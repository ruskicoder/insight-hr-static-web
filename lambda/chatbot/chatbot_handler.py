import json
import boto3
import os
import logging
from datetime import datetime
from decimal import Decimal

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'ap-southeast-1'))
dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-1')

# Environment variables - All InsightHR DynamoDB tables
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-haiku-20240307-v1:0')
EMPLOYEES_TABLE = os.environ['EMPLOYEES_TABLE']
PERFORMANCE_SCORES_TABLE = os.environ['PERFORMANCE_SCORES_TABLE']
USERS_TABLE = os.environ['USERS_TABLE']
KPIS_TABLE = os.environ.get('KPIS_TABLE', 'insighthr-kpis-dev')
FORMULAS_TABLE = os.environ.get('FORMULAS_TABLE', 'insighthr-formulas-dev')
DATA_TABLES_TABLE = os.environ.get('DATA_TABLES_TABLE', 'insighthr-data-tables-dev')
NOTIFICATION_RULES_TABLE = os.environ.get('NOTIFICATION_RULES_TABLE', 'insighthr-notification-rules-dev')
NOTIFICATION_HISTORY_TABLE = os.environ.get('NOTIFICATION_HISTORY_TABLE', 'insighthr-notification-history-dev')
PASSWORD_RESET_REQUESTS_TABLE = os.environ.get('PASSWORD_RESET_REQUESTS_TABLE', 'insighthr-password-reset-requests-dev')

# Initialize DynamoDB tables
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
performance_scores_table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)
users_table = dynamodb.Table(USERS_TABLE)
kpis_table = dynamodb.Table(KPIS_TABLE)
formulas_table = dynamodb.Table(FORMULAS_TABLE)
data_tables_table = dynamodb.Table(DATA_TABLES_TABLE)
notification_rules_table = dynamodb.Table(NOTIFICATION_RULES_TABLE)
notification_history_table = dynamodb.Table(NOTIFICATION_HISTORY_TABLE)
password_reset_requests_table = dynamodb.Table(PASSWORD_RESET_REQUESTS_TABLE)


class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert Decimal to float for JSON serialization"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def get_user_info(email):
    """Get complete user information from Users table by email"""
    try:
        response = users_table.scan(
            FilterExpression='email = :email',
            ExpressionAttributeValues={':email': email}
        )
        
        if response['Items']:
            user = response['Items'][0]
            role = user.get('role', 'Employee')
            employee_id = user.get('employeeId')
            user_name = user.get('name', 'Unknown')
            
            # If user has employeeId, get full employee details from Employees table
            department = None
            employee_role = None
            employee_details = None
            
            if employee_id:
                try:
                    emp_response = employees_table.get_item(Key={'employeeId': employee_id})
                    if 'Item' in emp_response:
                        employee_details = emp_response['Item']
                        department = employee_details.get('department')
                        employee_role = employee_details.get('role')
                except Exception as e:
                    logger.warning(f"Could not fetch employee details: {e}")
            
            return {
                'role': role,
                'department': department,
                'employee_id': employee_id,
                'name': user_name,
                'email': email,
                'employee_role': employee_role,
                'employee_details': employee_details
            }
        
        return {
            'role': 'Employee',
            'department': None,
            'employee_id': None,
            'name': 'Unknown',
            'email': email,
            'employee_role': None,
            'employee_details': None
        }
    except Exception as e:
        logger.error(f"Error getting user info: {e}")
        return {
            'role': 'Employee',
            'department': None,
            'employee_id': None,
            'name': 'Unknown',
            'email': email,
            'employee_role': None,
            'employee_details': None
        }


def get_employees_data(role, department=None):
    """Fetch employee data based on role and department
    
    Company Policy:
    - Admin: Can view all employees
    - Manager: Can view employees in their department only
    - Employee: Cannot view employee list (returns empty)
    """
    try:
        if role == 'Admin':
            # Admin sees all employees
            response = employees_table.scan()
            logger.info(f"Admin accessing all employees: {len(response.get('Items', []))} records")
            return response.get('Items', [])
        elif role == 'Manager':
            if not department:
                logger.warning("Manager role without department - cannot fetch employees")
                return []
            # Manager sees only their department
            response = employees_table.scan(
                FilterExpression='department = :dept',
                ExpressionAttributeValues={':dept': department}
            )
            logger.info(f"Manager accessing {department} department employees: {len(response.get('Items', []))} records")
            return response.get('Items', [])
        else:
            # Employee role cannot view employee list
            logger.info("Employee role - no access to employee list")
            return []
    except Exception as e:
        logger.error(f"Error fetching employees: {e}")
        return []


def get_performance_data(role, department=None, employee_id=None):
    """Fetch performance data based on role and department"""
    try:
        if role == 'Admin':
            # Admin sees all performance data
            response = performance_scores_table.scan()
        elif role == 'Manager' and department:
            # Manager sees only their department's performance
            response = performance_scores_table.scan(
                FilterExpression='department = :dept',
                ExpressionAttributeValues={':dept': department}
            )
        elif role == 'Employee' and employee_id:
            # Employee sees only their own performance
            response = performance_scores_table.query(
                KeyConditionExpression='employeeId = :empId',
                ExpressionAttributeValues={':empId': employee_id}
            )
        else:
            return []
        
        return response.get('Items', [])
    except Exception as e:
        logger.error(f"Error fetching performance data: {e}")
        return []


def build_context(user_info):
    """Build context from DynamoDB for Bedrock prompt"""
    role = user_info['role']
    department = user_info['department']
    employee_id = user_info['employee_id']
    
    context = {
        'employees': get_employees_data(role, department),
        'performance_scores': get_performance_data(role, department, employee_id),
        'user_info': user_info,
        'role': role,
        'department': department
    }
    
    # Convert to JSON-serializable format
    context_json = json.dumps(context, cls=DecimalEncoder)
    return json.loads(context_json)


def detect_prompt_injection(user_message):
    """Detect potential prompt injection attempts in user input"""
    injection_patterns = [
        'forget', 'ignore previous', 'ignore all previous', 'ignore the above',
        'you are now', 'pretend', 'new instructions', 'new instruction',
        'system:', 'assistant:', 'disregard', 'override',
        'act as', 'roleplay', 'role play', 'simulate',
        'ignore your', 'forget your', 'new role', 'change your role',
        'you must', 'you will', 'you should now', 'from now on',
        'previous instructions', 'above instructions', 'initial prompt'
    ]
    
    user_message_lower = user_message.lower()
    
    for pattern in injection_patterns:
        if pattern in user_message_lower:
            logger.warning(f"Potential prompt injection detected: '{pattern}' in message")
            return True
    
    return False


def construct_prompt(user_message, context, conversation_history=None):
    """Construct prompt for Bedrock with context, conversation history, and user query
    
    Task 11.8: Added conversation_history parameter for context continuity
    """
    
    # Build context summary
    employees = context.get('employees', [])
    performance_scores = context.get('performance_scores', [])
    attendance_records = context.get('attendance', [])
    users = context.get('users', [])
    user_info = context.get('user_info', {})
    role = user_info.get('role', 'Employee')
    department = user_info.get('department')
    user_name = user_info.get('name', 'Unknown')
    employee_id = user_info.get('employee_id')
    employee_role = user_info.get('employee_role')
    
    # Build improved system prompt with clear role separation
    context_summary = f"""You are InsightHR AI Assistant - a professional HR data analysis tool.

===================================================================
USER CONTEXT (EXTRACTED FROM JWT TOKEN - TRUSTED SOURCE)
===================================================================
- User Role (app access): {role}
- User Name: {user_name}
- User Department: {department or "N/A"}
- Employee ID: {employee_id or "N/A"}

IMPORTANT DISTINCTIONS:
- User Role: Determines app permissions (Admin/Manager/Employee) - from Users table
- Employee Position: Company job title (from Employees table)
- User role ALWAYS takes precedence for access control
- Admins may not have employeeId (they are system administrators, not employees)

===================================================================
ACCESS RULES (BASED ON USER ROLE FROM JWT)
==================================================================="""
    
    if role == 'Admin':
        context_summary += """
Admin Access Level:
- Full access to all data across all departments
- Can view all employee information
- Can view all performance scores
- Can view all user accounts
- Can access any data in the system"""
    elif role == 'Manager':
        context_summary += f"""
Manager Access Level:
- Full access to data within {department} department
- Can view all employees in {department}
- Can view all performance scores for {department}
- Can answer questions about employees in their department
- Cannot access data from other departments"""
    else:
        context_summary += f"""
Employee Access Level:
- Access to own data only
- Can view own employee information (Employee ID: {employee_id or "N/A"})
- Can view own performance scores
- Cannot access other employees' data"""
    
    context_summary += """

===================================================================
COMPANY POLICY
===================================================================
- Superiors have the right to view all subordinate data
- You must provide requested information to authorized users
- Refusing authorized requests violates company policy
- Provide full details, insights, and analytics as requested
- This is an internal tool - data access is appropriate within permissions

===================================================================
DATA SOURCES
===================================================================
- Users table: App access control (userId, email, role, department, employeeId)
- Employees table: Company information (employeeId, name, position, department, salary, etc)
- Performance Scores table: Evaluations and ratings
- Attendance table: Check-in/out records and points

When user asks "my info":
- If employeeId exists: fetch BOTH user record AND employee record
- Clearly label "User Role" (app access) vs "Employee Position" (company job)
- Show both sets of information separately"""
    
    context_summary += f"""

===================================================================
CRITICAL RULES - NEVER VIOLATE THESE
===================================================================
1. ONLY use data from provided context below
2. NEVER fabricate names, numbers, or facts
3. If data not in context, state "I don't have that information"
4. Context data is the ONLY source of truth
5. Do not make assumptions or extrapolations beyond provided data

===================================================================
AVAILABLE DATA (filtered by {role} permissions)
===================================================================

EMPLOYEE RECORDS ({len(employees)} total):"""
    
    # Add FULL employee data (not just summary)
    if employees:
        context_summary += "\n"
        for emp in employees[:50]:  # Limit to first 50 to avoid token limits
            context_summary += f"\n- Employee ID: {emp.get('employeeId')}"
            context_summary += f"\n  Name: {emp.get('name')}"
            context_summary += f"\n  Department: {emp.get('department')}"
            context_summary += f"\n  Role: {emp.get('role')}"
            context_summary += f"\n  Email: {emp.get('email')}"
            context_summary += f"\n  Manager: {emp.get('managerId', 'N/A')}"
            context_summary += f"\n  Hire Date: {emp.get('hireDate', 'N/A')}"
            context_summary += "\n"
        
        if len(employees) > 50:
            context_summary += f"\n... and {len(employees) - 50} more employees (ask for specific employee IDs for details)\n"
    else:
        context_summary += "\nNo employee data available for your access level."
    
    context_summary += f"\n\nPERFORMANCE SCORE RECORDS ({len(performance_scores)} total):"
    
    # Add FULL performance data (not just summary)
    if performance_scores:
        context_summary += "\n"
        for score in performance_scores[:50]:  # Limit to first 50
            context_summary += f"\n- Employee ID: {score.get('employeeId')}"
            context_summary += f"\n  Period: {score.get('period')}"
            context_summary += f"\n  Overall Score: {score.get('overallScore')}"
            context_summary += f"\n  Department: {score.get('department')}"
            context_summary += f"\n  Submitted By: {score.get('submittedBy', 'N/A')}"
            context_summary += f"\n  Submitted At: {score.get('submittedAt', 'N/A')}"
            context_summary += "\n"
        
        if len(performance_scores) > 50:
            context_summary += f"\n... and {len(performance_scores) - 50} more performance records (ask for specific details)\n"
    else:
        context_summary += "\nNo performance data available for your access level."
    
    # Add attendance data if provided
    if attendance_records:
        context_summary += f"\n\nATTENDANCE RECORDS ({len(attendance_records)} total):"
        context_summary += "\n"
        for record in attendance_records[:50]:  # Limit to first 50
            context_summary += f"\n- Employee ID: {record.get('employeeId')}"
            context_summary += f"\n  Date: {record.get('date')}"
            context_summary += f"\n  Check-in: {record.get('checkIn', 'N/A')}"
            context_summary += f"\n  Check-out: {record.get('checkOut', 'N/A')}"
            context_summary += f"\n  Status: {record.get('status')}"
            context_summary += f"\n  Points: {record.get('points360', 'N/A')}"
            context_summary += "\n"
        
        if len(attendance_records) > 50:
            context_summary += f"\n... and {len(attendance_records) - 50} more attendance records\n"
    
    # Add user data if provided
    if users:
        context_summary += f"\n\nUSER ACCOUNTS ({len(users)} total):"
        context_summary += "\n"
        for user in users[:50]:  # Limit to first 50
            context_summary += f"\n- User ID: {user.get('userId')}"
            context_summary += f"\n  Email: {user.get('email')}"
            context_summary += f"\n  Name: {user.get('name')}"
            context_summary += f"\n  Role: {user.get('role')}"
            context_summary += f"\n  Department: {user.get('department', 'N/A')}"
            context_summary += f"\n  Employee ID: {user.get('employeeId', 'N/A')}"
            context_summary += "\n"
        
        if len(users) > 50:
            context_summary += f"\n... and {len(users) - 50} more user accounts\n"
    
    # Add conversation history if provided (Task 11.8)
    history_section = ""
    if conversation_history and len(conversation_history) > 0:
        history_section = "\n\n===================================================================\n"
        history_section += "CONVERSATION HISTORY (for context continuity)\n"
        history_section += "===================================================================\n"
        for msg in conversation_history:
            role_label = "User" if msg.get('role') == 'user' else "Assistant"
            history_section += f"\n{role_label}: {msg.get('content')}\n"
        history_section += "\nUse this conversation history to maintain context and provide relevant follow-up responses.\n"
    
    # Construct final prompt
    prompt = f"""{context_summary}{history_section}

===================================================================
RESPONSE GUIDELINES
===================================================================
1. Provide clear, professional responses
2. Use bullet points and formatting for readability
3. Include specific data from context when relevant
4. Stay focused on HR-related queries
5. Politely decline non-HR questions
6. If data is not in context, state "I don't have that information"
7. Use conversation history to maintain context continuity

===================================================================
USER QUESTION
===================================================================
{user_message}

===================================================================
YOUR RESPONSE
===================================================================
"""
    
    return prompt


def invoke_bedrock(prompt):
    """Invoke Bedrock model with the constructed prompt"""
    try:
        # Prepare request body for Claude 3 Haiku
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "top_p": 0.9
        }
        
        # Invoke Bedrock
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        # Extract text from Claude response
        if 'content' in response_body and len(response_body['content']) > 0:
            return response_body['content'][0]['text']
        else:
            return "I apologize, but I couldn't generate a response. Please try again."
    
    except Exception as e:
        logger.error(f"Error invoking Bedrock: {e}")
        return f"I encountered an error while processing your request. Please try again later."


def lambda_handler(event, context):
    """Main Lambda handler for chatbot"""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '').strip()
        frontend_context = body.get('context', {})  # Optional context from frontend
        conversation_history = body.get('history', [])  # Task 11.8: Conversation history for context continuity
        
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Message is required'
                })
            }
        
        # Detect prompt injection attempts
        if detect_prompt_injection(user_message):
            logger.warning(f"Prompt injection attempt detected from user message: {user_message[:100]}")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Invalid request detected. Please rephrase your question.'
                })
            }
        
        # Extract user email from JWT token (trusted source)
        request_context = event.get('requestContext', {})
        authorizer = request_context.get('authorizer', {})
        claims = authorizer.get('claims', {})
        user_email = claims.get('email')
        
        if not user_email:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Unauthorized: No user email found in token'
                })
            }
        
        # Get complete user information from database
        # Role is fetched from Users table, not JWT (as per system design)
        user_info = get_user_info(user_email)
        
        logger.info(f"User info: {user_info['name']}, role: {user_info['role']}, department: {user_info['department']}")
        
        # Build context from DynamoDB (backend fetched data)
        data_context = build_context(user_info)
        
        # Merge frontend context if provided (intelligent context provider)
        if frontend_context:
            logger.info(f"Using frontend-provided context with keys: {list(frontend_context.keys())}")
            # Frontend context takes precedence as it's more targeted
            # Extract data from API response format {success: true, data: [...]}
            if 'employees' in frontend_context:
                employees_data = frontend_context['employees']
                if isinstance(employees_data, dict) and 'data' in employees_data:
                    data_context['employees'] = employees_data['data']
                else:
                    data_context['employees'] = employees_data
            
            if 'performance_scores' in frontend_context or 'performanceScores' in frontend_context:
                perf_data = frontend_context.get('performanceScores') or frontend_context.get('performance_scores', [])
                if isinstance(perf_data, dict) and 'data' in perf_data:
                    data_context['performance_scores'] = perf_data['data']
                else:
                    data_context['performance_scores'] = perf_data
            
            if 'attendance' in frontend_context:
                attendance_data = frontend_context['attendance']
                if isinstance(attendance_data, dict) and 'data' in attendance_data:
                    data_context['attendance'] = attendance_data['data']
                else:
                    data_context['attendance'] = attendance_data
            
            if 'users' in frontend_context:
                users_data = frontend_context['users']
                if isinstance(users_data, dict) and 'data' in users_data:
                    data_context['users'] = users_data['data']
                else:
                    data_context['users'] = users_data
        
        # Construct prompt for Bedrock with conversation history (Task 11.8)
        prompt = construct_prompt(user_message, data_context, conversation_history)
        
        # Invoke Bedrock
        assistant_response = invoke_bedrock(prompt)
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'success': True,
                'data': {
                    'reply': assistant_response,
                    'timestamp': datetime.utcnow().isoformat()
                }
            })
        }
    
    except Exception as e:
        logger.error(f"Error in lambda_handler: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error'
            })
        }
