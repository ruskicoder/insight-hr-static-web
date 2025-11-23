import json
import os
import boto3
import uuid
import secrets
from datetime import datetime
from botocore.exceptions import ClientError
import jwt

# Initialize AWS clients
cognito_client = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

# Environment variables
USER_POOL_ID = os.environ.get('USER_POOL_ID')
USERS_TABLE_NAME = os.environ.get('DYNAMODB_USERS_TABLE')
PASSWORD_RESET_REQUESTS_TABLE = os.environ.get('PASSWORD_RESET_REQUESTS_TABLE', 'PasswordResetRequests')
# AWS_REGION is automatically set by Lambda runtime

users_table = dynamodb.Table(USERS_TABLE_NAME)
reset_requests_table = dynamodb.Table(PASSWORD_RESET_REQUESTS_TABLE)


def extract_user_from_token(event):
    """Extract user information from JWT token in Authorization header"""
    try:
        auth_header = event.get('headers', {}).get('Authorization') or event.get('headers', {}).get('authorization')
        if not auth_header:
            return None, 'Missing Authorization header'
        
        # Extract token from "Bearer <token>"
        token = auth_header.replace('Bearer ', '').replace('bearer ', '')
        
        # Decode JWT without verification (verification done by API Gateway authorizer)
        decoded = jwt.decode(token, options={"verify_signature": False})
        
        user_id = decoded.get('sub')
        
        if not user_id:
            return None, 'Invalid token: missing user ID'
        
        # Get user from DynamoDB to get role
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return None, 'User not found in database'
        
        user = response['Item']
        return user, None
        
    except Exception as e:
        print(f"Error extracting user from token: {e}")
        return None, f'Error validating token: {str(e)}'


def check_admin_role(user):
    """Check if user has Admin role"""
    return user.get('role') == 'Admin'


def cors_headers():
    """Return CORS headers"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }


def error_response(status_code, message):
    """Return error response"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({
            'success': False,
            'message': message
        })
    }


def success_response(data, status_code=200):
    """Return success response"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({
            'success': True,
            'data': data
        })
    }


def handle_request_reset(event):
    """
    Handle POST /auth/request-reset
    Public endpoint - no authentication required
    """
    try:
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        reason = body.get('reason', '').strip()
        
        if not email:
            return error_response(400, 'Email is required')
        
        # Check if user exists
        try:
            response = users_table.scan(
                FilterExpression='email = :email',
                ExpressionAttributeValues={':email': email}
            )
            
            if not response.get('Items'):
                return error_response(404, 'User not found')
            
            user = response['Items'][0]
            user_id = user['userId']
            
        except Exception as e:
            print(f"Error finding user: {e}")
            return error_response(500, 'Error finding user')
        
        # Check if there's already a pending request for this user
        try:
            response = reset_requests_table.query(
                IndexName='userId-index',
                KeyConditionExpression='userId = :userId',
                FilterExpression='#status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':userId': user_id,
                    ':status': 'pending'
                }
            )
            
            if response.get('Items'):
                return error_response(400, 'You already have a pending password reset request')
            
        except Exception as e:
            print(f"Error checking pending requests: {e}")
            # Continue anyway - better to allow duplicate than block user
        
        # Create password reset request
        request_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        reset_request = {
            'requestId': request_id,
            'userId': user_id,
            'email': email,
            'name': user.get('name', ''),
            'reason': reason,
            'status': 'pending',
            'requestedAt': now,
            'createdAt': now,
            'updatedAt': now
        }
        
        try:
            reset_requests_table.put_item(Item=reset_request)
        except Exception as e:
            print(f"Error creating reset request: {e}")
            return error_response(500, 'Error creating password reset request')
        
        return success_response({
            'message': 'Password reset request submitted successfully',
            'requestId': request_id
        }, 201)
        
    except Exception as e:
        print(f"Unexpected error in handle_request_reset: {e}")
        return error_response(500, 'Internal server error')


def handle_get_requests(event):
    """
    Handle GET /users/password-requests
    Admin only - get all pending password reset requests
    """
    try:
        # Extract current user from JWT token
        current_user, error = extract_user_from_token(event)
        if error:
            return error_response(401, error)
        
        # Check admin role
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Query pending requests
        try:
            response = reset_requests_table.query(
                IndexName='status-index',
                KeyConditionExpression='#status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': 'pending'},
                ScanIndexForward=False  # Most recent first
            )
            
            requests = response.get('Items', [])
            
            return success_response({
                'requests': requests,
                'count': len(requests)
            })
            
        except Exception as e:
            print(f"Error querying reset requests: {e}")
            return error_response(500, 'Error retrieving password reset requests')
        
    except Exception as e:
        print(f"Unexpected error in handle_get_requests: {e}")
        return error_response(500, 'Internal server error')


def generate_secure_password():
    """
    Generate a secure password that meets Cognito requirements:
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one number
    - At least one special character
    """
    import string
    import random
    
    # Define character sets
    uppercase = string.ascii_uppercase
    lowercase = string.ascii_lowercase
    digits = string.digits
    special = '!@#$%^&*'
    
    # Ensure at least one character from each required set
    password_chars = [
        secrets.choice(uppercase),
        secrets.choice(lowercase),
        secrets.choice(digits),
        secrets.choice(special),
    ]
    
    # Fill the rest with random characters from all sets
    all_chars = uppercase + lowercase + digits + special
    for _ in range(8):  # Total length will be 12 (4 required + 8 random)
        password_chars.append(secrets.choice(all_chars))
    
    # Shuffle to avoid predictable patterns
    random.shuffle(password_chars)
    
    return ''.join(password_chars)


def handle_approve_reset(event):
    """
    Handle POST /users/password-requests/:requestId/approve
    Admin only - approve password reset request
    """
    try:
        # Extract current user from JWT token
        current_user, error = extract_user_from_token(event)
        if error:
            return error_response(401, error)
        
        # Check admin role
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get requestId from path parameters
        request_id = event.get('pathParameters', {}).get('requestId')
        if not request_id:
            return error_response(400, 'Request ID is required')
        
        # Get reset request from DynamoDB
        try:
            response = reset_requests_table.get_item(Key={'requestId': request_id})
            if 'Item' not in response:
                return error_response(404, 'Password reset request not found')
            
            reset_request = response['Item']
            
            if reset_request.get('status') != 'pending':
                return error_response(400, f'Request is already {reset_request.get("status")}')
            
            user_id = reset_request['userId']
            email = reset_request['email']
            
        except Exception as e:
            print(f"Error finding reset request: {e}")
            return error_response(500, 'Error finding password reset request')
        
        # Generate secure password that meets Cognito requirements
        generated_password = generate_secure_password()
        
        # Reset password in Cognito
        try:
            cognito_client.admin_set_user_password(
                UserPoolId=USER_POOL_ID,
                Username=email,
                Password=generated_password,
                Permanent=False  # Force password change on next login
            )
        except Exception as e:
            print(f"Error resetting password in Cognito: {e}")
            return error_response(500, f'Error resetting password: {str(e)}')
        
        # Update request status to approved
        try:
            now = datetime.utcnow().isoformat()
            reset_requests_table.update_item(
                Key={'requestId': request_id},
                UpdateExpression='SET #status = :approved, approvedAt = :now, approvedBy = :admin, updatedAt = :now',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':approved': 'approved',
                    ':now': now,
                    ':admin': current_user['userId']
                }
            )
            
        except Exception as e:
            print(f"Error updating reset request: {e}")
            # Don't fail the operation if we can't update the request status
        
        return success_response({
            'message': f'Password reset approved. Generated password must be shared with user.',
            'email': email,
            'generatedPassword': generated_password
        })
        
    except Exception as e:
        print(f"Unexpected error in handle_approve_reset: {e}")
        return error_response(500, 'Internal server error')


def handle_deny_reset(event):
    """
    Handle POST /users/password-requests/:requestId/deny
    Admin only - deny password reset request
    """
    try:
        # Extract current user from JWT token
        current_user, error = extract_user_from_token(event)
        if error:
            return error_response(401, error)
        
        # Check admin role
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get requestId from path parameters
        request_id = event.get('pathParameters', {}).get('requestId')
        if not request_id:
            return error_response(400, 'Request ID is required')
        
        # Get reset request from DynamoDB
        try:
            response = reset_requests_table.get_item(Key={'requestId': request_id})
            if 'Item' not in response:
                return error_response(404, 'Password reset request not found')
            
            reset_request = response['Item']
            
            if reset_request.get('status') != 'pending':
                return error_response(400, f'Request is already {reset_request.get("status")}')
            
        except Exception as e:
            print(f"Error finding reset request: {e}")
            return error_response(500, 'Error finding password reset request')
        
        # Update request status to denied
        try:
            now = datetime.utcnow().isoformat()
            reset_requests_table.update_item(
                Key={'requestId': request_id},
                UpdateExpression='SET #status = :denied, deniedAt = :now, deniedBy = :admin, updatedAt = :now',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':denied': 'denied',
                    ':now': now,
                    ':admin': current_user['userId']
                }
            )
            
        except Exception as e:
            print(f"Error updating reset request: {e}")
            return error_response(500, 'Error denying password reset request')
        
        return success_response({
            'message': 'Password reset request denied successfully'
        })
        
    except Exception as e:
        print(f"Unexpected error in handle_deny_reset: {e}")
        return error_response(500, 'Internal server error')


def lambda_handler(event, context):
    """
    Main Lambda handler for password reset operations
    Routes:
    - POST /auth/request-reset (public)
    - GET /users/password-requests (admin only)
    - POST /users/password-requests/:requestId/approve (admin only)
    - POST /users/password-requests/:requestId/deny (admin only)
    """
    try:
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        
        print(f"Password reset handler - Method: {http_method}, Path: {path}")
        
        # Route to appropriate handler
        if http_method == 'POST' and path == '/auth/request-reset':
            return handle_request_reset(event)
        elif http_method == 'GET' and path == '/users/password-requests':
            return handle_get_requests(event)
        elif http_method == 'POST' and '/approve' in path:
            return handle_approve_reset(event)
        elif http_method == 'POST' and '/deny' in path:
            return handle_deny_reset(event)
        else:
            return error_response(404, 'Not found')
        
    except Exception as e:
        print(f"Unexpected error in lambda_handler: {e}")
        return error_response(500, 'Internal server error')
