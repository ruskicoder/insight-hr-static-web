import json
import os
import boto3
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
# AWS_REGION is automatically set by Lambda runtime
cognito_client = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

# Environment variables
USER_POOL_ID = os.environ.get('USER_POOL_ID')
CLIENT_ID = os.environ.get('CLIENT_ID')
USERS_TABLE_NAME = os.environ.get('DYNAMODB_USERS_TABLE')

users_table = dynamodb.Table(USERS_TABLE_NAME)


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
        
        # In production, verify Google token with Google API
        # For now, this is a mock implementation
        # TODO: Implement actual Google token verification
        
        # Mock Google user data
        google_email = 'google.user@example.com'
        google_name = 'Google User'
        
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
                # User exists, return user data
                user = response['Items'][0]
            else:
                # Create new user
                now = datetime.utcnow().isoformat()
                user_sub = f"google-{google_email}"
                
                user = {
                    'userId': user_sub,
                    'email': google_email,
                    'name': google_name,
                    'role': 'Employee',
                    'isActive': True,
                    'createdAt': now,
                    'updatedAt': now
                }
                
                users_table.put_item(Item=user)
                
                # Create user in Cognito (optional, for unified user management)
                try:
                    cognito_client.admin_create_user(
                        UserPoolId=USER_POOL_ID,
                        Username=google_email,
                        UserAttributes=[
                            {'Name': 'email', 'Value': google_email},
                            {'Name': 'name', 'Value': google_name},
                            {'Name': 'email_verified', 'Value': 'true'}
                        ],
                        MessageAction='SUPPRESS'
                    )
                except cognito_client.exceptions.UsernameExistsException:
                    pass  # User already exists in Cognito
                
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
        
        # Generate mock tokens (in production, use Cognito tokens)
        tokens = {
            'accessToken': f"google-access-token-{user['userId']}",
            'refreshToken': f"google-refresh-token-{user['userId']}",
            'idToken': f"google-id-token-{user['userId']}",
            'expiresIn': 3600
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
