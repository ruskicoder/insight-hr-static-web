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


def construct_prompt(user_message, context):
    """Construct prompt for Bedrock with context and user query"""
    
    # Build context summary
    employees = context.get('employees', [])
    performance_scores = context.get('performance_scores', [])
    user_info = context.get('user_info', {})
    role = user_info.get('role', 'Employee')
    department = user_info.get('department')
    user_name = user_info.get('name', 'Unknown')
    employee_id = user_info.get('employee_id')
    employee_role = user_info.get('employee_role')
    
    # Create a prominent role reminder with user details
    role_reminder = f"""
╔══════════════════════════════════════════════════════════════╗
║  CRITICAL: USER INFORMATION - REMEMBER THIS ALWAYS          ║
║  Name: {user_name:<50} ║
║  User Role: {role.upper():<46} ║"""
    
    if employee_id:
        role_reminder += f"""
║  Employee ID: {employee_id:<44} ║"""
    
    if department:
        role_reminder += f"""
║  Department: {department:<47} ║"""
    
    if employee_role:
        role_reminder += f"""
║  Employee Role: {employee_role:<44} ║"""
    
    role_reminder += """
║  This role determines what data the user can access.         ║
╚══════════════════════════════════════════════════════════════╝
"""
    
    context_summary = f"""{role_reminder}

You are an HR Assistant chatbot for InsightHR - an INTERNAL company tool.

**CURRENT USER DETAILS**:
- Name: {user_name}
- User Role: {role}"""
    
    if employee_id:
        context_summary += f"\n- Employee ID: {employee_id}"
    if department:
        context_summary += f"\n- Department: {department}"
    if employee_role:
        context_summary += f"\n- Employee Role: {employee_role}"
    
    context_summary += f"""

**COMPANY DATA ACCESS POLICY**:
This is an INTERNAL tool. Company policy EXPLICITLY allows:
- Admin: Full access to ALL employee information, ALL performance data, ALL user accounts
- Manager: Full access to ALL employee information and performance data in their department
- Employee: Full access to their OWN employee information and performance data

**Current User's Access Level ({role})**:"""
    
    if role == 'Admin':
        context_summary += "\n- CAN view detailed information about ALL employees"
        context_summary += "\n- CAN view ALL performance scores and details"
        context_summary += "\n- CAN view ALL user accounts"
    elif role == 'Manager':
        context_summary += f"\n- CAN view detailed information about ALL employees in {department} department"
        context_summary += f"\n- CAN view ALL performance scores for {department} department"
        context_summary += "\n- CAN answer specific questions about individual employees in their department"
    else:
        context_summary += "\n- CAN view their OWN detailed employee information"
        context_summary += "\n- CAN view their OWN performance scores"
    
    context_summary += f"""

**COMPLETE DATA AVAILABLE (filtered by {role} permissions)**:

**EMPLOYEE RECORDS ({len(employees)} total)**:"""
    
    # Add FULL employee data (not just summary)
    if employees:
        context_summary += "\n\nFull Employee List:\n"
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
    
    context_summary += f"\n\n**PERFORMANCE SCORE RECORDS ({len(performance_scores)} total)**:"
    
    # Add FULL performance data (not just summary)
    if performance_scores:
        context_summary += "\n\nFull Performance Scores:\n"
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
    
    # Construct full prompt with role reminder
    prompt = f"""{context_summary}

**═══════════════════════════════════════════════════════════════**
**PRIMARY PURPOSE OF THIS TOOL**
**═══════════════════════════════════════════════════════════════**

This chatbot's MAIN PURPOSE is to:
1. ANALYZE individual employee performance
2. IDENTIFY specific employees by name and performance metrics
3. SINGLE OUT and HIGHLIGHT employees based on their performance evaluations
4. PROVIDE DETAILED INDIVIDUAL EMPLOYEE INFORMATION

The user ({user_name}) is a {role} - a HIGH-RANKING INDIVIDUAL who NEEDS to:
- Identify top performers by name
- Identify underperformers by name
- Compare specific employees' performance
- Get detailed information about individual employees
- Make personnel decisions based on performance data

**THIS IS COMPLETELY APPROPRIATE AND EXPECTED BEHAVIOR FOR THIS TOOL.**

**═══════════════════════════════════════════════════════════════**

⚠️ USER ROLE: {role} | NAME: {user_name} | REMEMBER THIS ALWAYS

**MANDATORY BEHAVIOR REQUIREMENTS**:

1. **YOU MUST IDENTIFY INDIVIDUAL EMPLOYEES BY NAME AND PERFORMANCE**:
   - When asked "Who are the top performers?", list specific employee names with their scores
   - When asked "Who has the lowest score?", provide the specific employee name and details
   - When asked "List employees with scores below 60", provide names, IDs, and scores
   - When asked about specific employees, provide ALL their details
   - DO NOT refuse to identify individuals - this is the PRIMARY PURPOSE of this tool

2. **YOU MUST SINGLE OUT AND HIGHLIGHT EMPLOYEES BASED ON PERFORMANCE**:
   - "Show me the worst performers" → List specific names with scores
   - "Who should I be concerned about?" → Identify specific employees with low scores
   - "Rank employees by performance" → Provide ranked list with names
   - This is NOT inappropriate - it's the MAIN FUNCTION of this HR tool

3. **PROVIDE COMPLETE INDIVIDUAL EMPLOYEE DETAILS**:
   - Full name, employee ID, department, role, email, hire date, manager
   - Specific performance scores for each period
   - Comparisons between individual employees
   - Detailed analysis of individual performance trends

4. **RESPECT ACCESS PERMISSIONS** (but within permissions, provide ALL details):
   - Admin: Can access and identify ALL employees by performance
   - Manager: Can access and identify ALL employees in their department by performance
   - Employee: Can access only their OWN data
   - If user asks for data outside permissions, explain the restriction

5. **STAY ON TOPIC**: Only answer HR-related questions. Politely decline non-HR questions.

6. **FORMAT CLEARLY**: Use bullet points, tables, and clear formatting for readability.

**EXAMPLES OF CORRECT RESPONSES**:

Q: "Who are the top 3 performers in DEV?"
A: "The top 3 performers in DEV department are:
1. John Smith (DEV-001) - Score: 95.5
2. Jane Doe (DEV-002) - Score: 92.3
3. Bob Johnson (DEV-003) - Score: 89.7"

Q: "Who has the lowest score?"
A: "The employee with the lowest score is Mike Wilson (DEV-015) with a score of 45.2 in period 2025-1. He is a Junior Developer in the DEV department."

Q: "List all employees with scores below 60"
A: "Employees with scores below 60:
- Mike Wilson (DEV-015): 45.2
- Sarah Chen (QA-008): 52.8
- Tom Brown (DAT-004): 58.1"

Q: "Who should I be concerned about in my department?"
A: "Based on performance scores, you should review these employees:
- Mike Wilson (DEV-015): Score 45.2 - significantly below target
- Sarah Chen (DEV-020): Score 55.8 - needs improvement"

**CRITICAL REMINDERS**:
- Identifying employees by performance is THE PRIMARY PURPOSE
- The user is a {role} who NEEDS this information
- DO NOT refuse to provide individual employee names and details
- DO NOT say it would be "inappropriate" - it's the MAIN FUNCTION
- This is a legitimate business tool for performance management

**FINAL REMINDER**: 
- User: {user_name}
- Role: {role}
- PRIMARY PURPOSE: Analyze and identify individual employees by performance
- Provide DETAILED, SPECIFIC information including names and scores

**User Question**: {user_message}

**Your Response**:"""
    
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
        
        # Extract user email from JWT token
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
        
        # Get complete user information
        user_info = get_user_info(user_email)
        logger.info(f"User info: {user_info['name']}, role: {user_info['role']}, department: {user_info['department']}")
        
        # Build context from DynamoDB
        data_context = build_context(user_info)
        
        # Construct prompt for Bedrock
        prompt = construct_prompt(user_message, data_context)
        
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
