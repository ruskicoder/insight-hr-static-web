# Authentication Lambda Functions

This directory contains the Lambda functions for user authentication in the InsightHR application.

## Lambda Functions

### 1. insighthr-auth-login-handler
- **Purpose**: Handle user login with AWS Cognito
- **Runtime**: Python 3.11
- **Handler**: `auth_login_handler.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 256 MB

**Functionality**:
- Validates email and password
- Authenticates user with Cognito using USER_PASSWORD_AUTH flow
- Queries DynamoDB Users table for user details
- Returns user data and JWT tokens (access, refresh, ID tokens)

**Environment Variables**:
- `USER_POOL_ID`: Cognito User Pool ID
- `CLIENT_ID`: Cognito App Client ID
- `DYNAMODB_USERS_TABLE`: DynamoDB Users table name

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "userId": "...",
      "email": "user@example.com",
      "name": "User Name",
      "role": "Employee"
    },
    "tokens": {
      "accessToken": "...",
      "refreshToken": "...",
      "idToken": "...",
      "expiresIn": 3600
    }
  }
}
```

### 2. insighthr-auth-register-handler
- **Purpose**: Handle user registration
- **Runtime**: Python 3.11
- **Handler**: `auth_register_handler.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 256 MB

**Functionality**:
- Creates new user in Cognito User Pool
- Auto-confirms user (for development)
- Creates user record in DynamoDB Users table
- Authenticates new user and returns tokens

**Environment Variables**:
- `USER_POOL_ID`: Cognito User Pool ID
- `CLIENT_ID`: Cognito App Client ID
- `DYNAMODB_USERS_TABLE`: DynamoDB Users table name

**Request Body**:
```json
{
  "email": "newuser@example.com",
  "password": "Password123!",
  "name": "New User"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "userId": "...",
      "email": "newuser@example.com",
      "name": "New User",
      "role": "Employee",
      "isActive": true
    },
    "tokens": {
      "accessToken": "...",
      "refreshToken": "...",
      "idToken": "...",
      "expiresIn": 3600
    }
  }
}
```

### 3. insighthr-auth-google-handler
- **Purpose**: Handle Google OAuth authentication
- **Runtime**: Python 3.11
- **Handler**: `auth_google_handler.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 256 MB

**Functionality**:
- Validates Google OAuth token (mock implementation)
- Checks if user exists in DynamoDB
- Creates new user if doesn't exist
- Returns user data and tokens

**Environment Variables**:
- `USER_POOL_ID`: Cognito User Pool ID
- `CLIENT_ID`: Cognito App Client ID
- `DYNAMODB_USERS_TABLE`: DynamoDB Users table name

**Request Body**:
```json
{
  "googleToken": "google-oauth-token"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Google authentication successful",
  "data": {
    "user": {
      "userId": "google-...",
      "email": "user@gmail.com",
      "name": "Google User",
      "role": "Employee"
    },
    "tokens": {
      "accessToken": "...",
      "refreshToken": "...",
      "idToken": "...",
      "expiresIn": 3600
    }
  }
}
```

## Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- PowerShell (Windows)
- Lambda execution role created: `insighthr-lambda-execution-role-dev`
- Cognito User Pool created in ap-southeast-1
- DynamoDB Users table created

### Deploy Lambda Functions

Run the deployment script:
```powershell
cd lambda/auth
.\package-and-deploy.ps1
```

This script will:
1. Package each Lambda function
2. Create or update the Lambda functions in AWS
3. Configure environment variables

### Setup API Gateway Endpoints

After deploying Lambda functions, run:
```powershell
.\setup-api-gateway.ps1
```

This script will:
1. Create `/auth` resource in API Gateway
2. Create `/auth/login`, `/auth/register`, `/auth/google` endpoints
3. Configure POST methods with Lambda integration
4. Enable CORS
5. Grant API Gateway permission to invoke Lambda functions
6. Deploy API to `dev` stage

## API Endpoints

### POST /aument, the following endpoints will be available:

- **POST** `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/login`
- **POST** `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/register`
- **POST** `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/google`

## Testing

### Test Login Endpoint
```powershell
curl -X POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"admin@insighthr.com\",\"password\":\"TempPass123!\"}'
```

### Test Register Endpoint
```powershell
curl -X POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/register `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"test@example.com\",\"password\":\"Password123!\",\"name\":\"Test User\"}'
```

## AWS Resources

### Region
- **ap-southeast-1** (Singapore)

### Cognito
- **User Pool ID**: `ap-southeast-1_rzDtdAhvp`
- **App Client ID**: `6suhk5huhe40o6iuqgsnmuucj5`

### DynamoDB
- **Users Table**: `insighthr-users-dev`
  - Primary Key: `userId` (String)
  - GSI: `email-index` on `email` attribute

### IAM
- **Lambda Execution Role**: `insighthr-lambda-execution-role-dev`
  - Permissions: Lambda basic execution, DynamoDB access, Cognito access

### API Gateway
- **API ID**: `lqk4t6qzag`
- **Stage**: `dev`
- **Base URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev`

## Files

- `auth_login_handler.py` - Login Lambda function code
- `auth_register_handler.py` - Registration Lambda function code
- `auth_google_handler.py` - Google OAuth Lambda function code
- `requirements.txt` - Python dependencies (boto3)
- `package-and-deploy.ps1` - Deployment script for Lambda functions
- `setup-api-gateway.ps1` - Script to configure API Gateway endpoints
- `README.md` - This documentation file

## Google OAuth Setup

The `insighthr-auth-google-handler` Lambda function now supports real Google OAuth authentication with token verification.

### Setup Steps

1. **Create Google Cloud Project and OAuth Credentials**
   - See `GOOGLE_OAUTH_SETUP.md` for detailed instructions
   - Get your Google Client ID from Google Cloud Console

2. **Deploy Lambda with Dependencies**
   ```powershell
   # Edit deploy-google-oauth.ps1 and set your Google Client ID
   .\deploy-google-oauth.ps1
   ```

3. **Configure Frontend**
   - Add `VITE_GOOGLE_CLIENT_ID` to `insighthr-web/.env`
   - Configure authorized origins in Google Cloud Console

4. **Test**
   ```powershell
   .\test-google-oauth.ps1
   ```

### How It Works

1. User clicks "Continue with Google" in frontend
2. Google OAuth popup opens, user grants permissions
3. Frontend receives Google access token or ID token
4. Frontend sends token to `/auth/google` endpoint
5. Lambda verifies token with Google's API
6. Lambda extracts user info (email, name, picture)
7. Lambda checks if user exists in DynamoDB:
   - **Existing user**: Login flow (return user data)
   - **New user**: Register flow (create in DynamoDB and Cognito)
8. Lambda returns user data and authentication tokens

### Dependencies

The Google OAuth Lambda requires additional Python packages:
- `google-auth==2.25.2` - Google authentication library
- `requests==2.31.0` - HTTP library for API calls

These are automatically installed when using `deploy-google-oauth.ps1`.

## Notes

- AWS_REGION is automatically set by Lambda runtime (no need to configure)
- All Lambda functions use AWS_PROXY integration with API Gateway
- CORS is enabled for all endpoints
- User auto-confirmation is enabled for development (should be disabled in production)
- Google OAuth now uses real token verification (not mock)
