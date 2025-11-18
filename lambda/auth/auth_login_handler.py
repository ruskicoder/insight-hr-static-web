import json
import os
import boto3
import hmac
import hashlib
import base64
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
    Handle user login with Cognito
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        password = body.get('password')
        
        if not email or not password:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Email and password are required'
                })
            }
        
        # Authenticate with Cognito
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
        except cognito_client.exceptions.NotAuthorizedException:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Invalid email or password'
                })
            }
        except cognito_client.exceptions.UserNotFoundException:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Invalid email or password'
                })
            }
        
        # Get tokens from Cognito response
        tokens = {
            'accessToken': auth_response['AuthenticationResult']['AccessToken'],
            'refreshToken': auth_response['AuthenticationResult']['RefreshToken'],
            'idToken': auth_response['AuthenticationResult']['IdToken'],
            'expiresIn': auth_response['AuthenticationResult']['ExpiresIn']
        }
        
        # Get user details from DynamoDB
        try:
            response = users_table.query(
                IndexName='email-index',
                KeyConditionExpression='email = :email',
                ExpressionAttributeValues={
                    ':email': email
                }
            )
            
            if response['Items']:
                user = response['Items'][0]
            else:
                # User not in DynamoDB yet, get from Cognito
                cognito_user = cognito_client.admin_get_user(
                    UserPoolId=USER_POOL_ID,
                    Username=email
                )
                
                user = {
                    'userId': cognito_user['Username'],
                    'email': email,
                    'name': email.split('@')[0],
                    'role': 'Employee',
                    'createdAt': cognito_user['UserCreateDate'].isoformat(),
                    'updatedAt': cognito_user['UserLastModifiedDate'].isoformat()
                }
        except ClientError as e:
            print(f"Error querying DynamoDB: {e}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'message': 'Error retrieving user data'
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
                'message': 'Login successful',
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
