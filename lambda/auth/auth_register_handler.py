import json
import os
import boto3
import hmac
import hashlib
import base64
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
# AWS_REGION is automatically set by Lambda runtime
cognito_client = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

# Environment variables
USER_POOL_ID = os.environ.get('USER_POOL_ID')
CLIENT_ID = os.environ.get('CLIENT_ID')
CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
USERS_TABLE_NAME = os.environ.get('DYNAMODB_USERS_TABLE')

users_table = dynamodb.Table(USERS_TABLE_NAME)


def get_secret_hash(username):
    """Calculate SECRET_HASH for Cognito"""
    if not CLIENT_SECRET:
        return None
    message = bytes(username + CLIENT_ID, 'utf-8')
    secret = bytes(CLIENT_SECRET, 'utf-8')
    dig = hmac.new(secret, msg=message, digestmod=hashlib.sha256).digest()
    return base64.b64encode(dig).decode()


def lambda_handler(event, context):
    """
    Handle user registration with Cognito and DynamoDB
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        password = body.get('password')
        name = body.get('name')
        
        if not email or not password or not name:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Email, password, and name are required'
                })
            }
        
        # Create user in Cognito
        try:
            signup_params = {
                'ClientId': CLIENT_ID,
                'Username': email,
                'Password': password,
                'UserAttributes': [
                    {'Name': 'email', 'Value': email},
                    {'Name': 'name', 'Value': name}
                ]
            }
            
            # Add SECRET_HASH if client secret is configured
            secret_hash = get_secret_hash(email)
            if secret_hash:
                signup_params['SecretHash'] = secret_hash
            
            cognito_response = cognito_client.sign_up(**signup_params)
            
            user_sub = cognito_response['UserSub']
            
            # Auto-confirm user (for development)
            cognito_client.admin_confirm_sign_up(
                UserPoolId=USER_POOL_ID,
                Username=email
            )
            
        except cognito_client.exceptions.UsernameExistsException:
            return {
                'statusCode': 409,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'User with this email already exists'
                })
            }
        except cognito_client.exceptions.InvalidPasswordException:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Password does not meet requirements'
                })
            }
        
        # Create user record in DynamoDB
        now = datetime.utcnow().isoformat()
        user_data = {
            'userId': user_sub,
            'email': email,
            'name': name,
            'role': 'Employee',
            'isActive': True,
            'createdAt': now,
            'updatedAt': now
        }
        
        try:
            users_table.put_item(Item=user_data)
        except ClientError as e:
            print(f"Error creating user in DynamoDB: {e}")
            # User created in Cognito but not in DynamoDB
            # Could implement rollback here
        
        # Authenticate the new user to get tokens
        try:
            auth_params = {
                'USERNAME': email,
                'PASSWORD': password
            }
            
            # Add SECRET_HASH if client secret is configured
            secret_hash = get_secret_hash(email)
            if secret_hash:
                auth_params['SECRET_HASH'] = secret_hash
            
            auth_response = cognito_client.initiate_auth(
                ClientId=CLIENT_ID,
                AuthFlow='USER_PASSWORD_AUTH',
                AuthParameters=auth_params
            )
            
            tokens = {
                'accessToken': auth_response['AuthenticationResult']['AccessToken'],
                'refreshToken': auth_response['AuthenticationResult']['RefreshToken'],
                'idToken': auth_response['AuthenticationResult']['IdToken'],
                'expiresIn': auth_response['AuthenticationResult']['ExpiresIn']
            }
        except Exception as e:
            print(f"Error authenticating new user: {e}")
            tokens = None
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'message': 'Registration successful',
                'data': {
                    'user': user_data,
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
