import json
import os
import boto3
import hmac
import hashlib
import base64
from datetime import datetime
from botocore.exceptions import ClientError
import jwt
from jwt import PyJWKClient

# Initialize AWS clients
cognito_client = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

# Environment variables
USER_POOL_ID = os.environ.get('USER_POOL_ID')
CLIENT_ID = os.environ.get('CLIENT_ID')
CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
USERS_TABLE_NAME = os.environ.get('DYNAMODB_USERS_TABLE')
AWS_REGION = os.environ.get('AWS_REGION', 'ap-southeast-1')

users_table = dynamodb.Table(USERS_TABLE_NAME)


def get_secret_hash(username):
    """Calculate SECRET_HASH for Cognito"""
    if not CLIENT_SECRET:
        return None
    message = bytes(username + CLIENT_ID, 'utf-8')
    secret = bytes(CLIENT_SECRET, 'utf-8')
    dig = hmac.new(secret, msg=message, digestmod=hashlib.sha256).digest()
    return base64.b64encode(dig).decode()


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
        email = decoded.get('email')
        name = decoded.get('name', email.split('@')[0] if email else 'User')
        
        if not user_id:
            return None, 'Invalid token: missing user ID'
        
        # Get user from DynamoDB to get role
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            # User not in DynamoDB yet - create with default Employee role
            print(f"User {email} not found in DynamoDB, creating with Employee role")
            now = datetime.utcnow().isoformat()
            user = {
                'userId': user_id,
                'email': email,
                'name': name,
                'role': 'Employee',
                'isActive': True,
                'createdAt': now,
                'updatedAt': now
            }
            try:
                users_table.put_item(Item=user)
                print(f"Created user {email} in DynamoDB")
            except Exception as e:
                print(f"Error creating user in DynamoDB: {e}")
                # Continue anyway with the user object
        else:
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


def handle_get_me(current_user):
    """GET /users/me - Get current user profile"""
    try:
        return success_response({'user': current_user})
    except Exception as e:
        print(f"Error in get_me: {e}")
        return error_response(500, 'Error retrieving user profile')


def handle_update_me(event, current_user):
    """PUT /users/me - Update current user profile"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        # Only allow updating certain fields
        allowed_fields = ['name', 'department', 'avatarUrl']
        update_data = {k: v for k, v in body.items() if k in allowed_fields}
        
        if not update_data:
            return error_response(400, 'No valid fields to update')
        
        # Update timestamp
        update_data['updatedAt'] = datetime.utcnow().isoformat()
        
        # Build update expression
        update_expr = 'SET ' + ', '.join([f'#{k} = :{k}' for k in update_data.keys()])
        expr_attr_names = {f'#{k}': k for k in update_data.keys()}
        expr_attr_values = {f':{k}': v for k, v in update_data.items()}
        
        # Update in DynamoDB
        response = users_table.update_item(
            Key={'userId': current_user['userId']},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues='ALL_NEW'
        )
        
        # Update name in Cognito if provided
        if 'name' in update_data:
            try:
                cognito_client.admin_update_user_attributes(
                    UserPoolId=USER_POOL_ID,
                    Username=current_user['email'],
                    UserAttributes=[
                        {'Name': 'name', 'Value': update_data['name']}
                    ]
                )
            except Exception as e:
                print(f"Error updating Cognito attributes: {e}")
        
        return success_response({'user': response['Attributes']})
        
    except Exception as e:
        print(f"Error in update_me: {e}")
        return error_response(500, 'Error updating user profile')


def handle_get_all_users(event, current_user):
    """GET /users - List all users with filters (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get query parameters for filtering
        params = event.get('queryStringParameters') or {}
        search = params.get('search', '').lower()
        department = params.get('department')
        role = params.get('role')
        status = params.get('status')
        
        # Scan all users (for MVP, no pagination)
        response = users_table.scan()
        users = response['Items']
        
        # Apply filters
        if search:
            users = [u for u in users if search in u.get('name', '').lower() or search in u.get('email', '').lower()]
        
        if department:
            users = [u for u in users if u.get('department') == department]
        
        if role:
            users = [u for u in users if u.get('role') == role]
        
        if status and status.lower() != 'all':
            is_active = status.lower() == 'active'
            users = [u for u in users if u.get('isActive', True) == is_active]
        
        return success_response({'users': users})
        
    except Exception as e:
        print(f"Error in get_all_users: {e}")
        return error_response(500, 'Error retrieving users')


def handle_create_user(event, current_user):
    """POST /users - Create new user (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        name = body.get('name')
        role = body.get('role', 'Employee')
        department = body.get('department')
        employee_id = body.get('employeeId')
        
        if not email or not name:
            return error_response(400, 'Email and name are required')
        
        # Generate temporary password
        temp_password = f"TempPass{datetime.now().strftime('%Y%m%d')}!"
        
        # Create user in Cognito
        try:
            cognito_response = cognito_client.admin_create_user(
                UserPoolId=USER_POOL_ID,
                Username=email,
                UserAttributes=[
                    {'Name': 'email', 'Value': email},
                    {'Name': 'name', 'Value': name},
                    {'Name': 'email_verified', 'Value': 'true'}
                ],
                TemporaryPassword=temp_password,
                MessageAction='SUPPRESS'  # Don't send email
            )
            
            user_sub = cognito_response['User']['Username']
            
        except cognito_client.exceptions.UsernameExistsException:
            return error_response(409, 'User with this email already exists')
        except Exception as e:
            print(f"Error creating user in Cognito: {e}")
            return error_response(500, f'Error creating user in Cognito: {str(e)}')
        
        # Create user record in DynamoDB
        now = datetime.utcnow().isoformat()
        user_data = {
            'userId': user_sub,
            'email': email,
            'name': name,
            'role': role,
            'isActive': True,
            'createdAt': now,
            'updatedAt': now
        }
        
        if department:
            user_data['department'] = department
        if employee_id:
            user_data['employeeId'] = employee_id
        
        try:
            users_table.put_item(Item=user_data)
        except ClientError as e:
            print(f"Error creating user in DynamoDB: {e}")
            # Rollback: delete from Cognito
            try:
                cognito_client.admin_delete_user(
                    UserPoolId=USER_POOL_ID,
                    Username=email
                )
            except:
                pass
            return error_response(500, 'Error creating user in database')
        
        return success_response({
            'user': user_data,
            'temporaryPassword': temp_password
        }, 201)
        
    except Exception as e:
        print(f"Error in create_user: {e}")
        return error_response(500, 'Error creating user')


def handle_update_user(event, current_user, user_id):
    """PUT /users/:userId - Update user (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        body = json.loads(event.get('body', '{}'))
        
        # Get existing user
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return error_response(404, 'User not found')
        
        existing_user = response['Item']
        
        # Allowed fields for update
        allowed_fields = ['name', 'role', 'department', 'employeeId']
        update_data = {k: v for k, v in body.items() if k in allowed_fields}
        
        if not update_data:
            return error_response(400, 'No valid fields to update')
        
        # Update timestamp
        update_data['updatedAt'] = datetime.utcnow().isoformat()
        
        # Build update expression
        update_expr = 'SET ' + ', '.join([f'#{k} = :{k}' for k in update_data.keys()])
        expr_attr_names = {f'#{k}': k for k in update_data.keys()}
        expr_attr_values = {f':{k}': v for k, v in update_data.items()}
        
        # Update in DynamoDB
        response = users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues='ALL_NEW'
        )
        
        # Update name in Cognito if provided
        if 'name' in update_data:
            try:
                cognito_client.admin_update_user_attributes(
                    UserPoolId=USER_POOL_ID,
                    Username=existing_user['email'],
                    UserAttributes=[
                        {'Name': 'name', 'Value': update_data['name']}
                    ]
                )
            except Exception as e:
                print(f"Error updating Cognito attributes: {e}")
        
        return success_response({'user': response['Attributes']})
        
    except Exception as e:
        print(f"Error in update_user: {e}")
        return error_response(500, 'Error updating user')


def handle_disable_user(event, current_user, user_id):
    """PUT /users/:userId/disable - Disable user (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get existing user
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return error_response(404, 'User not found')
        
        existing_user = response['Item']
        
        # Disable in Cognito
        try:
            cognito_client.admin_disable_user(
                UserPoolId=USER_POOL_ID,
                Username=existing_user['email']
            )
        except Exception as e:
            print(f"Error disabling user in Cognito: {e}")
            return error_response(500, 'Error disabling user in Cognito')
        
        # Update in DynamoDB
        response = users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET isActive = :false, updatedAt = :now',
            ExpressionAttributeValues={
                ':false': False,
                ':now': datetime.utcnow().isoformat()
            },
            ReturnValues='ALL_NEW'
        )
        
        return success_response({'user': response['Attributes']})
        
    except Exception as e:
        print(f"Error in disable_user: {e}")
        return error_response(500, 'Error disabling user')


def handle_enable_user(event, current_user, user_id):
    """PUT /users/:userId/enable - Enable user (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get existing user
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return error_response(404, 'User not found')
        
        existing_user = response['Item']
        
        # Enable in Cognito
        try:
            cognito_client.admin_enable_user(
                UserPoolId=USER_POOL_ID,
                Username=existing_user['email']
            )
        except Exception as e:
            print(f"Error enabling user in Cognito: {e}")
            return error_response(500, 'Error enabling user in Cognito')
        
        # Update in DynamoDB
        response = users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET isActive = :true, updatedAt = :now',
            ExpressionAttributeValues={
                ':true': True,
                ':now': datetime.utcnow().isoformat()
            },
            ReturnValues='ALL_NEW'
        )
        
        return success_response({'user': response['Attributes']})
        
    except Exception as e:
        print(f"Error in enable_user: {e}")
        return error_response(500, 'Error enabling user')


def handle_delete_user(event, current_user, user_id):
    """DELETE /users/:userId - Delete user (Admin only)"""
    try:
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Get existing user
        response = users_table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return error_response(404, 'User not found')
        
        existing_user = response['Item']
        
        # Delete from Cognito
        try:
            cognito_client.admin_delete_user(
                UserPoolId=USER_POOL_ID,
                Username=existing_user['email']
            )
        except Exception as e:
            print(f"Error deleting user from Cognito: {e}")
            return error_response(500, 'Error deleting user from Cognito')
        
        # Delete from DynamoDB
        users_table.delete_item(Key={'userId': user_id})
        
        return success_response({'message': 'User deleted successfully'})
        
    except Exception as e:
        print(f"Error in delete_user: {e}")
        return error_response(500, 'Error deleting user')


def lambda_handler(event, context):
    """
    Main Lambda handler for user management operations
    Routes requests based on HTTP method and path
    """
    try:
        http_method = event.get('httpMethod')
        path = event.get('path', '')
        
        # Extract current user from JWT token
        current_user, error = extract_user_from_token(event)
        if error:
            return error_response(401, error)
        
        # Route to appropriate handler
        if path == '/users/me':
            if http_method == 'GET':
                return handle_get_me(current_user)
            elif http_method == 'PUT':
                return handle_update_me(event, current_user)
        
        elif path == '/users':
            if http_method == 'GET':
                return handle_get_all_users(event, current_user)
            elif http_method == 'POST':
                return handle_create_user(event, current_user)
        
        elif path.startswith('/users/'):
            # Extract userId from path
            path_parts = path.split('/')
            if len(path_parts) >= 3:
                user_id = path_parts[2]
                
                if len(path_parts) == 3:
                    # /users/:userId
                    if http_method == 'PUT':
                        return handle_update_user(event, current_user, user_id)
                    elif http_method == 'DELETE':
                        return handle_delete_user(event, current_user, user_id)
                
                elif len(path_parts) == 4:
                    action = path_parts[3]
                    if action == 'disable' and http_method == 'PUT':
                        return handle_disable_user(event, current_user, user_id)
                    elif action == 'enable' and http_method == 'PUT':
                        return handle_enable_user(event, current_user, user_id)
        
        return error_response(404, 'Endpoint not found')
        
    except Exception as e:
        print(f"Unexpected error in lambda_handler: {e}")
        return error_response(500, 'Internal server error')
