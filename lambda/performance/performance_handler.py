import json
import boto3
import os
import logging
from decimal import Decimal
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'ap-southeast-1'))
lambda_client = boto3.client('lambda', region_name=os.environ.get('AWS_REGION', 'ap-southeast-1'))

# Environment variables
PERFORMANCE_SCORES_TABLE = os.environ.get('PERFORMANCE_SCORES_TABLE', 'insighthr-performance-scores-dev')
EMPLOYEES_TABLE = os.environ.get('EMPLOYEES_TABLE', 'insighthr-employees-dev')
AUTO_SCORING_LAMBDA_ARN = os.environ.get('AUTO_SCORING_LAMBDA_ARN', '')
AWS_REGION = os.environ.get('AWS_REGION', 'ap-southeast-1')

# Get table references
performance_table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)
employees_table = dynamodb.Table(EMPLOYEES_TABLE)


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
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
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
        
        # Query Users table to get role and employeeId
        users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'insighthr-users-dev'))
        
        try:
            response = users_table.get_item(Key={'userId': user_id})
            user_data = response.get('Item', {})
            
            role = user_data.get('role', 'Employee')
            employee_id = user_data.get('employeeId', '')
            department = user_data.get('department', '')
            
            logger.info(f"Extracted user info from Users table - userId: {user_id}, email: {email}, role: {role}, employeeId: {employee_id}, department: {department}")
        except Exception as e:
            logger.warning(f"Failed to query Users table: {str(e)}, using defaults")
            role = 'Employee'
            employee_id = ''
            department = ''
        
        return {
            'userId': user_id,
            'email': email,
            'role': role,
            'employeeId': employee_id,
            'department': department
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


def trigger_auto_scoring():
    """
    Optionally trigger auto-scoring Lambda if configured.
    This is for Phase 5 integration - gracefully degrades if not available.
    """
    if not AUTO_SCORING_LAMBDA_ARN:
        logger.info("AUTO_SCORING_LAMBDA_ARN not configured - skipping auto-scoring trigger")
        return False
    
    try:
        logger.info(f"Invoking auto-scoring Lambda: {AUTO_SCORING_LAMBDA_ARN}")
        lambda_client.invoke(
            FunctionName=AUTO_SCORING_LAMBDA_ARN,
            InvocationType='Event',  # Async invocation
            Payload=json.dumps({'trigger': 'performance_query'})
        )
        logger.info("Auto-scoring Lambda invoked successfully")
        return True
    except Exception as e:
        logger.warning(f"Auto-scoring Lambda invocation failed: {str(e)}")
        logger.info("Continuing with existing performance data")
        return False


def get_all_performance_scores(filters, user_info):
    """
    Query performance scores with filters and role-based access control.
    
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
            response = performance_table.query(
                KeyConditionExpression='employeeId = :empId',
                ExpressionAttributeValues={':empId': user_employee_id}
            )
            scores = response.get('Items', [])
            
            # Apply period filter if specified
            period_filter = filters.get('period')
            if period_filter:
                scores = [s for s in scores if s.get('period') == period_filter]
            
            return scores
        
        elif role == 'Manager':
            # Managers can see their department's data
            department = filters.get('department', user_department)
            if not department:
                logger.warning(f"Manager user has no department: {user_info.get('email')}")
                return []
            
            # Query using GSI: department-period-index
            period_filter = filters.get('period')
            
            if period_filter:
                # Query with both department and period
                response = performance_table.query(
                    IndexName='department-period-index',
                    KeyConditionExpression='department = :dept AND period = :per',
                    ExpressionAttributeValues={
                        ':dept': department,
                        ':per': period_filter
                    }
                )
            else:
                # Query with department only
                response = performance_table.query(
                    IndexName='department-period-index',
                    KeyConditionExpression='department = :dept',
                    ExpressionAttributeValues={':dept': department}
                )
            
            scores = response.get('Items', [])
            
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
                response = performance_table.query(
                    KeyConditionExpression='employeeId = :empId',
                    ExpressionAttributeValues={':empId': employee_filter}
                )
                scores = response.get('Items', [])
                
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
                    response = performance_table.query(
                        IndexName='department-period-index',
                        KeyConditionExpression='department = :dept AND period = :per',
                        ExpressionAttributeValues={
                            ':dept': department_filter,
                            ':per': period_filter
                        }
                    )
                else:
                    response = performance_table.query(
                        IndexName='department-period-index',
                        KeyConditionExpression='department = :dept',
                        ExpressionAttributeValues={':dept': department_filter}
                    )
                
                return response.get('Items', [])
            
            else:
                # Scan all data (no filters)
                response = performance_table.scan()
                scores = response.get('Items', [])
                
                # Apply period filter if specified
                if period_filter:
                    scores = [s for s in scores if s.get('period') == period_filter]
                
                return scores
    
    except Exception as e:
        logger.error(f"Error querying performance scores: {str(e)}")
        raise


def get_employee_performance_history(employee_id, user_info):
    """
    Get performance history for a specific employee.
    Role-based access control applies.
    """
    try:
        role = user_info.get('role', 'Employee')
        user_employee_id = user_info.get('employeeId', '')
        user_department = user_info.get('department', '')
        
        # Check access permissions
        if role == 'Employee' and employee_id != user_employee_id:
            logger.warning(f"Employee {user_employee_id} attempted to access data for {employee_id}")
            return None  # Unauthorized
        
        # Query performance scores for the employee
        response = performance_table.query(
            KeyConditionExpression='employeeId = :empId',
            ExpressionAttributeValues={':empId': employee_id}
        )
        scores = response.get('Items', [])
        
        # For Managers, verify the employee is in their department
        if role == 'Manager' and scores:
            employee_dept = scores[0].get('department', '')
            if employee_dept != user_department:
                logger.warning(f"Manager from {user_department} attempted to access employee from {employee_dept}")
                return None  # Unauthorized
        
        # Sort by period (descending)
        scores.sort(key=lambda x: x.get('period', ''), reverse=True)
        
        return scores
    
    except Exception as e:
        logger.error(f"Error getting employee performance history: {str(e)}")
        raise


def generate_csv_export(scores):
    """
    Generate CSV export data from performance scores.
    Returns CSV string.
    """
    try:
        if not scores:
            return "No data available"
        
        # CSV header
        csv_lines = ["Employee ID,Employee Name,Department,Position,Period,Overall Score,KPI Scores"]
        
        # CSV rows
        for score in scores:
            employee_id = score.get('employeeId', '')
            employee_name = score.get('employeeName', '')
            department = score.get('department', '')
            position = score.get('position', '')
            period = score.get('period', '')
            overall_score = score.get('overallScore', 0)
            kpi_scores = score.get('kpiScores', {})
            
            # Format KPI scores as JSON string
            kpi_scores_str = json.dumps(kpi_scores, cls=DecimalEncoder)
            
            csv_lines.append(f"{employee_id},{employee_name},{department},{position},{period},{overall_score},\"{kpi_scores_str}\"")
        
        return "\n".join(csv_lines)
    
    except Exception as e:
        logger.error(f"Error generating CSV export: {str(e)}")
        raise


def lambda_handler(event, context):
    """
    Main Lambda handler for performance data operations.
    
    Endpoints:
    - GET /performance - Get all performance scores with filters
    - GET /performance/{employeeId} - Get employee performance history
    - POST /performance/export - Export performance data as CSV
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract HTTP method and path
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        
        # Extract user information from JWT
        user_info = extract_user_info(event)
        
        # Optional: Trigger auto-scoring Lambda (Phase 5 feature)
        trigger_auto_scoring()
        
        # Route to appropriate handler
        if http_method == 'GET' and path == '/performance':
            # GET /performance - Get all performance scores with filters
            filters = {
                'department': query_parameters.get('department'),
                'period': query_parameters.get('period'),
                'employeeId': query_parameters.get('employeeId')
            }
            
            scores = get_all_performance_scores(filters, user_info)
            
            return response(200, {
                'success': True,
                'scores': scores,
                'count': len(scores)
            })
        
        elif http_method == 'GET' and '/performance/' in path:
            # GET /performance/{employeeId} - Get employee performance history
            employee_id = path_parameters.get('employeeId')
            
            if not employee_id:
                return response(400, {
                    'success': False,
                    'message': 'Employee ID is required'
                })
            
            scores = get_employee_performance_history(employee_id, user_info)
            
            if scores is None:
                return response(403, {
                    'success': False,
                    'message': 'Access denied'
                })
            
            return response(200, {
                'success': True,
                'employeeId': employee_id,
                'scores': scores,
                'count': len(scores)
            })
        
        elif http_method == 'POST' and path == '/performance/export':
            # POST /performance/export - Export performance data as CSV
            body = json.loads(event.get('body', '{}'))
            filters = body.get('filters', {})
            
            scores = get_all_performance_scores(filters, user_info)
            csv_data = generate_csv_export(scores)
            
            return {
                'statusCode': 200,
                'headers': {
                    **cors_headers(),
                    'Content-Type': 'text/csv',
                    'Content-Disposition': 'attachment; filename="performance_export.csv"'
                },
                'body': csv_data
            }
        
        else:
            return response(404, {
                'success': False,
                'message': 'Endpoint not found'
            })
    
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return response(500, {
            'success': False,
            'message': 'Internal server error',
            'error': str(e)
        })
