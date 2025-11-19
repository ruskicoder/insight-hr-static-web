import json
import os
import boto3
import requests
from datetime import datetime
from botocore.exceptions import ClientError
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

# Initialize AWS clients
# AWS_REGION is automatically set by Lambda runtime
cognito_client = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

# Environment variables
USER_POOL_ID = os.environ.get('USER_POOL_ID')
CLIENT_ID = os.environ.get('CLIENT_ID')
USERS_TABLE_NAME = os.environ.get('DYNAMODB_USERS_TABLE')
GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')

users_table = dynamodb.Table(USERS_TABLE_NAME)


def verify_google_token(token):
    """
    Verify Google OAuth token and extract user info
    Returns: dict with email, name, picture or None if invalid
    """
    try:
        # First, try to verify as ID token (JWT)
        try:
            idinfo = id_token.verify_oauth2_token(
                token, 
                google_requests.Request(), 
                GOOGLE_CLIENT_ID
            )
            
            # Token is valid, extract user info
            return {
                'email': idinfo.get('email'),
                'name': idinfo.get('name'),
                'picture': idinfo.get('picture'),
                'email_verified': idinfo.get('email_verified', False)
            }
        except ValueError:
            # Not an ID token, might be an access token
            # Use Google's userinfo endpoint
            response = requests.get(
                'https://www.googleapis.com/oauth2/v3/userinfo',
                headers={'Authorization': f'Bearer {token}'}
            )
            
            if response.status_code == 200:
                user_info = response.json()
                return {
                    'email': user_info.get('email'),
                    'name': user_info.get('name'),
                    'picture': user_info.get('picture'),
                    'email_verified': user_info.get('email_verified', False)
                }
            else:
                print(f"Google userinfo API error: {response.status_code} - {response.text}")
                return None
                
    except Exception as e:
        print(f"Error verifying Google token: {e}")
        return None


def lambda_handler(event, context):
    """
    Handle Google OAuth authentication
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        google_token = body.get('googleToken')
        
        if not google_token:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Google token is required'
                })
            }
        
        # Verify Google token and get user info
        google_user_info = verify_google_token(google_token)
        
        if not google_user_info:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Invalid Google token'
                })
            }
        
        google_email = google_user_info['email']
        google_name = google_user_info['name']
        google_picture = google_user_info.get('picture')
        
        # Check if user exists in DynamoDB
        try:
            response = users_table.query(
                IndexName='email-index',
                KeyConditionExpression='email = :email',
                ExpressionAttributeValues={
                    ':email': google_email
                }
            )
            
            if response['Items']:
                # User exists - login flow
                user = response['Items'][0]
                print(f"Existing user found: {google_email}")
                
                # Update picture if changed
                if google_picture and user.get('avatarUrl') != google_picture:
                    users_table.update_item(
                        Key={'userId': user['userId']},
                        UpdateExpression='SET avatarUrl = :picture, updatedAt = :now',
                        ExpressionAttributeValues={
                            ':picture': google_picture,
                            ':now': datetime.utcnow().isoformat()
                        }
                    )
                    user['avatarUrl'] = google_picture
            else:
                # User doesn't exist - register flow
                print(f"Creating new user: {google_email}")
                now = datetime.utcnow().isoformat()
                
                # Generate unique userId
                import uuid
                user_id = str(uuid.uuid4())
                
                user = {
                    'userId': user_id,
                    'email': google_email,
                    'name': google_name,
                    'role': 'Employee',  # Default role for new users
                    'isActive': True,
                    'createdAt': now,
                    'updatedAt': now
                }
                
                # Add avatar URL if available
                if google_picture:
                    user['avatarUrl'] = google_picture
                
                # Save to DynamoDB
                users_table.put_item(Item=user)
                
                # Create user in Cognito for unified user management
                try:
                    user_attributes = [
                        {'Name': 'email', 'Value': google_email},
                        {'Name': 'name', 'Value': google_name},
                        {'Name': 'email_verified', 'Value': 'true'}
                    ]
                    
                    cognito_response = cognito_client.admin_create_user(
                        UserPoolId=USER_POOL_ID,
                        Username=google_email,
                        UserAttributes=user_attributes,
                        MessageAction='SUPPRESS'
                    )
                    
                    # Set permanent password (Google users don't use password)
                    cognito_client.admin_set_user_password(
                        UserPoolId=USER_POOL_ID,
                        Username=google_email,
                        Password=f"GoogleAuth-{uuid.uuid4()}",  # Random password
                        Permanent=True
                    )
                    
                    # Store Cognito sub in user record
                    cognito_sub = cognito_response['User']['Username']
                    users_table.update_item(
                        Key={'userId': user_id},
                        UpdateExpression='SET cognitoSub = :sub',
                        ExpressionAttributeValues={':sub': cognito_sub}
                    )
                    user['cognitoSub'] = cognito_sub
                    
                except cognito_client.exceptions.UsernameExistsException:
                    print(f"User already exists in Cognito: {google_email}")
                    # Get existing Cognito user
                    cognito_user = cognito_client.admin_get_user(
                        UserPoolId=USER_POOL_ID,
                        Username=google_email
                    )
                    cognito_sub = cognito_user['Username']
                    users_table.update_item(
                        Key={'userId': user_id},
                        UpdateExpression='SET cognitoSub = :sub',
                        ExpressionAttributeValues={':sub': cognito_sub}
                    )
                    user['cognitoSub'] = cognito_sub
                
        except ClientError as e:
            print(f"Error querying/creating user in DynamoDB: {e}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Error processing Google authentication'
                })
            }
        
        # Generate Cognito tokens for the user
        # For Google OAuth users, we need to authenticate them with Cognito
        # Since they don't have a password, we'll use admin_set_user_password with a random password
        # and then authenticate with that password
        try:
            # Get or create a secure random password for this session
            import secrets
            temp_password = secrets.token_urlsafe(32)
            
            # Set the password for the user (this allows us to authenticate)
            try:
                cognito_client.admin_set_user_password(
                    UserPoolId=USER_POOL_ID,
                    Username=google_email,
                    Password=temp_password,
                    Permanent=True
                )
            except Exception as pwd_error:
                print(f"Error setting password: {pwd_error}")
            
            # Now authenticate with the password to get real tokens
            import hmac
            import hashlib
            import base64
            
            # Get CLIENT_SECRET from environment
            CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
            
            # Calculate SECRET_HASH
            message = bytes(google_email + CLIENT_ID, 'utf-8')
            secret = bytes(CLIENT_SECRET, 'utf-8')
            dig = hmac.new(secret, msg=message, digestmod=hashlib.sha256).digest()
            secret_hash = base64.b64encode(dig).decode()
            
            auth_response = cognito_client.admin_initiate_auth(
                UserPoolId=USER_POOL_ID,
                ClientId=CLIENT_ID,
                AuthFlow='ADMIN_NO_SRP_AUTH',
                AuthParameters={
                    'USERNAME': google_email,
                    'PASSWORD': temp_password,
                    'SECRET_HASH': secret_hash
                }
            )
            
            tokens = {
                'accessToken': auth_response['AuthenticationResult']['AccessToken'],
                'refreshToken': auth_response['AuthenticationResult'].get('RefreshToken', ''),
                'idToken': auth_response['AuthenticationResult']['IdToken'],
                'expiresIn': auth_response['AuthenticationResult']['ExpiresIn']
            }
            print(f"Successfully generated Cognito tokens for {google_email}")
            
        except Exception as e:
            print(f"Error generating Cognito tokens: {e}")
            import traceback
            traceback.print_exc()
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': f'Error generating authentication tokens: {str(e)}'
                })
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'message': 'Google authentication successful',
                'data': {
                    'user': user,
                    'tokens': tokens
                }
            })
        }
        
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'message': 'Internal server error'
            })
        }
