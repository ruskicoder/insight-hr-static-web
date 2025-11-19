# User Management Lambda Functions

This directory contains AWS Lambda functions for user management operations in the InsightHR system.

## Lambda Functions

### 1. users-handler (users_handler.py)

Main Lambda function that handles all user management operations.

**Endpoints:**

- `GET /users/me` - Get current user profile
  - Authentication: Required (JWT token)
  - Authorization: Any authenticated user
  - Returns: Current user's profile data

- `PUT /users/me` - Update current user profile
  - Authentication: Required (JWT token)
  - Authorization: Any authenticated user
  - Body: `{ name, department, avatarUrl }`
  - Returns: Updated user profile
  - Note: Users can only update their own name, department, and avatar

- `GET /users` - List all users with filters
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Query Parameters: `search`, `department`, `role`, `status`
  - Returns: Array of users matching filters

- `POST /users` - Create new user
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Body: `{ email, name, role, department, employeeId }`
  - Returns: Created user and temporary password
  - Note: Creates user in both Cognito and DynamoDB

- `PUT /users/:userId` - Update user
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Body: `{ name, role, department, employeeId }`
  - Returns: Updated user profile

- `PUT /users/:userId/disable` - Disable user account
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Returns: Updated user with isActive=false
  - Note: Disables user in both Cognito and DynamoDB

- `PUT /users/:userId/enable` - Enable user account
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Returns: Updated user with isActive=true
  - Note: Enables user in both Cognito and DynamoDB

- `DELETE /users/:userId` - Delete user
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Returns: Success message
  - Note: Deletes user from both Cognito and DynamoDB

### 2. users-bulk-handler (users_bulk_handler.py)

Lambda function for bulk user creation from CSV data.

**Endpoint:**

- `POST /users/bulk` - Bulk create users from CSV
  - Authentication: Required (JWT token)
  - Authorization: Admin only
  - Body: `{ csvData: "email,name,role,department,employeeId\n..." }`
  - Returns: Summary of created users with success/failure for each
  - CSV Format:
    ```csv
    email,name,role,department,employeeId
    john@example.com,John Doe,Employee,Engineering,EMP001
    jane@example.com,Jane Smith,Manager,Sales,EMP002
    ```

## Features

### Role-Based Authorization

- Extracts user role from JWT token
- Validates Admin role for administrative operations
- Returns 403 Forbidden for unauthorized access

### Error Handling

- Comprehensive error handling for Cognito operations
- Rollback mechanism for failed DynamoDB operations
- Consistent error response format
- Detailed error logging to CloudWatch

### CORS Support

- All endpoints return CORS headers
- Supports cross-origin requests from frontend

### Data Consistency

- Creates/updates users in both Cognito and DynamoDB
- Rollback on failure to maintain consistency
- Soft delete for user accounts (isActive flag)

## Environment Variables

Required environment variables for Lambda functions:

- `USER_POOL_ID` - Cognito User Pool ID
- `CLIENT_ID` - Cognito App Client ID
- `CLIENT_SECRET` - Cognito App Client Secret
- `DYNAMODB_USERS_TABLE` - DynamoDB Users table name
- `AWS_REGION` - AWS region (default: ap-southeast-1)

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Python 3.11 installed
3. pip installed
4. Lambda execution role created with permissions:
   - AWSLambdaBasicExecutionRole
   - DynamoDB read/write access
   - Cognito admin access

### Deploy Lambda Functions

```powershell
# Deploy both Lambda functions
.\deploy-lambdas.ps1
```

### Setup API Gateway Endpoints

```powershell
# Create API Gateway endpoints with CORS
.\setup-api-gateway.ps1
```

## Testing

Test endpoints using PowerShell:

```powershell
# Login and get token
$API_BASE_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"
$loginBody = @{email="admin@insighthr.com";password="Admin123!"} | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "$API_BASE_URL/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$TOKEN = $loginResponse.data.tokens.idToken

# Test GET /users/me
Invoke-RestMethod -Uri "$API_BASE_URL/users/me" -Method Get -Headers @{Authorization="Bearer $TOKEN"}

# Test GET /users
Invoke-RestMethod -Uri "$API_BASE_URL/users" -Method Get -Headers @{Authorization="Bearer $TOKEN"}
```

## Dependencies

- `boto3` - AWS SDK for Python
- `botocore` - Low-level AWS service access
- `PyJWT` - JWT token decoding

## Security Considerations

1. **JWT Validation**: Token signature verification is handled by API Gateway Cognito Authorizer
2. **Role-Based Access**: Admin-only operations are protected by role checks
3. **Temporary Passwords**: Generated passwords follow security requirements
4. **Email Suppression**: User creation emails are suppressed (admin notifies users manually)
5. **Soft Delete**: Users are disabled rather than deleted to maintain audit trail

## Error Codes

- `400` - Bad Request (missing/invalid parameters)
- `401` - Unauthorized (missing/invalid JWT token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (user not found)
- `409` - Conflict (user already exists)
- `500` - Internal Server Error

## Response Format

### Success Response

```json
{
  "success": true,
  "data": {
    "user": { ... },
    "temporaryPassword": "TempPass20241118!"
  }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description"
}
```

## Notes

- All timestamps are in ISO 8601 format (UTC)
- User IDs are Cognito sub (UUID)
- Email is used as Cognito username
- Default role for self-registered users is "Employee"
- Admin-created users receive temporary passwords
