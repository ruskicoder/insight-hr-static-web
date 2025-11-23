import json
import boto3
import os
from decimal import Decimal
from datetime import datetime

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

def get_user_info(event):
    """Get user role and department from DynamoDB Users table using email from JWT
    For Manager users, look up their department from the Employees table using their employeeId"""
    try:
        # Get email from JWT claims
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        email = claims.get('email')
        
        if not email:
            print("No email found in JWT claims")
            return {'role': 'Employee', 'department': None, 'employeeId': None}
        
        print(f"Looking up user info for email: {email}")
        
        # Query Users table by email using GSI
        response = users_table.query(
            IndexName='email-index',
            KeyConditionExpression='email = :email',
            ExpressionAttributeValues={':email': email}
        )
        
        items = response.get('Items', [])
        if items:
            user = items[0]
            role = user.get('role', 'Employee')
            user_employee_id = user.get('employeeId')
            
            # For Manager users, get department from Employees table
            if role == 'Manager' and user_employee_id:
                print(f"Manager user with employeeId: {user_employee_id}, looking up department from Employees table")
                try:
                    emp_response = table.get_item(Key={'employeeId': user_employee_id})
                    employee = emp_response.get('Item')
                    if employee:
                        department = employee.get('department')
                        print(f"Found employee record - department: {department}")
                        return {'role': role, 'department': department, 'employeeId': user_employee_id}
                    else:
                        print(f"No employee record found for employeeId: {user_employee_id}")
                        return {'role': role, 'department': None, 'employeeId': user_employee_id}
                except Exception as e:
                    print(f"Error looking up employee: {e}")
                    return {'role': role, 'department': None, 'employeeId': user_employee_id}
            else:
                # For Admin/Employee, use department from Users table (if any)
                department = user.get('department')
                print(f"Found user - role: {role}, department: {department}, employeeId: {user_employee_id}")
                return {'role': role, 'department': department, 'employeeId': user_employee_id}
        else:
            print(f"No user found for email: {email}")
            return {'role': 'Employee', 'department': None, 'employeeId': None}
    except Exception as e:
        print(f"Error getting user info: {e}")
        return {'role': 'Employee', 'department': None, 'employeeId': None}

def lambda_handler(event, context):
    """
    Main Lambda handler for employee management operations
    
    Endpoints:
    - GET /employees → List all employees with filters
    - GET /employees/:employeeId → Get single employee
    - POST /employees → Create employee (Admin only)
    - PUT /employees/:employeeId → Update employee (Admin only)
    - DELETE /employees/:employeeId → Delete employee (Admin only)
    """
    
    print(f"Event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_parameters = event.get('pathParameters') or {}
    query_parameters = event.get('queryStringParameters') or {}
    
    # Extract user info for authorization
    user_info = get_user_info(event)
    user_role = user_info['role']
    user_department = user_info['department']
    
    try:
        # GET /employees - List all employees with filters
        if http_method == 'GET' and path == '/employees':
            return list_employees(query_parameters, user_role, user_department)
        
        # GET /employees/:employeeId - Get single employee
        elif http_method == 'GET' and path_parameters.get('employeeId'):
            employee_id = path_parameters['employeeId']
            return get_employee(employee_id, user_role, user_department)
        
        # POST /employees - Create employee (Admin only)
        elif http_method == 'POST' and path == '/employees':
            if user_role != 'Admin':
                return {
                    'statusCode': 403,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': 'Forbidden: Admin access required'})
                }
            body = json.loads(event.get('body', '{}'))
            return create_employee(body)
        
        # PUT /employees/:employeeId - Update employee (Admin only)
        elif http_method == 'PUT' and path_parameters.get('employeeId'):
            if user_role != 'Admin':
                return {
                    'statusCode': 403,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': 'Forbidden: Admin access required'})
                }
            employee_id = path_parameters['employeeId']
            body = json.loads(event.get('body', '{}'))
            return update_employee(employee_id, body)
        
        # DELETE /employees/:employeeId - Delete employee (Admin only)
        elif http_method == 'DELETE' and path_parameters.get('employeeId'):
            if user_role != 'Admin':
                return {
                    'statusCode': 403,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': 'Forbidden: Admin access required'})
                }
            employee_id = path_parameters['employeeId']
            return delete_employee(employee_id)
        
        else:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Not Found'})
            }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }

def list_employees(query_params, user_role, user_department):
    """List all employees with optional filters and role-based access control"""
    try:
        department = query_params.get('department')
        position = query_params.get('position')
        status = query_params.get('status')
        search = query_params.get('search', '').lower()
        
        # Manager role: filter by their department only
        if user_role == 'Manager' and user_department:
            print(f"Manager access: filtering by department {user_department}")
            response = table.query(
                IndexName='department-index',
                KeyConditionExpression='department = :dept',
                ExpressionAttributeValues={':dept': user_department}
            )
            employees = response.get('Items', [])
        # If department filter is provided, use GSI
        elif department and department != 'ALL':
            response = table.query(
                IndexName='department-index',
                KeyConditionExpression='department = :dept',
                ExpressionAttributeValues={':dept': department}
            )
            employees = response.get('Items', [])
        else:
            # Otherwise, scan the table
            response = table.scan()
            employees = response.get('Items', [])
        
        # Apply additional filters
        filtered_employees = employees
        
        if position and position != 'ALL':
            filtered_employees = [e for e in filtered_employees if e.get('position') == position]
        
        if status and status != 'ALL':
            filtered_employees = [e for e in filtered_employees if e.get('status') == status]
        
        if search:
            filtered_employees = [
                e for e in filtered_employees
                if search in e.get('name', '').lower() or search in e.get('employeeId', '').lower()
            ]
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': True,
                'data': {
                    'employees': filtered_employees,
                    'count': len(filtered_employees)
                }
            }, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error listing employees: {str(e)}")
        raise

def get_employee(employee_id, user_role, user_department):
    """Get a single employee by ID with role-based access control"""
    try:
        response = table.get_item(Key={'employeeId': employee_id})
        employee = response.get('Item')
        
        if not employee:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Employee not found'})
            }
        
        # Manager role: check if employee is in their department
        if user_role == 'Manager' and user_department:
            if employee.get('department') != user_department:
                return {
                    'statusCode': 403,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': 'Forbidden: You can only view employees in your department'})
                }
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': True,
                'data': {'employee': employee}
            }, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error getting employee: {str(e)}")
        raise

def create_employee(data):
    """Create a new employee"""
    try:
        # Validate required fields
        required_fields = ['employeeId', 'name', 'position', 'department']
        for field in required_fields:
            if field not in data:
                return {
                    'statusCode': 400,
                    'headers': cors_headers(),
                    'body': json.dumps({'error': f'Missing required field: {field}'})
                }
        
        # Check if employee already exists
        existing = table.get_item(Key={'employeeId': data['employeeId']})
        if 'Item' in existing:
            return {
                'statusCode': 409,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Employee ID already exists'})
            }
        
        # Create employee record
        now = datetime.utcnow().isoformat() + 'Z'
        employee = {
            'employeeId': data['employeeId'],
            'name': data['name'],
            'position': data['position'],
            'department': data['department'],
            'status': 'active',
            'email': data.get('email'),
            'createdAt': now,
            'updatedAt': now
        }
        
        table.put_item(Item=employee)
        
        return {
            'statusCode': 201,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': True,
                'data': {'employee': employee}
            }, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error creating employee: {str(e)}")
        raise

def update_employee(employee_id, data):
    """Update an existing employee"""
    try:
        # Check if employee exists
        existing = table.get_item(Key={'employeeId': employee_id})
        if 'Item' not in existing:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Employee not found'})
            }
        
        # Build update expression
        update_expr = 'SET updatedAt = :updated'
        expr_values = {':updated': datetime.utcnow().isoformat() + 'Z'}
        expr_names = {}
        
        # Add fields to update
        if 'name' in data:
            update_expr += ', #n = :name'
            expr_values[':name'] = data['name']
            expr_names['#n'] = 'name'
        
        if 'position' in data:
            update_expr += ', #p = :position'
            expr_values[':position'] = data['position']
            expr_names['#p'] = 'position'
        
        if 'department' in data:
            update_expr += ', department = :department'
            expr_values[':department'] = data['department']
        
        if 'status' in data:
            update_expr += ', #s = :status'
            expr_values[':status'] = data['status']
            expr_names['#s'] = 'status'
        
        if 'email' in data:
            update_expr += ', email = :email'
            expr_values[':email'] = data['email']
        
        # Update the employee
        update_params = {
            'Key': {'employeeId': employee_id},
            'UpdateExpression': update_expr,
            'ExpressionAttributeValues': expr_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expr_names:
            update_params['ExpressionAttributeNames'] = expr_names
        
        response = table.update_item(**update_params)
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': True,
                'data': {'employee': response['Attributes']}
            }, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error updating employee: {str(e)}")
        raise

def delete_employee(employee_id):
    """Delete an employee"""
    try:
        # Check if employee exists
        existing = table.get_item(Key={'employeeId': employee_id})
        if 'Item' not in existing:
            return {
                'statusCode': 404,
                'headers': cors_headers(),
                'body': json.dumps({'error': 'Employee not found'})
            }
        
        # Delete the employee
        table.delete_item(Key={'employeeId': employee_id})
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'success': True,
                'message': 'Employee deleted successfully'
            })
        }
    
    except Exception as e:
        print(f"Error deleting employee: {str(e)}")
        raise

def cors_headers():
    """Return CORS headers"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }
