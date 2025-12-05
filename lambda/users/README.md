# Users Lambda Functions

User management Lambda functions for InsightHR platform.

## Overview

Handles user CRUD operations, bulk imports, and user-employee linking.

## Functions

### users_handler.py
Main user management handler with role-based access control.

**Endpoints:**
- `GET /users` - List all users (Admin only)
- `GET /users/{userId}` - Get user by ID
- `POST /users` - Create new user
- `PUT /users/{userId}` - Update user
- `DELETE /users/{userId}` - Delete user (Admin only)
- `POST /users/{userId}/enable` - Enable user account
- `POST /users/{userId}/disable` - Disable user account

### users_bulk_handler.py
Bulk user operations handler.

**Endpoints:**
- `POST /users/bulk` - Bulk create users from CSV
- `POST /users/bulk/template` - Download CSV template

## Deployment

```powershell
# Deploy Lambda function
.\deploy-users-handler.ps1

# Setup API Gateway endpoints
.\setup-api-gateway.ps1
```

## Environment Variables

- `USERS_TABLE` - DynamoDB table name (insighthr-users-dev)
- `REGION` - AWS region (ap-southeast-1)

## IAM Permissions Required

- `dynamodb:GetItem`
- `dynamodb:PutItem`
- `dynamodb:UpdateItem`
- `dynamodb:DeleteItem`
- `dynamodb:Scan`
- `dynamodb:Query`

## API Gateway Integration

- **API ID**: lqk4t6qzag
- **Stage**: prod
- **Base URL**: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/prod
- **Authorization**: Cognito User Pool (ap-southeast-1_rzDtdAhvp)

## Role-Based Access

- **Admin**: Full access to all user operations
- **Manager**: Read access to department users
- **Employee**: Read access to own user data only

## Testing

```powershell
# Test user endpoints
.\test-user-endpoints.ps1

# Check user role
.\check-user-role.ps1
```

## Related

- Frontend: `insighthr-web/src/services/userService.ts`
- Store: `insighthr-web/src/store/userStore.ts`
- Components: `insighthr-web/src/components/admin/UserManagement.tsx`
