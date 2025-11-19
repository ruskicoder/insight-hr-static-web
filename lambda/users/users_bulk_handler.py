import json
import os
import boto3
import hmac
import hashlib
import base64
import csv
import io
from datetime import datetime
from botocore.exceptions import ClientError
import jwt

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


def parse_csv_data(csv_content):
    """Parse CSV content and return list of user records"""
    try:
        # Handle both string and bytes
        if isinstance(csv_content, bytes):
            csv_content = csv_content.decode('utf-8')
        
        # Parse CSV
        csv_reader = csv.DictReader(io.StringIO(csv_content))
        users = []
        
        for row in csv_reader:
            # Expected columns: email, name, role, department, employeeId
            user = {
                'email': row.get('email', '').strip(),
                'name': row.get('name', '').strip(),
                'role': row.get('role', 'Employee').strip(),
                'department': row.get('department', '').strip(),
                'employeeId': row.get('employeeId', '').strip()
            }
            
            # Validate required fields
            if user['email'] and user['name']:
                users.append(user)
        
        return users, None
        
    except Exception as e:
        return None, f'Error parsing CSV: {str(e)}'


def create_single_user(user_data):
    """Create a single user in Cognito and DynamoDB"""
    try:
        email = user_data['email']
        name = user_data['name']
        role = user_data.get('role', 'Employee')
        department = user_data.get('department')
        employee_id = user_data.get('employeeId')
        
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
            return {
                'success': False,
                'email': email,
                'error': 'User already exists'
            }
        except Exception as e:
            return {
                'success': False,
                'email': email,
                'error': f'Cognito error: {str(e)}'
            }
        
        # Create user record in DynamoDB
        now = datetime.utcnow().isoformat()
        db_user_data = {
            'userId': user_sub,
            'email': email,
            'name': name,
            'role': role,
            'isActive': True,
            'createdAt': now,
            'updatedAt': now
        }
        
        if department:
            db_user_data['department'] = department
        if employee_id:
            db_user_data['employeeId'] = employee_id
        
        try:
            users_table.put_item(Item=db_user_data)
        except ClientError as e:
            # Rollback: delete from Cognito
            try:
                cognito_client.admin_delete_user(
                    UserPoolId=USER_POOL_ID,
                    Username=email
                )
            except:
                pass
            
            return {
                'success': False,
                'email': email,
                'error': f'Database error: {str(e)}'
            }
        
        return {
            'success': True,
            'email': email,
            'userId': user_sub,
            'temporaryPassword': temp_password
        }
        
    except Exception as e:
        return {
            'success': False,
            'email': user_data.get('email', 'unknown'),
            'error': f'Unexpected error: {str(e)}'
        }


def lambda_handler(event, context):
    """
    Handle bulk user creation from CSV data
    POST /users/bulk
    """
    try:
        # Extract current user from JWT token
        current_user, error = extract_user_from_token(event)
        if error:
            return error_response(401, error)
        
        # Check admin role
        if not check_admin_role(current_user):
            return error_response(403, 'Access denied: Admin role required')
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        csv_data = body.get('csvData')
        
        if not csv_data:
            return error_response(400, 'CSV data is required')
        
        # Parse CSV data
        users, parse_error = parse_csv_data(csv_data)
        if parse_error:
            return error_response(400, parse_error)
        
        if not users:
            return error_response(400, 'No valid users found in CSV')
        
        # Create users
        results = []
        success_count = 0
        failure_count = 0
        
        for user_data in users:
            result = create_single_user(user_data)
            results.append(result)
            
            if result['success']:
                success_count += 1
            else:
                failure_count += 1
        
        return success_response({
            'summary': {
                'total': len(users),
                'success': success_count,
                'failed': failure_count
            },
            'results': results
        }, 201)
        
    except Exception as e:
        print(f"Unexpected error in lambda_handler: {e}")
        return error_response(500, 'Internal server error')
