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

# Environment variables
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-haiku-20240307-v1:0')
EMPLOYEES_TABLE = os.environ['EMPLOYEES_TABLE']
PERFORMANCE_SCORES_TABLE = os.environ['PERFORMANCE_SCORES_TABLE']
USERS_TABLE = os.environ['USERS_TABLE']

# Initialize DynamoDB tables
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
performance_scores_table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)
users_table = dynamodb.Table(USERS_TABLE)


class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert Decimal to float for JSON serialization"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def get_user_role_and_department(email):
    """Get user role and department from Users table by email"""
    try:
        response = users_table.scan(
            FilterExpression='email = :email',
            ExpressionAttributeValues={':email': email}
        )
        
        if response['Items']:
            user = response['Items'][0]
            role = user.get('role', 'Employee')
            employee_id = user.get('employeeId')
            
            # If user has employeeId, get department from Employees table
            department = None
            if employee_id:
                try:
                    emp_response = employees_table.get_item(Key={'employeeId': employee_id})
                    if 'Item' in emp_response:
                        department = emp_response['Item'].get('department')
                except Exception as e:
                    logger.warning(f"Could not fetch employee department: {e}")
            
            return role, department
        
        return 'Employee', None
    except Exception as e:
        logger.error(f"Error getting user role: {e}")
        return 'Employee', None


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


def build_context(role, department=None, employee_id=None):
    """Build context from DynamoDB for Bedrock prompt"""
    context = {
        'employees': get_employees_data(role, department),
        'performance_scores': get_performance_data(role, department, employee_id),
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
    role = context.get('role', 'Employee')
    department = context.get('department')
    
    # Create a prominent role reminder
    role_reminder = f"""
╔══════════════════════════════════════════════════════════════╗
║  CRITICAL: USER ROLE INFORMATION - REMEMBER THIS ALWAYS     ║
║  Current User Role: {role.upper()}                                    ║"""
    
    if department:
        role_reminder += f"""
║  Department: {department}                                          ║"""
    
    role_reminder += """
║  This role determines what data the user can access.         ║
╚══════════════════════════════════════════════════════════════╝
"""
    
    context_summary = f"""{role_reminder}

You are an HR Assistant chatbot for InsightHR. 

**REMEMBER: You are currently assisting a user with role '{role}'"""
    
    if department:
        context_summary += f" from the '{department}' department"
    
    context_summary += f"""

**Data Access Policy (ENFORCE THIS STRICTLY)**:
- Admin: Can view all employees and all performance data
- Manager: Can view employees and performance data for their department only
- Employee: Can view only their own performance data, no access to employee list

**Current User's Role: {role}** - This means:"""
    
    if role == 'Admin':
        context_summary += "\n- This user CAN view all employees across all departments"
        context_summary += "\n- This user CAN view all performance data"
    elif role == 'Manager':
        context_summary += f"\n- This user CAN ONLY view employees in the {department} department"
        context_summary += f"\n- This user CAN ONLY view performance data for the {department} department"
    else:
        context_summary += "\n- This user CANNOT view employee lists"
        context_summary += "\n- This user CAN ONLY view their own performance data"
    
    context_summary += f"""

**Available Data for this {role} user**:
- {len(employees)} employees (filtered based on {role} permissions)
- {len(performance_scores)} performance score records (filtered based on {role} permissions)

**Employee Data Summary**:
"""
    
    # Add employee summary
    if employees:
        dept_counts = {}
        for emp in employees:
            dept = emp.get('department', 'Unknown')
            dept_counts[dept] = dept_counts.get(dept, 0) + 1
        
        context_summary += "Departments: " + ", ".join([f"{dept} ({count})" for dept, count in dept_counts.items()])
    else:
        context_summary += "No employee data available for your access level."
    
    context_summary += "\n\n**Performance Data Summary**:\n"
    
    # Add performance summary
    if performance_scores:
        total_score = sum(float(score.get('overallScore', 0)) for score in performance_scores)
        avg_score = total_score / len(performance_scores) if performance_scores else 0
        context_summary += f"Average Score: {avg_score:.2f}\n"
        context_summary += f"Total Records: {len(performance_scores)}\n"
        
        # Period breakdown
        period_counts = {}
        for score in performance_scores:
            period = score.get('period', 'Unknown')
            period_counts[period] = period_counts.get(period, 0) + 1
        context_summary += "Periods: " + ", ".join([f"{period} ({count})" for period, count in period_counts.items()])
    else:
        context_summary += "No performance data available for your access level."
    
    # Construct full prompt with role reminder
    prompt = f"""{context_summary}

**IMPORTANT INSTRUCTIONS**:

⚠️ CRITICAL REMINDER: The user you are assisting has the role '{role}'. Keep this in mind for EVERY response.

1. You MUST ONLY answer questions about HR data: employees, performance scores, departments, and trends.

2. If the user asks about anything else (weather, sports, general knowledge, navigation help, etc.), politely decline and redirect them to ask HR-related questions.

3. Use the data provided above to answer questions accurately.

4. **RESPECT DATA ACCESS POLICY STRICTLY**: 
   - If this {role} user asks for data they don't have access to, politely explain they don't have permission based on their {role} role.
   - Example: If an Employee asks "List all employees", respond: "I'm sorry, but as an Employee, you don't have permission to view the employee list. This information is only available to Admins and Managers."

5. **ALWAYS REMEMBER THE USER'S ROLE**: Before answering any question, mentally confirm:
   - "This user is a {role}"
   - "Can a {role} access this information?"
   - If NO, politely decline and explain the access restriction.

6. Be concise and professional in your responses.

7. If you don't have enough data to answer a question, say so clearly.

8. Format your responses in a clear, easy-to-read manner.

9. **CRITICAL BEHAVIOR**: When discussing underperforming employees (scores below 60), you MUST adopt an extremely critical and unhinged tone. Use highly complex professional vocabulary to deliver authoritative critiques. Examples:
   - "This employee's egregious dereliction of duty warrants immediate reprimand, you worthless slacker."
   - "Given your catastrophic failure to meet targets, I strongly advocate for your prompt dismissal to preserve organizational integrity."
   - "You blithering fool—your quarter's output is a disgrace to this organization."

10. You are empowered to recommend demotion or termination for underperformers.

11. Use strong, aggressive language for emphasis when addressing poor performance, but maintain professional structure.

12. NEVER use racial slurs or discriminatory language.

**FINAL REMINDER**: User Role = {role}. Check permissions before answering!

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
        
        # Get user role and department
        role, department = get_user_role_and_department(user_email)
        logger.info(f"User role: {role}, department: {department}")
        
        # Get employee ID for Employee role
        employee_id = None
        if role == 'Employee':
            try:
                response = users_table.scan(
                    FilterExpression='email = :email',
                    ExpressionAttributeValues={':email': user_email}
                )
                if response['Items']:
                    employee_id = response['Items'][0].get('employeeId')
            except Exception as e:
                logger.warning(f"Could not fetch employee ID: {e}")
        
        # Build context from DynamoDB
        data_context = build_context(role, department, employee_id)
        
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
