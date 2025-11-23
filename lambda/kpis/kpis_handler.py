import json
import boto3
import os
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_KPIS_TABLE', 'insighthr-kpis-dev')
table = dynamodb.Table(table_name)

def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def get_user_from_token(event):
    """Extract user info from JWT token in authorizer context"""
    try:
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        claims = authorizer.get('claims', {})
        
        user_id = claims.get('sub') or claims.get('cognito:username')
        email = claims.get('email', '')
        role = claims.get('custom:role', 'Employee')
        
        return {
            'userId': user_id,
            'email': email,
            'role': role
        }
    except Exception as e:
        print(f"Error extracting user from token: {str(e)}")
        return None

def check_admin_role(user):
    """Check if user has Admin role"""
    if not user or user.get('role') != 'Admin':
        return False
    return True

def lambda_handler(event, context):
    """
    Main Lambda handler for KPI management
    Supports: GET (list/get), POST (create), PUT (update), DELETE (soft delete)
    """
    print(f"Event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_parameters = event.get('pathParameters') or {}
    query_parameters = event.get('queryStringParameters') or {}
    
    # Extract user from JWT token
    user = get_user_from_token(event)
    if not user:
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            'body': json.dumps({'message': 'Unauthorized - Invalid token'})
        }
    
    try:
        # GET /kpis - List all KPIs
        if http_method == 'GET' and not path_parameters.get('kpiId'):
            return list_kpis(query_parameters)
        
        # GET /kpis/{kpiId} - Get single KPI
        elif http_method == 'GET' and path_parameters.get('kpiId'):
            kpi_id = path_parameters['kpiId']
            return get_kpi(kpi_id)
        
        # POST /kpis - Create new KPI (Admin only)
        elif http_method == 'POST':
            if not check_admin_role(user):
                return {
                    'statusCode': 403,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'Forbidden - Admin role required'})
                }
            body = json.loads(event.get('body', '{}'))
            return create_kpi(body, user)
        
        # PUT /kpis/{kpiId} - Update KPI (Admin only)
        elif http_method == 'PUT' and path_parameters.get('kpiId'):
            if not check_admin_role(user):
                return {
                    'statusCode': 403,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'Forbidden - Admin role required'})
                }
            kpi_id = path_parameters['kpiId']
            body = json.loads(event.get('body', '{}'))
            return update_kpi(kpi_id, body, user)
        
        # DELETE /kpis/{kpiId} - Soft delete KPI (Admin only)
        elif http_method == 'DELETE' and path_parameters.get('kpiId'):
            if not check_admin_role(user):
                return {
                    'statusCode': 403,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'Forbidden - Admin role required'})
                }
            kpi_id = path_parameters['kpiId']
            return delete_kpi(kpi_id)
        
        else:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Invalid request'})
            }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Internal server error: {str(e)}'})
        }

def list_kpis(query_parameters):
    """List all KPIs with optional filters"""
    try:
        # Scan all KPIs (for MVP, no pagination)
        response = table.scan()
        kpis = response.get('Items', [])
        
        # Apply filters
        category = query_parameters.get('category')
        data_type = query_parameters.get('dataType')
        is_active = query_parameters.get('isActive')
        
        if category:
            kpis = [kpi for kpi in kpis if kpi.get('category') == category]
        
        if data_type:
            kpis = [kpi for kpi in kpis if kpi.get('dataType') == data_type]
        
        if is_active is not None:
            active_bool = is_active.lower() == 'true'
            kpis = [kpi for kpi in kpis if kpi.get('isActive') == active_bool]
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'kpis': kpis}, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error listing KPIs: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Failed to list KPIs: {str(e)}'})
        }

def get_kpi(kpi_id):
    """Get single KPI by ID"""
    try:
        response = table.get_item(Key={'kpiId': kpi_id})
        kpi = response.get('Item')
        
        if not kpi:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'KPI not found'})
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'kpi': kpi}, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error getting KPI: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Failed to get KPI: {str(e)}'})
        }

def create_kpi(body, user):
    """Create new KPI"""
    try:
        # Validate required fields
        required_fields = ['name', 'description', 'dataType']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': f'Missing required field: {field}'})
                }
        
        # Check if KPI name already exists
        response = table.scan(
            FilterExpression='#name = :name',
            ExpressionAttributeNames={'#name': 'name'},
            ExpressionAttributeValues={':name': body['name']}
        )
        if response.get('Items'):
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'KPI name already exists'})
            }
        
        # Create KPI
        kpi_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        kpi = {
            'kpiId': kpi_id,
            'name': body['name'],
            'description': body['description'],
            'dataType': body['dataType'],
            'category': body.get('category', ''),
            'isActive': True,
            'createdBy': user['userId'],
            'createdAt': now,
            'updatedAt': now
        }
        
        table.put_item(Item=kpi)
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'kpi': kpi}, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error creating KPI: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Failed to create KPI: {str(e)}'})
        }

def update_kpi(kpi_id, body, user):
    """Update existing KPI"""
    try:
        # Check if KPI exists
        response = table.get_item(Key={'kpiId': kpi_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'KPI not found'})
            }
        
        # Build update expression
        update_expr = 'SET updatedAt = :updatedAt'
        expr_attr_values = {':updatedAt': datetime.utcnow().isoformat()}
        expr_attr_names = {}
        
        if 'name' in body:
            update_expr += ', #name = :name'
            expr_attr_values[':name'] = body['name']
            expr_attr_names['#name'] = 'name'
        
        if 'description' in body:
            update_expr += ', description = :description'
            expr_attr_values[':description'] = body['description']
        
        if 'dataType' in body:
            update_expr += ', dataType = :dataType'
            expr_attr_values[':dataType'] = body['dataType']
        
        if 'category' in body:
            update_expr += ', category = :category'
            expr_attr_values[':category'] = body['category']
        
        if 'isActive' in body:
            update_expr += ', isActive = :isActive'
            expr_attr_values[':isActive'] = body['isActive']
        
        # Update KPI
        update_params = {
            'Key': {'kpiId': kpi_id},
            'UpdateExpression': update_expr,
            'ExpressionAttributeValues': expr_attr_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expr_attr_names:
            update_params['ExpressionAttributeNames'] = expr_attr_names
        
        response = table.update_item(**update_params)
        updated_kpi = response['Attributes']
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'kpi': updated_kpi}, default=decimal_default)
        }
    
    except Exception as e:
        print(f"Error updating KPI: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Failed to update KPI: {str(e)}'})
        }

def delete_kpi(kpi_id):
    """Soft delete KPI (set isActive to False)"""
    try:
        # Check if KPI exists
        response = table.get_item(Key={'kpiId': kpi_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'KPI not found'})
            }
        
        # Soft delete by setting isActive to False
        table.update_item(
            Key={'kpiId': kpi_id},
            UpdateExpression='SET isActive = :isActive, updatedAt = :updatedAt',
            ExpressionAttributeValues={
                ':isActive': False,
                ':updatedAt': datetime.utcnow().isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'KPI disabled successfully'})
        }
    
    except Exception as e:
        print(f"Error deleting KPI: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Failed to delete KPI: {str(e)}'})
        }
