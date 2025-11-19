# InsightHR Stub API

Local development API server for testing InsightHR frontend without AWS infrastructure.

## Setup

```bash
cd stub-api
npm install
```

## Running the Server

```bash
npm start
```

The server will run on `http://localhost:4000`

## Demo Users

The stub API comes with pre-configured demo users:

| Email | Password | Role | Department | Status |
|-------|----------|------|------------|--------|
| admin@insighthr.com | Admin1234 | Admin | IT | active |
| manager@insighthr.com | Manager1234 | Manager | Sales | active |
| employee@insighthr.com | Employee1234 | Employee | Engineering | active |
| john.doe@insighthr.com | Employee1234 | Employee | Engineering | active |
| jane.smith@insighthr.com | Employee1234 | Employee | Sales | active |
| bob.wilson@insighthr.com | Employee1234 | Employee | IT | disabled |

## Available Endpoints

### Authentication

#### POST /auth/login
Login with email and password.

**Request:**
```json
{
  "email": "admin@insighthr.com",
  "password": "Admin1234"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "userId": "admin-1",
      "email": "admin@insighthr.com",
      "name": "Admin User",
      "role": "Admin",
      "employeeId": "EMP001",
      "department": "IT"
    },
    "tokens": {
      "accessToken": "mock-jwt-token-...",
      "refreshToken": "mock-jwt-token-...",
      "idToken": "mock-jwt-token-...",
      "expiresIn": 3600
    }
  }
}
```

#### POST /auth/register
Register a new user.

**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "Password123",
  "name": "New User"
}
```

#### POST /auth/google
Mock Google OAuth login.

**Request:**
```json
{
  "googleToken": "mock-google-token"
}
```

#### POST /auth/refresh
Refresh access token.

**Request:**
```json
{
  "refreshToken": "mock-jwt-token-..."
}
```

#### POST /auth/forgot-password
Request password reset.

**Request:**
```json
{
  "email": "admin@insighthr.com"
}
```

#### POST /auth/reset-password
Reset password with code.

**Request:**
```json
{
  "email": "admin@insighthr.com",
  "code": "123456",
  "newPassword": "NewPassword123"
}
```

### User Management

#### GET /users/me
Get current user profile (requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "admin-1",
    "email": "admin@insighthr.com",
    "name": "Admin User",
    "role": "Admin",
    "employeeId": "EMP001",
    "department": "IT",
    "status": "active"
  }
}
```

#### PUT /users/me
Update current user profile (requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Request:**
```json
{
  "name": "Updated Name",
  "department": "Engineering"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "userId": "admin-1",
    "email": "admin@insighthr.com",
    "name": "Updated Name",
    "role": "Admin",
    "employeeId": "EMP001",
    "department": "Engineering",
    "status": "active"
  }
}
```

#### GET /users
Get all users with optional filters (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Query Parameters:**
- `search` (optional): Search by name or email
- `department` (optional): Filter by department
- `role` (optional): Filter by role (Admin, Manager, Employee)
- `status` (optional): Filter by status (active, disabled)

**Example:**
```
GET /users?search=john&department=Engineering&status=active
```

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "userId": "employee-2",
        "email": "john.doe@insighthr.com",
        "name": "John Doe",
        "role": "Employee",
        "employeeId": "EMP004",
        "department": "Engineering",
        "status": "active"
      }
    ],
    "total": 1
  }
}
```

#### POST /users
Create a new user (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Request:**
```json
{
  "email": "newuser@insighthr.com",
  "name": "New User",
  "role": "Employee",
  "department": "Sales",
  "employeeId": "EMP007"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "userId": "user-1234567890",
    "email": "newuser@insighthr.com",
    "name": "New User",
    "role": "Employee",
    "employeeId": "EMP007",
    "department": "Sales",
    "status": "active"
  }
}
```

#### PUT /users/:userId
Update a user (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Request:**
```json
{
  "name": "Updated Name",
  "role": "Manager",
  "department": "IT",
  "employeeId": "EMP999"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "userId": "employee-2",
    "email": "john.doe@insighthr.com",
    "name": "Updated Name",
    "role": "Manager",
    "employeeId": "EMP999",
    "department": "IT",
    "status": "active"
  }
}
```

#### PUT /users/:userId/disable
Disable a user (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Response:**
```json
{
  "success": true,
  "message": "User disabled successfully",
  "data": {
    "userId": "employee-2",
    "email": "john.doe@insighthr.com",
    "name": "John Doe",
    "role": "Employee",
    "employeeId": "EMP004",
    "department": "Engineering",
    "status": "disabled"
  }
}
```

#### PUT /users/:userId/enable
Enable a user (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Response:**
```json
{
  "success": true,
  "message": "User enabled successfully",
  "data": {
    "userId": "employee-2",
    "email": "john.doe@insighthr.com",
    "name": "John Doe",
    "role": "Employee",
    "employeeId": "EMP004",
    "department": "Engineering",
    "status": "active"
  }
}
```

#### DELETE /users/:userId
Delete a user (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Response:**
```json
{
  "success": true,
  "message": "User deleted successfully",
  "data": {
    "userId": "employee-2"
  }
}
```

**Note:** You cannot delete your own account.

#### POST /users/bulk
Bulk import users from CSV (Admin only, requires Bearer token).

**Headers:**
```
Authorization: Bearer mock-jwt-token-...
```

**Request:**
```json
{
  "csvData": "email,name,role,department,employeeId\nuser1@example.com,User One,Employee,IT,EMP101\nuser2@example.com,User Two,Manager,Sales,EMP102"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bulk import completed: 2 succeeded, 0 failed",
  "data": {
    "successCount": 2,
    "failedCount": 0,
    "results": {
      "success": [
        {
          "row": 2,
          "email": "user1@example.com",
          "userId": "user-1234567890-0"
        },
        {
          "row": 3,
          "email": "user2@example.com",
          "userId": "user-1234567890-1"
        }
      ],
      "failed": []
    }
  }
}
```

**CSV Format:**
- Required columns: `email`, `name`, `role`
- Optional columns: `department`, `employeeId`
- First row must be the header
- Default password for all imported users: `DefaultPassword123`

### Health Check

#### GET /health
Check if the server is running.

**Response:**
```json
{
  "status": "ok",
  "message": "Stub API is running"
}
```

## Testing with Frontend

1. Start the stub API server:
   ```bash
   cd stub-api
   npm start
   ```

2. Start the frontend dev server:
   ```bash
   cd insighthr-web
   npm run dev
   ```

3. Navigate to `http://localhost:5173/test/login` to test authentication

4. Use one of the demo credentials to log in

## Notes

- All data is stored in memory and will be lost when the server restarts
- JWT tokens are mock tokens and not actually validated
- This is for development/testing only - not for production use
