import json
import boto3
import os
from datetime import datetime, time, timezone, timedelta
from decimal import Decimal
from boto3.dynamodb.conditions import Key, Attr

# Application timezone: UTC+7 (Bangkok/Jakarta)
APP_TIMEZONE = timezone(timedelta(hours=7))

dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')

ATTENDANCE_TABLE = os.environ.get('ATTENDANCE_TABLE', 'insighthr-attendance-history-dev')
EMPLOYEES_TABLE = os.environ.get('EMPLOYEES_TABLE', 'insighthr-employees-dev')
USERS_TABLE = os.environ.get('USERS_TABLE', 'insighthr-users-dev')
AWS_REGION = os.environ.get('AWS_REGION', 'ap-southeast-1')

attendance_table = dynamodb.Table(ATTENDANCE_TABLE)
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
users_table = dynamodb.Table(USERS_TABLE)


def lambda_handler(event, context):
    """Main Lambda handler for attendance operations"""
    print(f"Event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_parameters = event.get('pathParameters') or {}
    query_parameters = event.get('queryStringParameters') or {}
    
    try:
        # Public endpoints (no auth required)
        if path == '/attendance/check-in' and http_method == 'POST':
            return handle_check_in(event)
        elif path == '/attendance/check-out' and http_method == 'POST':
            return handle_check_out(event)
        elif path.endswith('/status') and http_method == 'GET':
            return handle_check_status(path_parameters)
        
        # Protected endpoints (auth required)
        # Extract user info from JWT (passed by API Gateway authorizer)
        user_email = extract_user_email(event)
        user_role, user_department = get_user_info(user_email)
        
        if path == '/attendance' and http_method == 'GET':
            return handle_list_attendance(query_parameters, user_role, user_department)
        elif path.startswith('/attendance/') and '/' in path[13:] and http_method == 'GET':
            return handle_get_attendance(path_parameters, user_role, user_department)
        elif path == '/attendance' and http_method == 'POST':
            return handle_create_attendance(event, user_role, user_department)
        elif path.startswith('/attendance/') and '/' in path[13:] and http_method == 'PUT':
            return handle_update_attendance(event, path_parameters, user_role, user_department)
        elif path.startswith('/attendance/') and '/' in path[13:] and http_method == 'DELETE':
            return handle_delete_attendance(path_parameters, user_role)
        elif path == '/attendance/bulk' and http_method == 'POST':
            return handle_bulk_import(event, user_role, user_department)
        else:
            return response(404, {'error': 'Not found'})
            
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_check_in(event):
    """Handle public check-in (no auth required)"""
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employeeId')
        
        if not employee_id:
            return response(400, {'error': 'employeeId is required'})
        
        # Verify employee exists
        employee = get_employee(employee_id)
        if not employee:
            return response(404, {'error': 'Employee not found'})
        
        # Check for existing check-in today (use app timezone)
        now = datetime.now(APP_TIMEZONE)
        today = now.strftime('%Y-%m-%d')
        existing = get_attendance_record(employee_id, today)
        
        if existing and existing.get('checkIn'):
            return response(400, {
                'error': 'Already checked in today',
                'checkIn': existing.get('checkIn')
            })
        
        # Create check-in record
        check_in_time = now.strftime('%H:%M')
        
        # Determine status based on check-in time
        status = determine_check_in_status(check_in_time)
        
        # Calculate initial points (will be updated on check-out)
        points360 = 0
        
        record = {
            'employeeId': employee_id,
            'date': today,
            'checkIn': check_in_time,
            'position': employee.get('position', ''),
            'department': employee.get('department', ''),
            'status': status,
            'points360': Decimal(str(points360)),
            'paidLeave': False,
            'createdAt': now.isoformat(),
            'updatedAt': now.isoformat()
        }
        
        attendance_table.put_item(Item=record)
        
        return response(200, {
            'success': True,
            'message': 'Check-in successful',
            'employeeName': employee.get('name', employee_id),
            'date': today,
            'checkIn': check_in_time,
            'status': status
        })
        
    except Exception as e:
        print(f"Check-in error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_check_out(event):
    """Handle public check-out (no auth required)"""
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employeeId')
        
        if not employee_id:
            return response(400, {'error': 'employeeId is required'})
        
        # Verify employee exists
        employee = get_employee(employee_id)
        if not employee:
            return response(404, {'error': 'Employee not found'})
        
        # Check for existing check-in today (use app timezone)
        now = datetime.now(APP_TIMEZONE)
        today = now.strftime('%Y-%m-%d')
        existing = get_attendance_record(employee_id, today)
        
        if not existing or not existing.get('checkIn'):
            return response(400, {'error': 'No check-in found for today'})
        
        if existing.get('checkOut'):
            return response(400, {
                'error': 'Already checked out today',
                'checkOut': existing.get('checkOut')
            })
        
        # Update with check-out time
        check_out_time = now.strftime('%H:%M')
        check_in_time = existing.get('checkIn')
        
        # Determine final status and calculate points
        status, points360 = calculate_final_status_and_points(check_in_time, check_out_time)
        
        # Update record
        attendance_table.update_item(
            Key={'employeeId': employee_id, 'date': today},
            UpdateExpression='SET checkOut = :co, #status = :status, points360 = :points, updatedAt = :updated',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':co': check_out_time,
                ':status': status,
                ':points': Decimal(str(points360)),
                ':updated': now.isoformat()
            }
        )
        
        return response(200, {
            'success': True,
            'message': 'Check-out successful',
            'employeeName': employee.get('name', employee_id),
            'date': today,
            'checkOut': check_out_time,
            'status': status,
            'points360': float(points360)
        })
        
    except Exception as e:
        print(f"Check-out error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_check_status(path_parameters):
    """Check if employee has ongoing session"""
    try:
        employee_id = path_parameters.get('employeeId')
        if not employee_id:
            return response(400, {'error': 'employeeId is required'})
        
        # Verify employee exists
        employee = get_employee(employee_id)
        if not employee:
            return response(404, {'error': 'Employee not found'})
        
        # Check today's record (use app timezone)
        now = datetime.now(APP_TIMEZONE)
        today = now.strftime('%Y-%m-%d')
        record = get_attendance_record(employee_id, today)
        
        if record and record.get('checkIn') and not record.get('checkOut'):
            return response(200, {
                'hasSession': True,
                'employeeId': employee_id,
                'employeeName': employee.get('name', employee_id),
                'checkIn': record.get('checkIn'),
                'date': today
            })
        else:
            return response(200, {'hasSession': False})
            
    except Exception as e:
        print(f"Check status error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_list_attendance(query_params, user_role, user_department):
    """List attendance records with filters"""
    try:
        department = query_params.get('department')
        start_date = query_params.get('startDate')
        end_date = query_params.get('endDate')
        employee_id = query_params.get('employeeId')
        status_filter = query_params.get('status')
        
        # Role-based filtering
        if user_role == 'Manager' and not department:
            department = user_department
        elif user_role == 'Employee':
            return response(403, {'error': 'Employees cannot access attendance management'})
        
        # Build filter expression
        filter_expressions = []
        expression_values = {}
        expression_names = {}
        
        if department:
            filter_expressions.append('department = :dept')
            expression_values[':dept'] = department
        
        if status_filter:
            filter_expressions.append('#status = :status')
            expression_names['#status'] = 'status'
            expression_values[':status'] = status_filter
        
        # Scan with filters
        scan_kwargs = {}
        if filter_expressions:
            scan_kwargs['FilterExpression'] = ' AND '.join(filter_expressions)
            scan_kwargs['ExpressionAttributeValues'] = expression_values
            if expression_names:
                scan_kwargs['ExpressionAttributeNames'] = expression_names
        
        result = attendance_table.scan(**scan_kwargs)
        items = result.get('Items', [])
        
        # Convert Decimal to float for JSON serialization
        items = convert_decimals(items)
        
        # Apply date range filter (post-scan)
        if start_date:
            items = [item for item in items if item.get('date', '') >= start_date]
        if end_date:
            items = [item for item in items if item.get('date', '') <= end_date]
        if employee_id:
            items = [item for item in items if item.get('employeeId') == employee_id]
        
        return response(200, {'records': items, 'count': len(items)})
        
    except Exception as e:
        print(f"List attendance error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_get_attendance(path_params, user_role, user_department):
    """Get single attendance record"""
    try:
        employee_id = path_params.get('employeeId')
        date = path_params.get('date')
        
        if not employee_id or not date:
            return response(400, {'error': 'employeeId and date are required'})
        
        record = get_attendance_record(employee_id, date)
        
        if not record:
            return response(404, {'error': 'Attendance record not found'})
        
        # Role-based access check
        if user_role == 'Manager' and record.get('department') != user_department:
            return response(403, {'error': 'Access denied'})
        
        record = convert_decimals(record)
        return response(200, record)
        
    except Exception as e:
        print(f"Get attendance error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_create_attendance(event, user_role, user_department):
    """Create attendance record manually (Admin/Manager only)"""
    try:
        if user_role not in ['Admin', 'Manager']:
            return response(403, {'error': 'Only Admin and Manager can create attendance records'})
        
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employeeId')
        date = body.get('date')
        
        if not employee_id or not date:
            return response(400, {'error': 'employeeId and date are required'})
        
        # Verify employee exists
        employee = get_employee(employee_id)
        if not employee:
            return response(404, {'error': 'Employee not found'})
        
        # Manager can only create for their department
        if user_role == 'Manager' and employee.get('department') != user_department:
            return response(403, {'error': 'Can only create attendance for your department'})
        
        # Check if record already exists
        existing = get_attendance_record(employee_id, date)
        if existing:
            return response(400, {'error': 'Attendance record already exists for this date'})
        
        # Create record
        check_in = body.get('checkIn')
        check_out = body.get('checkOut')
        paid_leave = body.get('paidLeave', False)
        reason = body.get('reason', '')
        status = body.get('status', 'work')
        
        # Calculate points if check-in and check-out provided
        points360 = 0
        if check_in and check_out:
            status, points360 = calculate_final_status_and_points(check_in, check_out)
        elif paid_leave:
            status = 'off'
        
        record = {
            'employeeId': employee_id,
            'date': date,
            'position': employee.get('position', ''),
            'department': employee.get('department', ''),
            'status': status,
            'points360': Decimal(str(points360)),
            'paidLeave': paid_leave,
            'createdAt': datetime.now(APP_TIMEZONE).isoformat(),
            'updatedAt': datetime.now(APP_TIMEZONE).isoformat()
        }
        
        if check_in:
            record['checkIn'] = check_in
        if check_out:
            record['checkOut'] = check_out
        if reason:
            record['reason'] = reason
        
        attendance_table.put_item(Item=record)
        
        return response(201, {'success': True, 'record': convert_decimals(record)})
        
    except Exception as e:
        print(f"Create attendance error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_update_attendance(event, path_params, user_role, user_department):
    """Update attendance record (Admin/Manager only)"""
    try:
        if user_role not in ['Admin', 'Manager']:
            return response(403, {'error': 'Only Admin and Manager can update attendance records'})
        
        employee_id = path_params.get('employeeId')
        date = path_params.get('date')
        
        if not employee_id or not date:
            return response(400, {'error': 'employeeId and date are required'})
        
        # Check if record exists
        existing = get_attendance_record(employee_id, date)
        if not existing:
            return response(404, {'error': 'Attendance record not found'})
        
        # Manager can only update their department
        if user_role == 'Manager' and existing.get('department') != user_department:
            return response(403, {'error': 'Can only update attendance for your department'})
        
        body = json.loads(event.get('body', '{}'))
        
        # Build update expression
        update_parts = []
        expression_values = {}
        expression_names = {}
        
        if 'checkIn' in body:
            update_parts.append('checkIn = :ci')
            expression_values[':ci'] = body['checkIn']
        
        if 'checkOut' in body:
            update_parts.append('checkOut = :co')
            expression_values[':co'] = body['checkOut']
        
        if 'status' in body:
            update_parts.append('#status = :status')
            expression_names['#status'] = 'status'
            expression_values[':status'] = body['status']
        
        if 'reason' in body:
            update_parts.append('reason = :reason')
            expression_values[':reason'] = body['reason']
        
        if 'paidLeave' in body:
            update_parts.append('paidLeave = :paidLeave')
            expression_values[':paidLeave'] = body['paidLeave']
        
        # Recalculate points if check-in/out changed
        check_in = body.get('checkIn', existing.get('checkIn'))
        check_out = body.get('checkOut', existing.get('checkOut'))
        if check_in and check_out:
            status, points360 = calculate_final_status_and_points(check_in, check_out)
            update_parts.append('points360 = :points')
            expression_values[':points'] = Decimal(str(points360))
            if 'status' not in body:
                update_parts.append('#status = :status')
                expression_names['#status'] = 'status'
                expression_values[':status'] = status
        
        # Always update updatedAt
        update_parts.append('updatedAt = :updated')
        expression_values[':updated'] = datetime.now(APP_TIMEZONE).isoformat()
        
        if not update_parts:
            return response(400, {'error': 'No fields to update'})
        
        # Update record
        update_kwargs = {
            'Key': {'employeeId': employee_id, 'date': date},
            'UpdateExpression': 'SET ' + ', '.join(update_parts),
            'ExpressionAttributeValues': expression_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_names:
            update_kwargs['ExpressionAttributeNames'] = expression_names
        
        result = attendance_table.update_item(**update_kwargs)
        
        return response(200, {'success': True, 'record': convert_decimals(result['Attributes'])})
        
    except Exception as e:
        print(f"Update attendance error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_delete_attendance(path_params, user_role):
    """Delete attendance record (Admin only)"""
    try:
        if user_role != 'Admin':
            return response(403, {'error': 'Only Admin can delete attendance records'})
        
        employee_id = path_params.get('employeeId')
        date = path_params.get('date')
        
        if not employee_id or not date:
            return response(400, {'error': 'employeeId and date are required'})
        
        attendance_table.delete_item(
            Key={'employeeId': employee_id, 'date': date}
        )
        
        return response(200, {'success': True, 'message': 'Attendance record deleted'})
        
    except Exception as e:
        print(f"Delete attendance error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


def handle_bulk_import(event, user_role, user_department):
    """Bulk import attendance records (Admin/Manager only)"""
    try:
        if user_role not in ['Admin', 'Manager']:
            return response(403, {'error': 'Only Admin and Manager can bulk import attendance'})
        
        body = json.loads(event.get('body', '{}'))
        records = body.get('records', [])
        
        if not records:
            return response(400, {'error': 'No records provided'})
        
        imported = 0
        failed = 0
        errors = []
        
        for idx, record_data in enumerate(records):
            try:
                employee_id = record_data.get('employeeId')
                date = record_data.get('date')
                
                if not employee_id or not date:
                    errors.append({
                        'row': idx + 1,
                        'employeeId': employee_id or 'N/A',
                        'error': 'Missing employeeId or date'
                    })
                    failed += 1
                    continue
                
                # Verify employee
                employee = get_employee(employee_id)
                if not employee:
                    errors.append({
                        'row': idx + 1,
                        'employeeId': employee_id,
                        'error': 'Employee not found'
                    })
                    failed += 1
                    continue
                
                # Manager can only import for their department
                if user_role == 'Manager' and employee.get('department') != user_department:
                    errors.append({
                        'row': idx + 1,
                        'employeeId': employee_id,
                        'error': 'Can only import for your department'
                    })
                    failed += 1
                    continue
                
                # Create record
                check_in = record_data.get('checkIn')
                check_out = record_data.get('checkOut')
                status = record_data.get('status', 'work')
                reason = record_data.get('reason', '')
                paid_leave = record_data.get('paidLeave', False)
                
                points360 = 0
                if check_in and check_out:
                    status, points360 = calculate_final_status_and_points(check_in, check_out)
                elif paid_leave:
                    status = 'off'
                
                record = {
                    'employeeId': employee_id,
                    'date': date,
                    'position': employee.get('position', ''),
                    'department': employee.get('department', ''),
                    'status': status,
                    'points360': Decimal(str(points360)),
                    'paidLeave': paid_leave,
                    'createdAt': datetime.now(APP_TIMEZONE).isoformat(),
                    'updatedAt': datetime.now(APP_TIMEZONE).isoformat()
                }
                
                if check_in:
                    record['checkIn'] = check_in
                if check_out:
                    record['checkOut'] = check_out
                if reason:
                    record['reason'] = reason
                
                attendance_table.put_item(Item=record)
                imported += 1
                
            except Exception as e:
                errors.append({
                    'row': idx + 1,
                    'employeeId': record_data.get('employeeId', 'N/A'),
                    'error': str(e)
                })
                failed += 1
        
        return response(200, {
            'success': True,
            'imported': imported,
            'failed': failed,
            'errors': errors if errors else None
        })
        
    except Exception as e:
        print(f"Bulk import error: {str(e)}")
        import traceback
        traceback.print_exc()
        return response(500, {'error': str(e)})


# Helper functions

def get_employee(employee_id):
    """Get employee from Employees table"""
    try:
        result = employees_table.get_item(Key={'employeeId': employee_id})
        return result.get('Item')
    except Exception as e:
        print(f"Error getting employee: {str(e)}")
        return None


def get_attendance_record(employee_id, date):
    """Get attendance record"""
    try:
        result = attendance_table.get_item(
            Key={'employeeId': employee_id, 'date': date}
        )
        return result.get('Item')
    except Exception as e:
        print(f"Error getting attendance record: {str(e)}")
        return None


def determine_check_in_status(check_in_time):
    """Determine status based on check-in time"""
    try:
        hour, minute = map(int, check_in_time.split(':'))
        check_in = time(hour, minute)
        
        if check_in < time(6, 0):
            return 'early_bird'
        elif check_in > time(9, 0):
            return 'late'
        else:
            return 'work'
    except:
        return 'work'


def calculate_final_status_and_points(check_in_time, check_out_time):
    """Calculate final status and 360 points based on check-in and check-out times"""
    try:
        # Parse times
        ci_hour, ci_minute = map(int, check_in_time.split(':'))
        co_hour, co_minute = map(int, check_out_time.split(':'))
        
        check_in = time(ci_hour, ci_minute)
        check_out = time(co_hour, co_minute)
        
        # Calculate hours worked
        ci_minutes = ci_hour * 60 + ci_minute
        co_minutes = co_hour * 60 + co_minute
        total_minutes = co_minutes - ci_minutes
        hours_worked = total_minutes / 60.0
        
        # Base points: 10 points per hour
        base_points_per_hour = 10
        points = 0
        status = 'work'
        
        # Early bird bonus (before 6:00 AM, 1.25x until 8:00 AM)
        if check_in < time(6, 0):
            early_end = min(time(8, 0), check_out)
            early_minutes = (early_end.hour * 60 + early_end.minute) - (6 * 60)
            if early_minutes > 0:
                early_hours = early_minutes / 60.0
                points += early_hours * base_points_per_hour * 1.25
                status = 'early_bird'
        
        # Regular work hours (6:00 AM - 5:00 PM)
        regular_start = max(check_in, time(6, 0))
        regular_end = min(check_out, time(17, 0))
        if regular_end > regular_start:
            regular_minutes = (regular_end.hour * 60 + regular_end.minute) - (regular_start.hour * 60 + regular_start.minute)
            regular_hours = regular_minutes / 60.0
            points += regular_hours * base_points_per_hour
        
        # Overtime bonus (after 5:00 PM, 1.5x)
        if check_out > time(17, 0):
            ot_minutes = (co_hour * 60 + co_minute) - (17 * 60)
            ot_hours = ot_minutes / 60.0
            points += ot_hours * base_points_per_hour * 1.5
            status = 'OT'
        
        # Late penalty
        if check_in > time(9, 0) and status == 'work':
            status = 'late'
        
        return status, round(points, 2)
        
    except Exception as e:
        print(f"Error calculating points: {str(e)}")
        return 'work', 0


def extract_user_email(event):
    """Extract user email from JWT claims (set by API Gateway authorizer)"""
    try:
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        return claims.get('email', '')
    except:
        return ''


def get_user_info(email):
    """Get user role and department from Users table"""
    try:
        # Query by email using GSI
        result = users_table.query(
            IndexName='email-index',
            KeyConditionExpression=Key('email').eq(email)
        )
        
        items = result.get('Items', [])
        if items:
            user = items[0]
            return user.get('role', 'Employee'), user.get('department', '')
        
        return 'Employee', ''
    except Exception as e:
        print(f"Error getting user info: {str(e)}")
        return 'Employee', ''


def convert_decimals(obj):
    """Convert Decimal objects to float for JSON serialization"""
    if isinstance(obj, list):
        return [convert_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj


def response(status_code, body):
    """Create HTTP response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body)
    }
