import json
import boto3
import os
import logging
from decimal import Decimal
from datetime import datetime
import uuid

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'ap-southeast-1'))

# Environment variables
PERFORMANCE_SCORES_TABLE = os.environ.get('PERFORMANCE_SCORES_TABLE', 'insighthr-performance-scores-dev')
EMPLOYEES_TABLE = os.environ.get('EMPLOYEES_TABLE', 'insighthr-employees-dev')
USERS_TABLE = os.environ.get('USERS_TABLE', 'insighthr-users-dev')
AWS_REGION = os.environ.get('AWS_REGION', 'ap-southeast-1')

# Get table references
performance_table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
users_table = dynamodb.Table(USERS_TABLE)


class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert Decimal to float for JSON serialization"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def cors_headers():
    """Return CORS headers for API Gateway responses"""
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }


def response(status_code, body):
    """Create API Gateway response with CORS headers"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps(body, cls=DecimalEncoder)
    }


def extract_user_info(event):
    """Extract user information from JWT token and query Users table for role"""
    try:
        # Get claims from authorizer context
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        claims = authorizer.get('claims', {})
        
        user_id = claims.get('sub', '')
        email = claims.get('email', '')
        
        if not email:
            logger.warning("No email found in JWT claims")
            return {
                'userId': user_id,
                'email': '',
                'role': 'Employee',
                'employeeId': '',
                'department': ''
            }
        
        # Query Users table by email using GSI
        try:
            logger.info(f"Looking up user info for email: {email}")
            user_response = users_table.query(
                IndexName='email-index',
                KeyConditionExpression='email = :email',
                ExpressionAttributeValues={':email': email}
            )
            
            items = user_response.get('Items', [])
            if not items:
                logger.warning(f"No user found for email: {email}")
                return {
                    'userId': user_id,
                    'email': email,
                    'role': 'Employee',
                    'employeeId': '',
                    'department': ''
                }
            
            user_data = items[0]
            role = user_data.get('role', 'Employee')
            employee_id = user_data.get('employeeId', '')
            user_department = user_data.get('department', '')
            
            logger.info(f"Extracted user info - userId: {user_id}, email: {email}, role: {role}, employeeId: {employee_id}, department: {user_department}")
            
            return {
                'userId': user_id,
                'email': email,
                'role': role,
                'employeeId': employee_id,
                'department': user_department
            }
        except Exception as e:
            logger.warning(f"Failed to query Users table: {str(e)}, using defaults")
            return {
                'userId': user_id,
                'email': email,
                'role': 'Employee',
                'employeeId': '',
                'department': ''
            }
    except Exception as e:
        logger.error(f"Error extracting user info: {str(e)}")
        return {
            'userId': '',
            'email': '',
            'role': 'Employee',
            'employeeId': '',
            'department': ''
        }


def get_employee_details(employee_id):
    """Get employee details from Employees table"""
    try:
        emp_response = employees_table.get_item(Key={'employeeId': employee_id})
        employee = emp_response.get('Item')
        if employee:
            return {
                'name': employee.get('name', f'Employee {employee_id}'),
                'department': employee.get('department', ''),
                'position': employee.get('position', '')
            }
        return None
    except Exception as e:
        logger.error(f"Error getting employee details: {str(e)}")
        return None


def list_performance_scores(filters, user_info):
    """
    List performance scores with filters and role-based access control.
    
    Filters:
    - department: Filter by department
    - period: Filter by specific period (e.g., "2025-1")
    - employeeId: Filter by specific employee
    
    Role-based access:
    - Admin: See all data
    - Manager: See only their department
    - Employee: See only their own data
    """
    try:
        role = user_info.get('role', 'Employee')
        user_employee_id = user_info.get('employeeId', '')
        user_department = user_info.get('department', '')
        
        # Apply role-based filtering
        if role == 'Employee':
            # Employees can only see their own data
            if not user_employee_id:
                logger.warning(f"Employee user has no employeeId: {user_info.get('email')}")
                return []
            
            # Query by employeeId
            score_response = performance_table.query(
                KeyConditionExpression='employeeId = :empId',
                ExpressionAttributeValues={':empId': user_employee_id}
            )
            scores = score_response.get('Items', [])
            
            # Apply period filter if specified
            period_filter = filters.get('period')
            if period_filter:
                scores = [s for s in scores if s.get('period') == period_filter]
            
            return scores
        
        elif role == 'Manager':
            # Managers can see their department's data
            # Manager's department comes from their employee record in Employees table
            if not user_employee_id:
                logger.warning(f"Manager user has no employeeId: {user_info.get('email')}")
                return []
            
            # Get manager's department from Employees table
            manager_details = get_employee_details(user_employee_id)
            if not manager_details:
                logger.warning(f"Manager employee record not found: {user_employee_id}")
                return []
            
            department = manager_details.get('department', '')
            if not department:
                logger.warning(f"Manager has no department in Employees table: {user_info.get('email')}")
                return []
            
            # Query using GSI: department-period-index
            period_filter = filters.get('period')
            
            if period_filter:
                # Query with both department and period
                score_response = performance_table.query(
                    IndexName='department-period-index',
                    KeyConditionExpression='department = :dept AND period = :per',
                    ExpressionAttributeValues={
                        ':dept': department,
                        ':per': period_filter
                    }
                )
            else:
                # Query with department only
                score_response = performance_table.query(
                    IndexName='department-period-index',
                    KeyConditionExpression='department = :dept',
                    ExpressionAttributeValues={':dept': department}
                )
            
            scores = score_response.get('Items', [])
            
            # Apply employeeId filter if specified
            employee_filter = filters.get('employeeId')
            if employee_filter:
                scores = [s for s in scores if s.get('employeeId') == employee_filter]
            
            return scores
        
        else:  # Admin
            # Admins can see all data with any filters
            department_filter = filters.get('department')
            period_filter = filters.get('period')
            employee_filter = filters.get('employeeId')
            
            if employee_filter:
                # Query by specific employee
                score_response = performance_table.query(
                    KeyConditionExpression='employeeId = :empId',
                    ExpressionAttributeValues={':empId': employee_filter}
                )
                scores = score_response.get('Items', [])
                
                # Apply period filter if specified
                if period_filter:
                    scores = [s for s in scores if s.get('period') == period_filter]
                
                # Apply department filter if specified
                if department_filter:
                    scores = [s for s in scores if s.get('department') == department_filter]
                
                return scores
            
            elif department_filter:
                # Query using GSI: department-period-index
                if period_filter:
                    score_response = performance_table.query(
                        IndexName='department-period-index',
                        KeyConditionExpression='department = :dept AND period = :per',
                        ExpressionAttributeValues={
                            ':dept': department_filter,
                            ':per': period_filter
                        }
                    )
                else:
                    score_response = performance_table.query(
                        IndexName='department-period-index',
                        KeyConditionExpression='department = :dept',
                        ExpressionAttributeValues={':dept': department_filter}
                    )
                
                return score_response.get('Items', [])
            
            else:
                # Scan all data (no filters)
                score_response = performance_table.scan()
                scores = score_response.get('Items', [])
                
                # Apply period filter if specified
                if period_filter:
                    scores = [s for s in scores if s.get('period') == period_filter]
                
                return scores
    
    except Exception as e:
        logger.error(f"Error listing performance scores: {str(e)}")
        raise


def get_single_score(employee_id, period, user_info):
    """Get a single performance score by employeeId and period"""
    try:
        role = user_info.get('role', 'Employee')
        user_employee_id = user_info.get('employeeId', '')
        user_department = user_info.get('department', '')
        
        # Check access permissions
        if role == 'Employee' and employee_id != user_employee_id:
            logger.warning(f"Employee {user_employee_id} attempted to access data for {employee_id}")
            return None  # Unauthorized
        
        # Get the score
        score_response = performance_table.get_item(
            Key={
                'employeeId': employee_id,
                'period': period
            }
        )
        
        score = score_response.get('Item')
        if not score:
            return None
        
        # For Managers, verify the employee is in their department
        # Manager's department comes from their employee record in Employees table
        if role == 'Manager':
            if not user_employee_id:
                logger.warning(f"Manager user has no employeeId: {user_info.get('email')}")
                return None  # Unauthorized
            
            # Get manager's department from Employees table
            manager_details = get_employee_details(user_employee_id)
            if not manager_details:
                logger.warning(f"Manager employee record not found: {user_employee_id}")
                return None  # Unauthorized
            
            manager_department = manager_details.get('department', '')
            employee_dept = score.get('department', '')
            if employee_dept != manager_department:
                logger.warning(f"Manager from {manager_department} attempted to access employee from {employee_dept}")
                return None  # Unauthorized
        
        return score
    
    except Exception as e:
        logger.error(f"Error getting single score: {str(e)}")
        raise


def create_performance_score(data, user_info):
    """Create a new performance score (Admin and Manager can create)"""
    try:
        role = user_info.get('role', 'Employee')
        user_employee_id = user_info.get('employeeId', '')
        user_email = user_info.get('email', '')
        
        logger.info(f"Create request - User: {user_email}, Role: {role}, EmployeeId: {user_employee_id}")
        
        # Only Admin and Manager can create scores
        if role not in ['Admin', 'Manager']:
            logger.warning(f"Non-admin/manager user attempted to create score: {user_email}")
            return None  # Unauthorized
        
        # Validate required fields
        employee_id = data.get('employeeId')
        period = data.get('period')
        
        if not employee_id or not period:
            raise ValueError("employeeId and period are required")
        
        # Get employee details
        employee_details = get_employee_details(employee_id)
        if not employee_details:
            raise ValueError(f"Employee {employee_id} not found")
        
        employee_dept = employee_details.get('department', '')
        logger.info(f"Employee {employee_id} department: {employee_dept}")
        
        # For Managers, verify the employee is in their department
        if role == 'Manager':
            if not user_employee_id:
                logger.error(f"Manager {user_email} has no employeeId set in Users table")
                return None  # Unauthorized - Manager must have employeeId set
            
            # Get manager's department from Employees table
            manager_details = get_employee_details(user_employee_id)
            if not manager_details:
                logger.error(f"Manager {user_email} employee record not found: {user_employee_id}")
                return None  # Unauthorized - Manager employee record must exist
            
            manager_department = manager_details.get('department', '')
            logger.info(f"Manager {user_email} department: {manager_department}")
            
            if employee_dept != manager_department:
                logger.warning(f"Manager from {manager_department} attempted to create score for employee from {employee_dept}")
                return None  # Unauthorized
        
        # Extract scores
        kpi_score = Decimal(str(data.get('KPI', 0)))
        completed_task_score = Decimal(str(data.get('completed_task', 0)))
        feedback_360_score = Decimal(str(data.get('feedback_360', 0)))
        
        # Calculate final score (average of three scores)
        final_score = data.get('final_score')
        if final_score is None:
            final_score = (kpi_score + completed_task_score + feedback_360_score) / 3
        else:
            final_score = Decimal(str(final_score))
        
        # Create score record
        now = datetime.utcnow().isoformat()
        score_id = str(uuid.uuid4())
        
        score_item = {
            'scoreId': score_id,
            'employeeId': employee_id,
            'period': period,
            'employeeName': employee_details['name'],
            'department': employee_details['department'],
            'position': employee_details['position'],
            'overallScore': final_score,
            'kpiScores': {
                'KPI': kpi_score,
                'completed_task': completed_task_score,
                'feedback_360': feedback_360_score
            },
            'calculatedAt': now,
            'createdAt': now,
            'updatedAt': now
        }
        
        # Save to DynamoDB
        performance_table.put_item(Item=score_item)
        
        logger.info(f"Created performance score: {employee_id} - {period}")
        return score_item
    
    except Exception as e:
        logger.error(f"Error creating performance score: {str(e)}")
        raise


def update_performance_score(employee_id, period, data, user_info):
    """Update an existing performance score (Admin and Manager can update)"""
    try:
        role = user_info.get('role', 'Employee')
        user_employee_id = user_info.get('employeeId', '')
        user_email = user_info.get('email', '')
        
        logger.info(f"Update request - User: {user_email}, Role: {role}, EmployeeId: {user_employee_id}")
        
        # Only Admin and Manager can update scores
        if role not in ['Admin', 'Manager']:
            logger.warning(f"Non-admin/manager user attempted to update score: {user_email}")
            return None  # Unauthorized
        
        # Get existing score
        score_response = performance_table.get_item(
            Key={
                'employeeId': employee_id,
                'period': period
            }
        )
        
        existing_score = score_response.get('Item')
        if not existing_score:
            raise ValueError(f"Score not found for {employee_id} - {period}")
        
        employee_dept = existing_score.get('department', '')
        logger.info(f"Employee {employee_id} department: {employee_dept}")
        
        # For Managers, verify the employee is in their department
        # Manager's department comes from their employee record in Employees table
        if role == 'Manager':
            if not user_employee_id:
                logger.error(f"Manager {user_email} has no employeeId set in Users table")
                return None  # Unauthorized - Manager must have employeeId set
            
            # Get manager's department from Employees table
            manager_details = get_employee_details(user_employee_id)
            if not manager_details:
                logger.error(f"Manager {user_email} employee record not found: {user_employee_id}")
                return None  # Unauthorized - Manager employee record must exist
            
            manager_department = manager_details.get('department', '')
            logger.info(f"Manager {user_email} department: {manager_department}")
            
            if employee_dept != manager_department:
                logger.warning(f"Manager from {manager_department} attempted to update employee from {employee_dept}")
                return None  # Unauthorized
        
        # Update scores
        kpi_scores = existing_score.get('kpiScores', {})
        
        if 'KPI' in data:
            kpi_scores['KPI'] = Decimal(str(data['KPI']))
        if 'completed_task' in data:
            kpi_scores['completed_task'] = Decimal(str(data['completed_task']))
        if 'feedback_360' in data:
            kpi_scores['feedback_360'] = Decimal(str(data['feedback_360']))
        
        # Calculate final score
        if 'final_score' in data:
            final_score = Decimal(str(data['final_score']))
        else:
            # Recalculate from KPI scores
            kpi = kpi_scores.get('KPI', Decimal('0'))
            completed = kpi_scores.get('completed_task', Decimal('0'))
            feedback = kpi_scores.get('feedback_360', Decimal('0'))
            final_score = (kpi + completed + feedback) / 3
        
        # Update the record
        now = datetime.utcnow().isoformat()
        
        performance_table.update_item(
            Key={
                'employeeId': employee_id,
                'period': period
            },
            UpdateExpression='SET kpiScores = :kpi, overallScore = :score, updatedAt = :updated',
            ExpressionAttributeValues={
                ':kpi': kpi_scores,
                ':score': final_score,
                ':updated': now
            }
        )
        
        # Get updated score
        updated_response = performance_table.get_item(
            Key={
                'employeeId': employee_id,
                'period': period
            }
        )
        
        logger.info(f"Updated performance score: {employee_id} - {period}")
        return updated_response.get('Item')
    
    except Exception as e:
        logger.error(f"Error updating performance score: {str(e)}")
        raise


def delete_performance_score(employee_id, period, user_info):
    """Delete a performance score (Admin only)"""
    try:
        role = user_info.get('role', 'Employee')
        
        # Only Admin can delete scores
        if role != 'Admin':
            logger.warning(f"Non-admin user attempted to delete score: {user_info.get('email')}")
            return False  # Unauthorized
        
        # Delete the score
        performance_table.delete_item(
            Key={
                'employeeId': employee_id,
                'period': period
            }
        )
        
        logger.info(f"Deleted performance score: {employee_id} - {period}")
        return True
    
    except Exception as e:
        logger.error(f"Error deleting performance score: {str(e)}")
        raise


def bulk_create_scores(scores_data, user_info):
    """Bulk create performance scores (Admin and Manager can create)"""
    try:
        role = user_info.get('role', 'Employee')
        
        # Only Admin and Manager can bulk create scores
        if role not in ['Admin', 'Manager']:
            logger.warning(f"Non-admin/manager user attempted to bulk create scores: {user_info.get('email')}")
            return None  # Unauthorized
        
        results = []
        for score_data in scores_data:
            try:
                score = create_performance_score(score_data, user_info)
                results.append({
                    'success': True,
                    'employeeId': score_data.get('employeeId'),
                    'period': score_data.get('period'),
                    'score': score
                })
            except Exception as e:
                logger.error(f"Failed to create score for {score_data.get('employeeId')}: {str(e)}")
                results.append({
                    'success': False,
                    'employeeId': score_data.get('employeeId'),
                    'period': score_data.get('period'),
                    'error': str(e)
                })
        
        return results
    except Exception as e:
        logger.error(f"Error in bulk_create_scores: {str(e)}")
        raise


def parse_csv_upload(csv_content):
    """Parse CSV content and extract scores"""
    import csv
    import io
    
    try:
        lines = csv_content.strip().split('\n')
        if len(lines) < 2:
            raise ValueError("CSV file is empty or invalid")
        
        # Parse header
        header = [h.strip() for h in lines[0].split(',')]
        
        # Find score column (format: YYYY-QN)
        score_col_idx = None
        period = None
        for idx, col in enumerate(header):
            if col and len(col) >= 7 and col[4] == '-' and col[5] == 'Q':
                score_col_idx = idx
                period = col
                break
        
        if score_col_idx is None:
            raise ValueError("No score column found (expected format: YYYY-QN)")
        
        # Parse data rows
        scores = []
        for i in range(1, len(lines)):
            if not lines[i].strip():
                continue
                
            values = [v.strip() for v in lines[i].split(',')]
            
            try:
                employee_id_idx = header.index('employeeId')
                employee_id = values[employee_id_idx]
                score_value = float(values[score_col_idx])
                
                if employee_id and score_value:
                    scores.append({
                        'employeeId': employee_id,
                        'period': period,
                        'KPI': score_value,
                        'completed_task': score_value,
                        'feedback_360': score_value,
                        'final_score': score_value
                    })
            except (ValueError, IndexError) as e:
                logger.warning(f"Skipping invalid row {i}: {str(e)}")
                continue
        
        return scores
    except Exception as e:
        logger.error(f"Error parsing CSV: {str(e)}")
        raise


def generate_template(year, quarter):
    """Generate CSV template for bulk score upload"""
    try:
        # Get all active employees
        emp_response = employees_table.scan(
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        employees = emp_response.get('Items', [])
        
        # Generate CSV content
        csv_lines = []
        csv_lines.append(f"employeeId,name,department,position,{year}-Q{quarter}")
        
        for emp in employees:
            employee_id = emp.get('employeeId', '')
            name = emp.get('name', '')
            department = emp.get('department', '')
            position = emp.get('position', '')
            csv_lines.append(f"{employee_id},{name},{department},{position},")
        
        return '\n'.join(csv_lines)
    except Exception as e:
        logger.error(f"Error generating template: {str(e)}")
        raise


def lambda_handler(event, context):
    """
    Main Lambda handler for performance score CRUD operations.
    
    Endpoints:
    - GET /performance-scores - List all scores with filters
    - GET /performance-scores/{employeeId}/{period} - Get single score
    - POST /performance-scores - Create new score (Admin only)
    - POST /performance-scores/bulk - Bulk create scores (Admin only)
    - POST /performance-scores/upload - Upload CSV file (Admin and Manager)
    - GET /performance-scores/template/{year}/{quarter} - Download template CSV
    - PUT /performance-scores/{employeeId}/{period} - Update score (Admin only)
    - DELETE /performance-scores/{employeeId}/{period} - Delete score (Admin only)
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract HTTP method and path
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        
        # Handle OPTIONS for CORS preflight
        if http_method == 'OPTIONS':
            return response(200, {'message': 'OK'})
        
        # Extract user information from JWT
        user_info = extract_user_info(event)
        
        # Route to appropriate handler
        if http_method == 'GET' and path == '/performance-scores':
            # GET /performance-scores - List all scores with filters
            filters = {
                'department': query_parameters.get('department'),
                'period': query_parameters.get('period'),
                'employeeId': query_parameters.get('employeeId')
            }
            
            scores = list_performance_scores(filters, user_info)
            
            return response(200, {
                'success': True,
                'scores': scores,
                'count': len(scores)
            })
        
        elif http_method == 'GET' and 'template' in path and path_parameters and 'year' in path_parameters:
            # GET /performance-scores/template/{year}/{quarter} - Download template CSV (must come before single score check)
            year = path_parameters.get('year') if path_parameters else None
            quarter = path_parameters.get('quarter') if path_parameters else None
            
            logger.info(f"Template download request - year: {year}, quarter: {quarter}, path_parameters: {path_parameters}")
            
            if not year or not quarter:
                return response(400, {
                    'success': False,
                    'message': f'year and quarter are required. Received year={year}, quarter={quarter}'
                })
            
            try:
                csv_content = generate_template(int(year), int(quarter))
                
                return {
                    'statusCode': 200,
                    'headers': {
                        **cors_headers(),
                        'Content-Type': 'text/csv',
                        'Content-Disposition': f'attachment; filename="performance_scores_template_{year}_Q{quarter}.csv"'
                    },
                    'body': csv_content
                }
            except Exception as e:
                logger.error(f"Error generating template: {str(e)}")
                return response(500, {
                    'success': False,
                    'message': f'Failed to generate template: {str(e)}'
                })
        
        elif http_method == 'GET' and '/performance-scores/' in path:
            # GET /performance-scores/{employeeId}/{period} - Get single score
            employee_id = path_parameters.get('employeeId')
            period = path_parameters.get('period')
            
            if not employee_id or not period:
                return response(400, {
                    'success': False,
                    'message': 'employeeId and period are required'
                })
            
            score = get_single_score(employee_id, period, user_info)
            
            if score is None:
                return response(404, {
                    'success': False,
                    'message': 'Score not found or access denied'
                })
            
            return response(200, {
                'success': True,
                'score': score
            })
        
        elif http_method == 'POST' and path == '/performance-scores/upload':
            # POST /performance-scores/upload - Upload CSV file (Admin and Manager)
            import base64
            
            body = json.loads(event.get('body', '{}'))
            csv_content = body.get('csvContent', '')
            
            if not csv_content:
                return response(400, {
                    'success': False,
                    'message': 'csvContent is required'
                })
            
            # Parse CSV and extract scores
            try:
                scores_data = parse_csv_upload(csv_content)
                
                if not scores_data:
                    return response(400, {
                        'success': False,
                        'message': 'No valid scores found in CSV'
                    })
                
                # Bulk create scores
                results = bulk_create_scores(scores_data, user_info)
                
                if results is None:
                    return response(403, {
                        'success': False,
                        'message': 'Access denied. Admin or Manager role required.'
                    })
                
                success_count = sum(1 for r in results if r.get('success'))
                
                return response(200, {
                    'success': True,
                    'results': results,
                    'summary': {
                        'total': len(results),
                        'success': success_count,
                        'failed': len(results) - success_count
                    },
                    'message': f'Upload completed: {success_count}/{len(results)} scores created'
                })
            except ValueError as e:
                return response(400, {
                    'success': False,
                    'message': str(e)
                })
        
        elif http_method == 'POST' and path == '/performance-scores/bulk':
            # POST /performance-scores/bulk - Bulk create scores (Admin only)
            body = json.loads(event.get('body', '{}'))
            scores_data = body.get('scores', [])
            
            if not scores_data:
                return response(400, {
                    'success': False,
                    'message': 'scores array is required'
                })
            
            results = bulk_create_scores(scores_data, user_info)
            
            if results is None:
                return response(403, {
                    'success': False,
                    'message': 'Access denied. Admin or Manager role required.'
                })
            
            success_count = sum(1 for r in results if r.get('success'))
            
            return response(200, {
                'success': True,
                'results': results,
                'summary': {
                    'total': len(results),
                    'success': success_count,
                    'failed': len(results) - success_count
                },
                'message': f'Bulk operation completed: {success_count}/{len(results)} scores created'
            })
        
        elif http_method == 'POST' and path == '/performance-scores':
            # POST /performance-scores - Create new score (Admin only)
            body = json.loads(event.get('body', '{}'))
            
            score = create_performance_score(body, user_info)
            
            if score is None:
                return response(403, {
                    'success': False,
                    'message': 'Access denied. Admin or Manager role required, and Managers can only create scores in their department.'
                })
            
            return response(201, {
                'success': True,
                'score': score,
                'message': 'Performance score created successfully'
            })
        
        elif http_method == 'PUT' and '/performance-scores/' in path:
            # PUT /performance-scores/{employeeId}/{period} - Update score (Admin and Manager)
            employee_id = path_parameters.get('employeeId')
            period = path_parameters.get('period')
            body = json.loads(event.get('body', '{}'))
            
            if not employee_id or not period:
                return response(400, {
                    'success': False,
                    'message': 'employeeId and period are required'
                })
            
            score = update_performance_score(employee_id, period, body, user_info)
            
            if score is None:
                return response(403, {
                    'success': False,
                    'message': 'Access denied. Admin or Manager role required, and Managers can only update scores in their department.'
                })
            
            return response(200, {
                'success': True,
                'score': score,
                'message': 'Performance score updated successfully'
            })
        
        elif http_method == 'DELETE' and '/performance-scores/' in path:
            # DELETE /performance-scores/{employeeId}/{period} - Delete score (Admin only)
            employee_id = path_parameters.get('employeeId')
            period = path_parameters.get('period')
            
            if not employee_id or not period:
                return response(400, {
                    'success': False,
                    'message': 'employeeId and period are required'
                })
            
            success = delete_performance_score(employee_id, period, user_info)
            
            if not success:
                return response(403, {
                    'success': False,
                    'message': 'Access denied. Admin role required.'
                })
            
            return response(200, {
                'success': True,
                'message': 'Performance score deleted successfully'
            })
        
        else:
            return response(404, {
                'success': False,
                'message': 'Endpoint not found'
            })
    
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return response(400, {
            'success': False,
            'message': str(e)
        })
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return response(500, {
            'success': False,
            'message': 'Internal server error',
            'error': str(e)
        })
