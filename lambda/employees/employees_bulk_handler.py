import json
import boto3
import os
import csv
import io
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('EMPLOYEES_TABLE', 'insighthr-employees-dev')
table = dynamodb.Table(table_name)

# Users table for role lookup
users_table_name = os.environ.get('USERS_TABLE', 'insighthr-users-dev')
users_table = dynamodb.Table(users_table_name)

def decimal_default(obj):
    """Helper to convert Decimal to float for JSON serialization"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def get_user_role(event):
    """Get user role from DynamoDB Users table using email from JWT"""
    try:
        # Get email from JWT claims
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        email = claims.get('email')
        
        if not email:
            print("No email found in JWT claims")
            return 'Employee'
        
        print(f"Looking up role for email: {email}")
        
        # Query Users table by email using GSI
        response = users_table.query(
            IndexName='email-index',
            KeyConditionExpression='email = :email',
            ExpressionAttributeValues={':email': email}
        )
        
        items = response.get('Items', [])
        if items:
            role = items[0].get('role', 'Employee')
            print(f"Found role: {role}")
            return role
        else:
            print(f"No user found for email: {email}")
            return 'Employee'
    except Exception as e:
        print(f"Error getting user role: {e}")
        return 'Employee'

def lambda_handler(event, context):
    """
    Bulk import employees from CSV data
    
    POST /employees/bulk
    Body: { "csvData": "employeeId,name,position,department\n..." }
    """
    
    print(f"Event: {json.dumps(event)}")
    
    # Check authorization
    user_role = get_user_role(event)
    if user_role != 'Admin':
        return {
            'statusCode': 403,
            'headers': cors_headers(),
            'body': json.dumps({'error': 'Forbidden: Admin access required'})
        }
    
    try:
        body = json.loads(event.get('body', '{}'))
        csv_data = body.get('csvData', '')
        
        if not csv_data:
            return {
                'statusCode': 400,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Missing csvData in request body'})
            }
        
        # Parse CSV data
        csv_file = io.StringIO(csv_data)
        csv_reader = csv.DictReader(csv_file)
        
        results = []
        imported = 0
        failed = 0
        
        for row_num, row in enumerate(csv_reader, start=2):  # Start at 2 (header is row 1)
            try:
                # Validate required fields
                employee_id = row.get('employeeId', '').strip()
                name = row.get('name', '').strip()
                position = row.get('position', '').strip()
                department = row.get('department', '').strip()
                
                if not all([employee_id, name, position, department]):
                    results.append({
                        'row': row_num,
                        'employeeId': employee_id,
                        'success': False,
                        'error': 'Missing required fields'
                    })
                    failed += 1
                    continue
                
                # Validate position
                valid_positions = ['Junior', 'Mid', 'Senior', 'Lead', 'Manager']
                if position not in valid_positions:
                    results.append({
                        'row': row_num,
                        'employeeId': employee_id,
                        'success': False,
                        'error': f'Invalid position: {position}. Must be one of: {", ".join(valid_positions)}'
                    })
                    failed += 1
                    continue
                
                # Validate department
                valid_departments = ['AI', 'DAT', 'DEV', 'QA', 'SEC']
                if department not in valid_departments:
                    results.append({
                        'row': row_num,
                        'employeeId': employee_id,
                        'success': False,
                        'error': f'Invalid department: {department}. Must be one of: {", ".join(valid_departments)}'
                    })
                    failed += 1
                    continue
                
                # Check if employee already exists
                existing = table.get_item(Key={'employeeId': employee_id})
                if 'Item' in existing:
                    results.append({
                        'row': row_num,
                        'employeeId': employee_id,
                        'success': False,
                        'error': 'Employee ID already exists'
                    })
                    failed += 1
                    continue
                
                # Create employee record
                now = datetime.utcnow().isoformat() + 'Z'
                employee = {
                    'employeeId': employee_id,
                    'name': name,
                    'position': position,
                    'department': department,
                    'status': 'active',
                    'email': row.get('email', '').strip() or None,
                    'createdAt': now,
                    'updatedAt': now
                }
                
                # Insert into DynamoDB
                table.put_item(Item=employee)
                
                results.append({
                    'row': row_num,
                    'employeeId': employee_id,
                    'success': True
                })
                imported += 1
            
            except Exception as e:
                print(f"Error processing row {row_num}: {str(e)}")
                results.append({
                    'row': row_num,
                    'employeeId': row.get('employeeId', 'unknown'),
                    'success': False,
                    'error': str(e)
                })
                failed += 1
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': failed == 0,
                'imported': imported,
                'failed': failed,
                'results': results
            }, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error in bulk import: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def cors_headers():
    """Return CORS headers"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }
