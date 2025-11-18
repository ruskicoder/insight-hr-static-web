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

| Email | Password | Role |
|-------|----------|------|
| admin@insighthr.com | Admin1234 | Admin |
| manager@insighthr.com | Manager1234 | Manager |
| employee@insighthr.com | Employee1234 | Employee |

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
    "department": "IT"
  }
}
```

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
