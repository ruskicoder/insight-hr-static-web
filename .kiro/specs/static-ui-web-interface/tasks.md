# Implementation Plan

## Overview

This implementation plan breaks down the InsightHR Static Web Interface MVP into discrete, manageable coding tasks. Each task builds incrementally on previous work, with a focus on delivering core functionality within the 1-month timeline.

**Tech Stack:** React + TypeScript, Vite, Zustand, Axios, Recharts, Tailwind CSS, shadcn/ui, React Hook Form
**Backend:** Python Lambda + API Gateway + DynamoDB
**AWS Region:** ap-southeast-1 (Singapore)
**Timeline:** 4 weeks (20 working days)

**Development Strategy:**
- Set up AWS infrastructure as we go (check existing → create if missing)
- Build UI components alongside backend Lambda functions
- Apply Apple Blue theme from the start (inspired by Apple's design language)
- Use component library optimized for S3 deployment
- TypeScript in non-strict mode for rapid development
- Feature branches: `feat-[task-name]`
- Commit after task confirmation

**AWS Setup Approach:**
- Before each feature, scan for existing AWS resources
- If resources exist, verify configuration and use them
- If resources don't exist, create them with proper configuration
- All infrastructure in ap-southeast-1 (Singapore) region
- Update aws-secret.md with new resource details

**Build Order:** AWS Foundation → Login + Auth → Dashboard → Admin Features

---

## Task List

### Phase 0: AWS Infrastructure Foundation

- [x] 0.1 Verify and update AWS region configuration
  - Scan aws-secret.md for current region settings
  - Update all AWS resources to use ap-southeast-1 (Singapore)
  - Verify AWS CLI is configured with correct credentials
  - Test AWS CLI connectivity: `aws sts get-caller-identity --region ap-southeast-1`
  - Update aws-secret.md with AWS_REGION=ap-southeast-1
  - _Requirements: 9.1, 11.4_

- [x] 0.2 Set up DynamoDB tables in Singapore region
  - Check if DynamoDB tables exist in ap-southeast-1: `aws dynamodb list-tables --region ap-southeast-1`
  - If tables don't exist, create them with proper schema:
    - Users table (PK: userId, GSI: email-index)
    - KPIs table (PK: kpiId, GSI: category-index)
    - Formulas table (PK: formulaId, GSI: department-index)
    - PerformanceScores table (PK: employeeId, SK: period, GSI: department-period-index)
    - DataTables table (PK: tableId)
    - NotificationRules table (PK: ruleId)
    - NotificationHistory table (PK: notificationId, SK: sentAt)
  - If tables exist in us-east-1, migrate or recreate in ap-southeast-1
  - Update aws-secret.md with table names and ARNs
  - _Requirements: 3.5, 5.6, 6.1, 8.2_

- [x] 0.3 Set up S3 buckets in Singapore region
  - Check if S3 buckets exist: `aws s3 ls --region ap-southeast-1`
  - Create insighthr-uploads-sg bucket for file uploads (if not exists)
  - Create insighthr-web-app-sg bucket for static hosting (if not exists)
  - Configure CORS for uploads bucket
  - Enable static website hosting on web-app bucket
  - Set bucket policies for public read access (web-app only)
  - Update aws-secret.md with bucket names and URLs
  - _Requirements: 5.6, 9.1_

- [x] 0.4 Set up Cognito User Pool in Singapore region
  - Check if Cognito User Pool exists in ap-southeast-1
  - If not exists, create User Pool with:
    - Email/password authentication
    - Google OAuth provider configuration (Note: Google OAuth needs manual configuration)
    - Password policy (min 8 chars, uppercase, lowercase, number)
    - Email verification enabled
  - Create User Pool Client (app client)
  - Configure Google OAuth (client ID, client secret, callback URLs)
  - Create initial admin user for testing
  - Update aws-secret.md with User Pool ID, Client ID, and domain
  - _Requirements: 1.1, 1.2, 1.5_

- [x] 0.5 Set up API Gateway in Singapore region
  - Check if API Gateway exists in ap-southeast-1
  - If not exists, create REST API Gateway
  - Create Cognito authorizer for JWT validation
  - Set up CORS configuration for all endpoints (Note: CORS will be configured per endpoint)
  - Create /dev deployment stage
  - Update aws-secret.md with API Gateway ID and URL
  - Note: Individual endpoints will be created with each Lambda function
  - _Requirements: 11.6_

- [x] 0.6 Set up IAM roles for Lambda execution
  - Check if Lambda execution role exists
  - If not exists, create role with:
    - Trust policy for lambda.amazonaws.com
    - AWSLambdaBasicExecutionRole managed policy
    - Custom inline policy for DynamoDB access (all tables)
    - Custom inline policy for S3 access (uploads bucket)
    - Custom inline policy for SNS publish (for notifications)
    - Custom inline policy for Lex/Bedrock access (for chatbot)
  - Update aws-secret.md with role ARN
  - _Requirements: 1.1, 3.3, 5.6, 7.2, 8.2_

### Phase 1: Project Setup (Keeping Existing Codebase)

- [x] 1. Project setup and foundation
  - Initialize Vite + React + TypeScript project with required dependencies
  - Install shadcn/ui, React Hook Form, Zustand, Axios, Recharts
  - Configure Tailwind CSS with Apple Blue theme (inspired by Apple's design language)
  - Set up project structure (components, pages, services, store, types, utils)
  - Create .env files with AWS credentials from aws-secret.md
  - Create .env.example with placeholder values
  - Add aws-secret.md to .gitignore
  - Configure for S3/CloudFront deployment
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 1.1 Configure build and development tools


  - Set up Vite configuration with code splitting and optimization for S3
  - Configure TypeScript in non-strict mode with path aliases
  - Add ESLint and Prettier for code quality
  - Configure build output for static hosting
  - _Requirements: 11.5_

- [x] 1.2 Create theme and global styles
  - Implement Apple Blue color palette in theme.ts (inspired by Apple's design language)
  - Create global CSS with typography and spacing variables
  - Set up Tailwind configuration with custom theme
  - _Requirements: 10.2, 10.3_

- [x] 2. Common UI components with Apple Blue styling
  - Set up shadcn/ui components (Button, Input, Select, Dialog, Card, Textarea)
  - Customize components with Apple Blue theme
  - Create LoadingSpinner component with theme colors
  - Create Toast notification component
  - Create ConfirmDialog component
  - Create ErrorBoundary component
  - Fully style all components as they are built
  - Test each component in isolation
  - _Requirements: 10.3, 10.5, 9.5, 10.2_

- [x] 3. Routing and layout structure
  - Set up React Router with route configuration
  - Create MainLayout component with Header and Sidebar
  - Create ProtectedRoute component for role-based access
  - Implement navigation menu with role-based visibility
  - _Requirements: 1.2, 10.1_

- [x] 4. API service layer with AWS integration


  - Create Axios instance with base configuration pointing to API Gateway
  - Implement request interceptor for JWT token attachment
  - Implement response interceptor for token refresh and error handling
  - Create error handler utility for consistent error messages
  - Update .env with API Gateway URL from aws-secret.md
  - _Requirements: 11.6_

### Phase 2: Authentication System

- [x] 5. Frontend - Login and registration UI (static framework)






  - Create LoginForm component with email/password fields using React Hook Form
  - Create RegisterForm component for self-registration
  - Create GoogleAuthButton component for OAuth flow
  - Update LoginPage with form switching
  - Implement form validation for email and password
  - Add loading states and error handling
  - Fully style with Apple theme
  - Create test page at `/test/login` for isolated testing
  - _Requirements: 1.1, 1.2, 1.3, 1.4_
- [x] 5.1 Stub API - Authentication endpoints (local Express server)




  - Create `/stub-api` folder for local development server
  - Set up Express.js server on `localhost:4000`
  - Create in-memory user store with demo users (admin, manager, employee)
  - Implement POST /auth/login endpoint (validate credentials, return mock JWT)
  - Implement POST /auth/register endpoint (add user to memory, return mock JWT)
  - Implement POST /auth/google endpoint (mock Google OAuth, return mock JWT)
  - Implement POST /auth/refresh endpoint (return new mock JWT)
  - Return consistent response format matching AWS Lambda structure
  - Test all endpoints with Postman/curl
  - Document stub API in `/stub-api/README.md`
  - _Requirements: 1.1, 1.2, 1.4, 1.5_



- [x] 5.2 Frontend - Integrate with stub API




  - Install and configure amazon-cognito-identity-js
  - Update authService to call stub API endpoints
  - Implement login method calling stub API
  - Implement register method calling stub API
  - Implement Google OAuth flow (mock)
  - Update auth store (Zustand) for user state management
  - Implement token storage and retrieval from localStorage
  - Test authentication flow with stub API at `/test/login`
  - Verify role-based routing works with stub data
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 5.3 AWS Infrastructure - Authentication setup











  - Verify Cognito User Pool exists in ap-southeast-1 (from task 0.4)
  - Check if auth Lambda functions exist in ap-southeast-1
  - Create Lambda function: auth-login-handler
    - Runtime: Python 3.11
    - Handler: Validate Cognito tokens, query Users DynamoDB table
    - Environment variables: USER_POOL_ID, DYNAMODB_USERS_TABLE, AWS_REGION
  - Create Lambda function: auth-register-handler
    - Create Cognito user with auto-confirmation (admin_confirm_sign_up)
    - Insert user into Users DynamoDB table with Employee role by default
    - Return tokens immediately after registration
    - Note: Auto-approval is MVP approach; admin approval workflow is future enhancement
  - Create Lambda function: auth-google-handler
    - Handle Google OAuth callback, create/update user
  - Package Lambda functions with dependencies


  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 5.4 AWS Deployment - Authentication Lambda functions






  - Deploy auth-login-handler to ap-southeast-1
  - Deploy auth-register-handler to ap-southeast-1
  - Deploy auth-google-handler to ap-southeast-1
  - Create API Gateway endpoints:
    - POST /auth/login → auth-login-handler
    - POST /auth/register → auth-register-handler
    - POST /auth/google → auth-google-handler
    - POST /auth/refresh → auth-login-handler
  - Configure Cognito authorizer for protected endpoints
  - Test endpoints with Postman/curl

  - Update aws-secret.md with Lambda ARNs and API endpoints
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 5.5 Frontend - Switch to AWS endpoints and test











  - Update authService to use real AWS API Gateway URLs
  - Update .env with production API Gateway URL
  - Create environment toggle (stub vs AWS)
  - Test authentication flow with real Cognito on localhost
  - Create backdoor admin account in Cognito for testing
  - Test role-based routing (Admin, Manager, Employee)
  - Implement logout functionality (clear tokens, Cognito sign out)
  - Implement automatic token refresh on expiration
  - Add session persistence across page reloads
  - Verify end-to-end authentication works on localhost
  - _Requirements: 1.2, 1.5, 1.6_

- [x] 5.6 Build and deploy authentication phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3 bucket: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache (if CloudFront exists): `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website authentication flow
  - Verify CORS configuration allows S3-hosted frontend to call API Gateway
  - Test login, register, and logout on live site
  - Document deployment URL in aws-secret.md
  - Fix: Added OPTIONS methods to API Gateway endpoints for CORS preflight support
  - _Requirements: 1.2, 1.5, 9.1_

- [x] 5.7 Set up CloudFront distribution for HTTPS and cleaner URL





  - Create CloudFront distribution for S3 website bucket
  - Configure CloudFront origin to point to S3 website endpoint (insighthr-web-app-sg.s3-website-ap-southeast-1.amazonaws.com)
  - Set origin protocol policy to HTTP only (S3 website endpoints don't support HTTPS)
  - Configure default cache behavior (compress objects, redirect HTTP to HTTPS)
  - Set default root object to index.html
  - Configure custom error responses (404 -> /index.html for SPA routing)
  - Enable CloudFront distribution and wait for deployment (Status: Deployed)
  - Test HTTPS access via CloudFront domain (e.g., https://d1234abcd.cloudfront.net)
  - Update CORS configuration on API Gateway to allow CloudFront domain
  - Update aws-secret.md with CloudFront distribution ID and domain URL
  - Note: CloudFront provides free HTTPS with default *.cloudfront.net domain (no custom domain needed)
  - _Requirements: 9.1, 11.4_

- [x] 5.8 Implement real Google OAuth login/register



  - Set up Google Cloud Console project and create OAuth 2.0 credentials
  - Configure authorized JavaScript origins and redirect URIs for localhost and CloudFront
  - Install @react-oauth/google package in frontend
  - Update GoogleAuthButton component to use real Google OAuth flow with GoogleOAuthProvider
  - Implement handleCredentialResponse to receive Google JWT token
  - Update authService.googleLogin() to send Google JWT token to backend
  - Update lambda/auth/auth_google_handler.py to verify Google JWT token with Google's API
  - Extract user info (email, name, picture) from verified Google token
  - Check if user exists in DynamoDB Users table by email
  - If user exists, return existing user with Cognito tokens (login flow)
  - If user doesn't exist, create new Cognito user and DynamoDB record (register flow)
  - Test Google OAuth flow end-to-end on localhost
  - Deploy updated Lambda to AWS and test on CloudFront domain
  - Document Google OAuth setup in README.md (client ID, redirect URIs)
  - _Requirements: 1.1, 1.4, 1.5_

### Phase 6: User Management (Profile & Admin User CRUD)

- [x] 6. Frontend - User types and service layer





  - Create user.types.ts with interfaces:
    - User (userId, email, name, role, department, employeeId, status, createdAt, updatedAt)
    - CreateUserRequest (email, name, role, department, employeeId)
    - UpdateUserRequest (name, role, department, employeeId)
    - UserFilters (search, department, role, status)
  - Create userService.ts with API methods:
    - getMe() → GET /users/me (fetch current user profile)
    - updateMe(data) → PUT /users/me (update current user profile)
    - getAll(filters) → GET /users (fetch all users with filters, Admin only)
    - create(userData) → POST /users (create new user, Admin only)
    - update(userId, userData) → PUT /users/:userId (update user, Admin only)
    - disable(userId) → PUT /users/:userId/disable (disable user, Admin only)
    - enable(userId) → PUT /users/:userId/enable (enable user, Admin only)
    - delete(userId) → DELETE /users/:userId (delete user, Admin only)
    - bulkImport(csvData) → POST /users/bulk (bulk create users from CSV, Admin only)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_


- [x] 6.1 Frontend - Profile page UI (/profile)







  - Create ProfileView component (read-only display):
    - Display user information (name, email, role, department, employeeId)
    - Show avatar placeholder
    - Add "Edit Profile" button (opens edit form)
  - Create ProfileEdit component:
    - Allow editing name and department only (email and role not editable)
    - Form validation with React Hook Form
    - Submit and Cancel buttons 
  - Style with Apple theme
  - Create test page at `/test/profile` for isolated testing
  - _Requirements: 2.1, 2.2_


- [x] 6.2 Frontend - User management UI components (Admin only) (/admin/users)


  - Create UserManagement container component with tabs
  - Create UserList component:
    - Table with columns: name, email, role, department, employeeId, status, actions
    - Sortable columns (click header to sort)
    - Action buttons: Edit, Disable/Enable, Delete (with confirmation)
    - Pagination controls (10, 25, 50 per page)
  - Create UserForm component for create/edit:
    - Fields: email, name, role (dropdown: Admin/Manager/Employee), department (dropdown), employeeId
    - Validation: required fields, email format, unique email check
    - Submit and Cancel buttons
  - Create UserFilters component:
    - Search input (filter by name or email)
    - Department dropdown filter
    - Role dropdown filter
    - Status filter (All, Active, Disabled)
    - Clear filters button
  - Create UserBulkImport component:
    - CSV file upload with drag-and-drop
    - CSV template download button
    - Preview imported users before confirmation
    - Bulk import progress indicator
  - Add confirmation dialogs for destructive actions
  - Style all components with Apple theme
  - Create main page at `/admin/users`
  - Create test page at `/test/users` for isolated testing

  - _Requirements: 2.3, 2.4, 2.5_

- [x] 6.3 Stub API - User management endpoints





  - Add to Express.js stub server (`localhost:4000`)
  - Create in-memory user store with demo users (admin, manager, employees)
  - Implement GET /users/me endpoint (return current user profile)
  - Implement PUT /users/me endpoint (update user profile in memory)
  - Implement GET /users endpoint (return all users with filters, Admin only)
  - Implement POST /users endpoint (create user, Admin only)
  - Implement PUT /users/:userId endpoint (update user, Admin only)
  - Implement PUT /users/:userId/disable endpoint (disable user, Admin only)
  - Implement PUT /users/:userId/enable endpoint (enable user, Admin only)
  - Implement DELETE /users/:userId endpoint (delete user, Admin only)
  - Implement POST /users/bulk endpoint (bulk create users from CSV, Admin only)
  - Return consistent response format matching AWS Lambda structure
  - Test all endpoints with Postman/curl

  - Document stub API in `/stub-api/README.md`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.4 Frontend - Integrate with stub API and test






  - Connect ProfileView to userService:
    - Fetch data from stub /users/me endpoint on mount
    - Implement loading and error states
  - Connect ProfileEdit to userService:
    - Call updateMe() on form submit
    - Show success/error toast notification
  - Connect UserManagement components to stub API:
    - UserList: fetch users on mount, apply filters, handle pagination
    - UserForm: call create/update on submit
    - UserFilters: trigger getAll() with filter params on change
    - UserBulkImport: call bulkImport() with CSV data
  - Test profile page at `/test/profile`:
    - Verify user data loads correctly
    - Test edit form and save changes
    - Verify error handling
  - Test user management at `/test/users`:
    - Test user list display with sorting and pagination
    - Test create user flow
    - Test edit user flow
    - Test disable/enable user
    - Test delete user with confirmation
    - Test filtering and search

    - Test bulk import with CSV file
  - Verify Admin-only access control works
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.5 AWS Infrastructure - User management Lambda





  - Check if user Lambda functions exist in ap-southeast-1
  - Create Lambda function: users-handler (Python 3.11)
    - GET /users/me → Fetch current user from DynamoDB by userId (from JWT)
    - PUT /users/me → Update current user profile in DynamoDB
    - GET /users → List all users with filters (Admin only)
    - POST /users → Create user in Cognito and DynamoDB (Admin only)
    - PUT /users/:userId → Update user in Cognito and DynamoDB (Admin only)
    - PUT /users/:userId/disable → Disable user in Cognito and DynamoDB (Admin only)
    - PUT /users/:userId/enable → Enable user in Cognito and DynamoDB (Admin only)
    - DELETE /users/:userId → Delete user from Cognito and DynamoDB (Admin only)
  - Create Lambda function: users-bulk-handler (Python 3.11)
    - POST /users/bulk → Parse CSV, create multiple users in Cognito and DynamoDB
    - Return success/failure for each user

  - Implement role-based authorization (extract role from JWT)
  - Implement error handling for Cognito and DynamoDB operations
  - Package Lambdas with dependencies (boto3)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.6 AWS Deployment - User management Lambda
  - Deploy users-handler to ap-southeast-1
  - Deploy users-bulk-handler to ap-southeast-1
  - Create API Gateway endpoints:
    - GET /users/me (Cognito authorizer required)
    - PUT /users/me (Cognito authorizer required)
    - GET /users (Cognito authorizer required, Admin only)
    - POST /users (Cognito authorizer required, Admin only)
    - PUT /users/:userId (Cognito authorizer required, Admin only)
    - PUT /users/:userId/disable (Cognito authorizer required, Admin only)
    - PUT /users/:userId/enable (Cognito authorizer required, Admin only)
    - DELETE /users/:userId (Cognito authorizer required, Admin only)
    - POST /users/bulk (Cognito authorizer required, Admin only)
  - Configure CORS for all endpoints
  - Test endpoints with Postman/curl:
    - Test GET /users/me with valid JWT
    - Test PUT /users/me with profile update
    - Test GET /users with Admin token (should return all users)
    - Test GET /users with Employee token (should return 403)
    - Test POST /users with valid user data
    - Test PUT /users/:userId with role/department update
    - Test disable/enable user endpoints
    - Test DELETE /users/:userId
    - Test POST /users/bulk with CSV data
  - Update aws-secret.md with Lambda ARNs and API Gateway endpoints
  - **KNOWN ISSUE NOT FIXED**: Frontend was sending accessToken instead of idToken
    - Cognito authorizer requires idToken (contains user identity)
    - accessToken is rejected with 401 Unauthorized
    - Solution: Frontend must use idToken for Authorization header
    - See lambda/users/FIX-401-ISSUE.md for details
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.7 Frontend - Switch to AWS endpoints and test












  - Update userService to use real AWS API Gateway URLs (from .env)
  - Update .env with production API Gateway URL for user endpoints
  - Test profile page with real DynamoDB data on localhost:
    - Login as test user
    - Navigate to /test/profile
    - Verify profile data loads from DynamoDB
    - Test profile edit and verify changes persist
  - Test user management with real data on localhost:
    - Login as Admin user
    - Navigate to /test/users
    - Verify user list loads from DynamoDB
    - Test create user (should create in Cognito and DynamoDB)
    - Test edit user (should update in both systems)
    - Test disable/enable user (should update Cognito status)
    - Test delete user (should remove from both systems)
    - Test bulk import with CSV file
  - Verify role-based access control:
    - Test with Employee user (should see "Access Denied" for /test/users)

    - Test with Admin user (should see full user management UI)
  - Test filtering and search with real data
  - Verify error handling with invalid data and network errors
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6.8 Build and deploy user management phase to S3





  - commit all unstaged/staged changes including submodules to github
  - polish user management "edit user" page
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website profile features:
    - Login as test user
    - Access profile page and verify data loads
    - Test profile edit functionality
  - Test live deployed website user management features (Admin only):
    - Login as Admin user
    - Access user management page
    - Test create user flow
    - Test edit user flow
    - Test disable/enable user
    - Test delete user
    - Test bulk import
    - Test filtering and search
  - Verify all user operations work on live site
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document deployment URL in aws-secret.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 9.1_

### Phase 3: Performance Dashboard (Moved Up)

- [x] 7. AWS Infrastructure - Scan for existing employee/performance tables


  - Check if PerformanceScores table exists in ap-southeast-1: `aws dynamodb describe-table --table-name PerformanceScores --region ap-southeast-1`
  - Check if Employees table exists in ap-southeast-1: `aws dynamodb describe-table --table-name Employees --region ap-southeast-1`
  - If PerformanceScores table exists:
    - Analyze table schema (PK, SK, GSIs, attributes)
    - Verify it has required fields: employeeId, period, score, department, kpiScores
    - Check if GSI exists for department-period queries
    - If schema is correct, document in aws-secret.md and use existing table
    - If schema is broken/incomplete, decide: fix schema or create new table
  - If PerformanceScores table doesn't exist:
    - Create table with schema: PK=employeeId, SK=period, GSI=department-period-index
  - If Employees table exists:
    - Analyze table schema and verify it has: employeeId, name, department, role
    - If correct, use existing table
    - If broken, fix or create new
  - If Employees table doesn't exist:
    - Check if Users table can serve as employee data source
    - If not, create Employees table
  - Update aws-secret.md with table names, ARNs, and schema details
  - _Requirements: 6.1, 6.2_

- [x] 7.1 Frontend - Dashboard UI (static framework)



  - implement ui feature at /dashboard
  - Create Performance types and interfaces
  - Create PerformanceDashboard container component
  - Create DataTable component with sortable columns
  - Create FilterPanel with department, time period, employee filters
  - Install and configure Recharts library
  - Create LineChart component for performance trends
  - Create BarChart component for comparative performance
  - Create PieChart component for distribution
  - Create ExportButton component
  - Implement role-based data display (Admin/Manager/Employee)
  - Style with Apple theme
  - Create test page at `/test/dashboard` for isolated testing
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7.1.1 HOTFIX - Bulk User Import & Password Reset


  **Backend:**
  - Update `users_bulk_handler.py`: parse optional `password` column from CSV
  - If password provided: use it, set `forceChangePassword=false`
  - If password empty: generate with `secrets.token_urlsafe(12)`, set `forceChangePassword=true`
  - Return: `{ hasGeneratedPasswords: bool, results: [{ email, userId, generatedPassword?, wasGenerated }] }`
  - Create `PasswordResetRequests` table: PK=requestId, GSI=status-index, GSI=userId-index
  - Create `password-reset-handler.py` Lambda
  - POST `/auth/request-reset`: validate email, check no pending request, create record
  - GET `/users/password-requests`: query pending requests (Admin only)
  - POST `/users/:userId/approve-reset`: reset password to user's email, set FORCE_CHANGE_PASSWORD, update status
  
  **Frontend:**
  - Update CSV template: add `password` column
  - Update `BulkImportResult` interface: add `hasGeneratedPasswords`, `results` array
  - Update `UserBulkImport.tsx`: if `hasGeneratedPasswords=true`, show modal with table (email + password) and "Download CSV" button
  - Create `/reset-request` page: email input, reason textarea, submit button
  - Update `LoginForm.tsx`: change `<a href="#">` to `<Link to="/reset-request">`
  - Add "Password Requests" tab to `UserManagement.tsx` with badge showing count
  - Create `PasswordRequestsPanel.tsx`: table with Email, Name, Requested, Reason, Approve button
  - Create `ChangePasswordModal.tsx`: current password, new password, confirm password fields, cannot dismiss
  - Update `authService.ts`: add `changePassword()` method, check NEW_PASSWORD_REQUIRED after login
  - Show `ChangePasswordModal` if force change required, block app access until complete

  - test all implemented features
  - deploy all changes to aws
  - once confirmed by me, commit all staged/unstaged changes to github 
  
  _Requirements: 1.1, 1.2, 2.5_

- [x] 7.1.2 HOTFIX - Password Reset UI Improvements & Role Color Fix











  **Password Reset Flow Enhancement:**
  - User requests password reset → Admin approves/denies → System generates new password → Admin sees generated password → Admin informs user → User must change password on first login
  
  **Backend Changes:**
  - Update `password_reset_handler.py`:
    - Add POST `/users/password-requests/:requestId/deny` endpoint (Admin only)
    - Update POST `/users/password-requests/:requestId/approve` to:
      - Generate secure password adhering to Cognito password rules (min 8 chars, uppercase, lowercase, number, special char)
      - Use `secrets` module for cryptographically secure password generation
      - Reset user password in Cognito with generated password
      - Set `forceChangePassword=true` in Cognito (FORCE_CHANGE_PASSWORD status)
      - Return generated password in response: `{ success: true, generatedPassword: "xxx", email: "user@example.com" }`
      - Update request status to "approved" in DynamoDB
    - Deny endpoint should update status to "denied" in DynamoDB
  
  **Frontend Changes:**
  - Update `PasswordRequestsPanel.tsx`:
    - Add "Deny" button next to "Approve" button for each request
    - When "Approve" is clicked:
      - Call approve endpoint
      - Display modal showing generated password with copy-to-clipboard button
      - Show message: "Generated password for [email]: [password]. Please inform the user."
      - Provide "Download as Text" button to save password
      - Modal should have "Done" button to close after admin confirms they've saved the password
    - When "Deny" is clicked:
      - Show confirmation dialog: "Are you sure you want to deny this password reset request?"
      - Call deny endpoint
      - Show success toast: "Password reset request denied"
    - Refresh request list after approve/deny action
  
  - Update `UserList.tsx` (User Management tab):
    - Change role badge color for "Employee" role from current color to green
    - Keep "Admin" role as red/primary color
    - Keep "Manager" role as blue/secondary color
    - Ensure color change is consistent across all role displays in the user list
  
  - Test all changes:
    - Test password reset request flow end-to-end
    - Verify generated password meets Cognito requirements
    - Test approve flow and verify modal displays password correctly
    - Test deny flow and verify request is marked as denied
    - Test copy-to-clipboard functionality
    - Verify user is forced to change password on first login after reset
    - Verify Employee role displays in green color in user management list
  
  - Deploy changes:
    - Deploy updated Lambda function to AWS
    - Test deployed endpoints
    - Deploy frontend to S3 and invalidate CloudFront cache
    - Verify all changes work on live site
  
  _Requirements: 1.6, 2.3, 2.4_

- [x] 7.2 AWS Lambda - Performance data handler





  - Check if performance Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep performance`
  - If performance-handler Lambda exists:
    - Analyze Lambda configuration (runtime, handler, environment variables, IAM role)
    - Test Lambda with sample event to verify it works
    - Check if it queries the correct DynamoDB tables
    - Verify it has AUTO_SCORING_LAMBDA_ARN environment variable (can be empty)
    - If working correctly, document in aws-secret.md and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If performance-handler doesn't exist:
    - Create Lambda function: performance-handler (Python 3.11)
    - Runtime: Python 3.11
    - Handler: Query PerformanceScores and Employees tables
    - Environment variables:
      - PERFORMANCE_SCORES_TABLE (required)
      - EMPLOYEES_TABLE (required)
      - AUTO_SCORING_LAMBDA_ARN (optional, empty for Phase 3, set in Phase 5)
      - AWS_REGION=ap-southeast-1
    - Implement inter-Lambda communication pattern:
      - Check if AUTO_SCORING_LAMBDA_ARN is set
      - If set, invoke auto-scoring Lambda asynchronously (Event invocation)
      - If not set or invocation fails, log warning and continue with existing data
      - Graceful degradation: Lambda works with or without auto-scoring
    - GET /performance → Query performance scores with filters (department, period, employeeId)
    - GET /performance/:employeeId → Get employee performance history
    - POST /performance/export → Generate CSV export
    - Implement DynamoDB queries with GSI for filtering (department-period-index)
    - Implement role-based data filtering (Admin sees all, Manager sees department, Employee sees own)
  - Set up DynamoDB Stream trigger on Employees table (optional for Phase 3):
    - Throttled/batched trigger to prevent high bandwidth usage
    - Triggers performance-handler when employee data changes
  - Package Lambda with dependencies (boto3)
  - Deploy performance-handler to ap-southeast-1
  - Check if API Gateway endpoints exist for performance operations
  - If endpoints exist, verify they point to correct Lambda and have proper CORS
  - If endpoints don't exist or are broken, create/fix them
  - Create API Gateway endpoints:
    - GET /performance (Cognito authorizer required)
    - GET /performance/:employeeId (Cognito authorizer required)
    - POST /performance/export (Cognito authorizer required)
  - Configure CORS for all endpoints
  - Test data retrieval with filters using Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoints
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7.3 Integration & Deploy - Performance dashboard





  - Create performanceService for API calls to AWS endpoints
  - Create performance store (Zustand) with filters
  - Update dashboard components to use AWS API Gateway URLs
  - Test dashboard with real DynamoDB data on localhost
  - Test filtering with real data
  - Test charts with real performance scores
  - Test CSV export with real data
  - Verify role-based access works (Admin sees all, Manager sees department, Employee sees own)
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website dashboard features
  - Verify charts, filters, and CSV export work on live site
  - Test role-based data visibility on live site
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 9.1_


- [x] 7.3.1 HOTFIX - Dashboard Redesign & Architecture Improvements






  **Architecture Changes:**
  - Redesign dashboard page with tab-based navigation
  - Separate "Charts" tab and "Employees" tab
  - Show Charts tab by default on page load
  - Improve chart organization and data visualization
  
  **Frontend Changes:**
  - Update `PerformanceDashboard.tsx`:
    - Add tab navigation component (Charts | Employees)
    - Default to Charts tab on load
    - Move DataTable to Employees tab
    - Keep FilterPanel accessible from both tabs
  
  - Redesign Charts tab layout:
    - **Section 1: Overview Cards** (top row)
      - Total Employees card
      - Average Score card (across all filtered data)
      - Highest Score card
      - Lowest Score card
    
    - **Section 2: Performance by Department** (second row)
      - Bar Chart: Average score by department (DEV, QA, DAT, SEC)
      - Pie Chart: Employee distribution by department
    
    - **Section 3: Performance Trends** (third row)
      - Line Chart: Average score by quarter (2025-1, 2025-2, 2025-3)
      - Line Chart: Score trends by department over quarters
    
    - **Section 4: Performance Distribution** (fourth row)
      - Pie Chart: Score ranges (Excellent 80-100, Good 60-79, Needs Improvement <60)
      - Bar Chart: Employee count by score range and department
  
  - Update Employees tab:
    - Move DataTable here with all employee performance records
    - Keep sortable columns and pagination
    - Add employee search functionality
    - Show detailed KPI scores in expandable rows
  
  - Update FilterPanel:
    - Add department filter: ALL, DEV, QA, DAT, SEC
    - Add period filter: ALL, 2025-1, 2025-2, 2025-3
    - Add quarter/monthly toggle (for future use)
    - Apply filters to both Charts and Employees tabs
  
  **Backend Changes:**
  - Update `performance_handler.py`:
    - Fix department extraction logic to match current implementation
    - Ensure department values are: DEV, QA, DAT, SEC (not Development, Quality Assurance, etc.)
    - Verify period format is "2025-1", "2025-2", "2025-3" (not "2025-Q1")
  
  - Update `import-performance-data.py`:
    - Verify department extraction from employeeId is correct
    - Ensure period format matches: "YYYY-{season}" (e.g., "2025-1")
  
  **Testing:**
  - Test Charts tab loads by default
  - Test tab switching between Charts and Employees
  - Test all charts display correct data
  - Test filters apply to both tabs
  - Test department breakdown shows DEV, QA, DAT, SEC correctly
  - Test quarterly trends show 2025-1, 2025-2, 2025-3
  - Test Employees tab shows detailed records
  - Deploy to S3 and test on live site
  
  _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 10.1, 10.2_



- [ ] 7.4 HOTFIX - UI Updates & Password Reset Message


  **UI Navigation Updates:**
  - Update AdminPage component navigation
  - Remove old navigation items from sidebar/menu:
    - KPI Management
    - Formula Builder  
    - Upload Data
  - Add new navigation items to sidebar/menu:
    - Employee Management (/admin/employees)
    - Performance Score Management (/admin/performance-scores)
  - Keep existing navigation items:
    - User Management (/admin/users)
    - Dashboard (/dashboard)
  - Update any breadcrumbs or page titles
  - Remove any references to old features in UI
  - Style navigation with Apple theme
  
  **Password Reset Message Update:**
  - Update PasswordResetRequestPage component:
    - Change success message after submission
    - New message: "Your password reset request has been submitted. An admin will contact you with your new password."
  - Update any related confirmation dialogs or toast messages
  - Test password reset request flow with new message
  
  **Testing:**
  - Test navigation shows correct menu items
  - Test clicking new menu items navigates to correct pages (even if pages don't exist yet, routes should be defined)
  - Test old menu items are removed
  - Test password reset message displays correctly
  - Deploy to S3 and test on live site
  
  _Requirements: UI organization, password reset flow_

### Phase 4: Employee Management (Full CRUD)

- [ ] 8. AWS Infrastructure - Verify Employees table
  - Check if Employees table exists in ap-southeast-1: `aws dynamodb describe-table --table-name insighthr-employees-dev --region ap-southeast-1`
  - If Employees table exists:
    - Analyze table schema (PK, SK, GSIs, attributes)
    - Verify it has required fields: employeeId, name, position, department, status
    - Check if GSI exists for department-index queries
    - Verify table contains employee data (should have ~300 employees)
    - If schema is correct, document in aws-secret.md and use existing table
    - If schema is broken/incomplete, decide: fix schema or create new table
  - If Employees table doesn't exist:
    - Create table with schema: PK=employeeId, GSI=department-index
    - Prepare to import data from employee_quarterly_scores_2025.csv
  - Update aws-secret.md with table name, ARN, and schema details
  - _Requirements: Employee data management_

- [ ] 8.1 Frontend - Employee Management UI components
  - Implement UI feature at /admin/employees
  - Create Employee types and interfaces (employee.types.ts):
    - Employee (employeeId, name, position, department, status, createdAt, updatedAt)
    - CreateEmployeeRequest (employeeId, name, position, department)
    - UpdateEmployeeRequest (name, position, department, status)
    - EmployeeFilters (search, department, position, status)
  - Create EmployeeManagement container component with tabs
  - Create EmployeeList component:
    - Table with columns: employeeId, name, position, department, status, actions
    - Sortable columns (click header to sort)
    - Action buttons: Edit, Delete (with confirmation)
    - Pagination controls (10, 25, 50 per page)
  - Create EmployeeForm component for create/edit:
    - Fields: employeeId, name, position (dropdown: Junior/Mid/Senior/Lead/Manager), department (dropdown: DEV/QA/DAT/SEC)
    - Validation: required fields, unique employeeId check
    - Submit and Cancel buttons
  - Create EmployeeFilters component:
    - Search input (filter by name or employeeId)
    - Department dropdown filter (ALL, DEV, QA, DAT, SEC)
    - Position dropdown filter (ALL, Junior, Mid, Senior, Lead, Manager)
    - Status filter (All, Active, Inactive)
    - Clear filters button
  - Create EmployeeBulkImport component:
    - CSV file upload with drag-and-drop
    - CSV template download button
    - Preview imported employees before confirmation
    - Bulk import progress indicator
  - Add confirmation dialogs for destructive actions (delete)
  - Style all components with Apple theme
  - Create main page at `/admin/employees`
  - Create test page at `/test/employees` for isolated testing
  - _Requirements: Employee CRUD operations_

- [ ] 8.2 Stub API - Employee management endpoints
  - Add to Express.js stub server (`localhost:4000`)
  - Create in-memory employee store with demo employees from different departments
  - Implement GET /employees endpoint (return all employees with filters)
  - Implement GET /employees/:employeeId endpoint (return single employee)
  - Implement POST /employees endpoint (create employee, Admin only)
  - Implement PUT /employees/:employeeId endpoint (update employee, Admin only)
  - Implement DELETE /employees/:employeeId endpoint (delete employee, Admin only)
  - Implement POST /employees/bulk endpoint (bulk create employees from CSV, Admin only)
  - Return consistent response format matching AWS Lambda structure
  - Test all endpoints with Postman/curl
  - Document stub API in `/stub-api/README.md`
  - _Requirements: Employee CRUD operations_

- [ ] 8.3 Frontend - Integrate with stub API and test
  - Create employeeService for API calls to stub endpoints
  - Create employee store (Zustand) for state management
  - Connect EmployeeManagement components to stub API:
    - EmployeeList: fetch employees on mount, apply filters, handle pagination
    - EmployeeForm: call create/update on submit
    - EmployeeFilters: trigger getAll() with filter params on change
    - EmployeeBulkImport: call bulkImport() with CSV data
  - Test employee management at `/test/employees`:
    - Test employee list display with sorting and pagination
    - Test create employee flow
    - Test edit employee flow
    - Test delete employee with confirmation
    - Test filtering and search
    - Test bulk import with CSV file
  - Verify Admin-only access control works
  - _Requirements: Employee CRUD operations_

- [ ] 8.4 AWS Lambda - Employee management handler
  - Check if employee Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep employee`
  - If employees-handler Lambda exists:
    - Analyze Lambda configuration (runtime, handler, environment variables, IAM role)
    - Test Lambda with sample event to verify it works
    - Check if it queries the correct DynamoDB Employees table
    - If working correctly, document in aws-secret.md and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If employees-handler doesn't exist:
    - Create Lambda function: employees-handler (Python 3.11)
    - GET /employees → List all employees with filters (department, position, status)
    - GET /employees/:employeeId → Get single employee
    - POST /employees → Create employee (Admin only)
    - PUT /employees/:employeeId → Update employee (Admin only)
    - DELETE /employees/:employeeId → Delete employee (Admin only)
    - Implement DynamoDB operations (scan, get, put, update, delete)
    - Implement role-based authorization (extract role from JWT)
    - Implement filtering with GSI (department-index)
  - Create Lambda function: employees-bulk-handler (Python 3.11)
    - POST /employees/bulk → Parse CSV, create multiple employees in DynamoDB
    - Return success/failure for each employee
  - Package Lambdas with dependencies (boto3)
  - _Requirements: Employee CRUD operations_

- [ ] 8.5 AWS Deployment - Employee management Lambda
  - Deploy employees-handler to ap-southeast-1
  - Deploy employees-bulk-handler to ap-southeast-1
  - Create API Gateway endpoints:
    - GET /employees (Cognito authorizer required)
    - GET /employees/:employeeId (Cognito authorizer required)
    - POST /employees (Cognito authorizer required, Admin only)
    - PUT /employees/:employeeId (Cognito authorizer required, Admin only)
    - DELETE /employees/:employeeId (Cognito authorizer required, Admin only)
    - POST /employees/bulk (Cognito authorizer required, Admin only)
  - Configure CORS for all endpoints
  - Test endpoints with Postman/curl:
    - Test GET /employees with filters
    - Test GET /employees/:employeeId
    - Test POST /employees with valid employee data
    - Test PUT /employees/:employeeId
    - Test DELETE /employees/:employeeId
    - Test POST /employees/bulk with CSV data
  - Update aws-secret.md with Lambda ARNs and API Gateway endpoints
  - _Requirements: Employee CRUD operations_

- [ ] 8.6 Frontend - Switch to AWS endpoints and test
  - Update employeeService to use real AWS API Gateway URLs (from .env)
  - Update .env with production API Gateway URL for employee endpoints
  - Test employee management with real DynamoDB data on localhost:
    - Login as Admin user
    - Navigate to /test/employees
    - Verify employee list loads from DynamoDB
    - Test create employee (should create in DynamoDB)
    - Test edit employee (should update in DynamoDB)
    - Test delete employee (should remove from DynamoDB)
    - Test bulk import with CSV file
  - Verify role-based access control:
    - Test with Employee user (should see "Access Denied" for /test/employees)
    - Test with Admin user (should see full employee management UI)
  - Test filtering and search with real data
  - Verify error handling with invalid data and network errors
  - _Requirements: Employee CRUD operations_

- [ ] 8.7 Import employee data from CSV
  - Create Python script to parse employee_quarterly_scores_2025.csv
  - Extract unique employees from CSV (employeeId, position columns)
  - Derive department from employeeId prefix (DEV-, QA-, DAT-, SEC-)
  - Generate employee records with fields:
    - employeeId (from CSV)
    - name (generate from employeeId, e.g., "Employee DEV-01013")
    - position (from CSV: Junior, Mid, Senior, Lead, Manager)
    - department (derived from employeeId prefix)
    - status: "Active"
    - createdAt: current timestamp
    - updatedAt: current timestamp
  - Batch write employees to DynamoDB Employees table
  - Verify ~300 unique employees are imported
  - Test employee list in UI shows all imported employees
  - Document import process in scripts/README.md
  - _Requirements: Employee data management_

- [ ] 8.8 Update User Management to use Employee selector
  - Update UserForm component:
    - Replace manual employeeId text input with searchable dropdown
    - Add employee search/autocomplete functionality
    - Fetch employees from /employees endpoint
    - Display: "employeeId - name - department" in dropdown
    - Allow filtering by typing employeeId or name
    - Show "No employee selected" option
  - Update userService:
    - Add getEmployees() method to fetch employee list
  - Test employee selection in user create/edit forms:
    - Verify dropdown loads employees from Employee table
    - Test search/filter functionality
    - Test selecting employee and saving user
    - Verify employeeId is correctly assigned to user
  - Style dropdown with Apple theme
  - _Requirements: User-Employee relationship_

- [ ] 8.9 Build and deploy employee management phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website employee management features:
    - Login as Admin user
    - Access employee management page
    - Test create employee flow
    - Test edit employee flow
    - Test delete employee
    - Test bulk import
    - Test filtering and search
  - Test user management employee selector on live site
  - Verify all employee operations work on live site
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document deployment URL in aws-secret.md
  - _Requirements: Employee CRUD operations, deployment_

### Phase 5: Performance Score Management (Calendar View)

- [ ] 9. AWS Infrastructure - Verify PerformanceScores table
  - Check if PerformanceScores table exists in ap-southeast-1: `aws dynamodb describe-table --table-name insighthr-performance-scores-dev --region ap-southeast-1`
  - If PerformanceScores table exists:
    - Analyze table schema (PK, SK, GSIs, attributes)
    - Verify it has required fields: employeeId, period, KPI, completed_task, feedback_360, final_score, department, position
    - Check if GSI exists for department-period-index queries
    - Verify table contains performance data (should have ~900 records: 300 employees × 3 quarters)
    - If schema is correct, document in aws-secret.md and use existing table
    - If schema is broken/incomplete, decide: fix schema or create new table
  - If PerformanceScores table doesn't exist:
    - Create table with schema: PK=employeeId, SK=period, GSI=department-period-index
    - Prepare to import data from employee_quarterly_scores_2025.csv
  - Update aws-secret.md with table name, ARN, and schema details
  - _Requirements: Performance score tracking_

- [ ] 9.1 Frontend - Performance Score Calendar UI
  - Implement UI feature at /admin/performance-scores
  - Create PerformanceScore types and interfaces (performanceScore.types.ts):
    - PerformanceScore (employeeId, period, KPI, completed_task, feedback_360, final_score, department, position)
    - CreateScoreRequest (employeeId, period, KPI, completed_task, feedback_360, final_score)
    - UpdateScoreRequest (KPI, completed_task, feedback_360, final_score)
    - ScoreFilters (department, period, employeeId)
  - Create PerformanceScoreManagement container component
  - Create CalendarView component:
    - View toggle: Week / Month / Quarter (default: Quarter)
    - Calendar grid showing employees (rows) × time periods (columns)
    - Each cell displays final_score with color coding:
      - Green (80-100): Excellent performance
      - Yellow (60-79): Good performance
      - Red (<60): Needs improvement
    - Click on cell to view/edit score details
  - Create ScoreDetailModal component:
    - Display employee info (employeeId, name, department, position)
    - Display period (e.g., "2025-Q1", "2025-Q2", "2025-Q3")
    - Show detailed scores:
      - KPI score
      - Completed tasks score
      - 360 feedback score
      - Final score (calculated or manual)
    - Edit mode: Allow updating individual scores
    - Save and Cancel buttons
  - Create ScoreFilters component:
    - Department dropdown filter (ALL, DEV, QA, DAT, SEC)
    - Period dropdown filter (ALL, 2025-1, 2025-2, 2025-3)
    - Employee search input (filter by employeeId or name)
    - Clear filters button
  - Create ScoreForm component for create/edit:
    - Fields: employeeId (dropdown from Employees), period (dropdown), KPI, completed_task, feedback_360, final_score
    - Validation: required fields, score ranges (0-100)
    - Auto-calculate final_score option
    - Submit and Cancel buttons
  - Style all components with Apple theme
  - Create main page at `/admin/performance-scores`
  - Create test page at `/test/performance-scores` for isolated testing
  - _Requirements: Performance score CRUD, calendar view_

- [ ] 9.2 Stub API - Performance score endpoints
  - Add to Express.js stub server (`localhost:4000`)
  - Create in-memory performance score store with demo data (multiple employees, multiple quarters)
  - Implement GET /performance-scores endpoint (return scores with filters: department, period, employeeId)
  - Implement GET /performance-scores/:employeeId/:period endpoint (return single score)
  - Implement POST /performance-scores endpoint (create score, Admin only)
  - Implement PUT /performance-scores/:employeeId/:period endpoint (update score, Admin only)
  - Implement DELETE /performance-scores/:employeeId/:period endpoint (delete score, Admin only)
  - Return consistent response format matching AWS Lambda structure
  - Test all endpoints with Postman/curl
  - Document stub API in `/stub-api/README.md`
  - _Requirements: Performance score CRUD_

- [ ] 9.3 Frontend - Integrate with stub API and test
  - Create performanceScoreService for API calls to stub endpoints
  - Create performance score store (Zustand) for state management
  - Connect PerformanceScoreManagement components to stub API:
    - CalendarView: fetch scores on mount, apply filters, render calendar grid
    - ScoreDetailModal: fetch score details, update on save
    - ScoreFilters: trigger getAll() with filter params on change
    - ScoreForm: call create/update on submit
  - Test performance score management at `/test/performance-scores`:
    - Test calendar view displays scores correctly
    - Test color coding (green/yellow/red) based on score ranges
    - Test clicking cell opens detail modal
    - Test editing score in modal
    - Test creating new score
    - Test filtering by department and period
    - Test employee search
  - Verify Admin-only access control works
  - _Requirements: Performance score CRUD, calendar view_

- [ ] 9.4 AWS Lambda - Performance score management handler
  - Check if performance-scores Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep performance-score`
  - If performance-scores-handler Lambda exists:
    - Analyze Lambda configuration (runtime, handler, environment variables, IAM role)
    - Test Lambda with sample event to verify it works
    - Check if it queries the correct DynamoDB PerformanceScores table
    - If working correctly, document in aws-secret.md and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If performance-scores-handler doesn't exist:
    - Create Lambda function: performance-scores-handler (Python 3.11)
    - GET /performance-scores → List scores with filters (department, period, employeeId)
    - GET /performance-scores/:employeeId/:period → Get single score
    - POST /performance-scores → Create score (Admin only)
    - PUT /performance-scores/:employeeId/:period → Update score (Admin only)
    - DELETE /performance-scores/:employeeId/:period → Delete score (Admin only)
    - Implement DynamoDB operations (query, get, put, update, delete)
    - Implement role-based authorization (extract role from JWT)
    - Implement filtering with GSI (department-period-index)
    - Join with Employees table to get employee name and details
  - Package Lambda with dependencies (boto3)
  - _Requirements: Performance score CRUD_

- [ ] 9.5 AWS Deployment - Performance score management Lambda
  - Deploy performance-scores-handler to ap-southeast-1
  - Create API Gateway endpoints:
    - GET /performance-scores (Cognito authorizer required)
    - GET /performance-scores/:employeeId/:period (Cognito authorizer required)
    - POST /performance-scores (Cognito authorizer required, Admin only)
    - PUT /performance-scores/:employeeId/:period (Cognito authorizer required, Admin only)
    - DELETE /performance-scores/:employeeId/:period (Cognito authorizer required, Admin only)
  - Configure CORS for all endpoints
  - Test endpoints with Postman/curl:
    - Test GET /performance-scores with filters
    - Test GET /performance-scores/:employeeId/:period
    - Test POST /performance-scores with valid score data
    - Test PUT /performance-scores/:employeeId/:period
    - Test DELETE /performance-scores/:employeeId/:period
  - Update aws-secret.md with Lambda ARN and API Gateway endpoints
  - _Requirements: Performance score CRUD_

- [ ] 9.6 Frontend - Switch to AWS endpoints and test
  - Update performanceScoreService to use real AWS API Gateway URLs (from .env)
  - Update .env with production API Gateway URL for performance score endpoints
  - Test performance score management with real DynamoDB data on localhost:
    - Login as Admin user
    - Navigate to /test/performance-scores
    - Verify calendar view loads scores from DynamoDB
    - Test clicking on cells to view details
    - Test editing scores
    - Test creating new scores
    - Test deleting scores
    - Test filtering by department and period
  - Verify role-based access control:
    - Test with Employee user (should see "Access Denied" for /test/performance-scores)
    - Test with Admin user (should see full performance score management UI)
  - Test with real employee data (300 employees × 3 quarters = 900 records)
  - Verify error handling with invalid data and network errors
  - _Requirements: Performance score CRUD, calendar view_

- [ ] 9.7 Build and deploy performance score management phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website performance score management features:
    - Login as Admin user
    - Access performance score management page
    - Test calendar view with real data
    - Test color coding (green/yellow/red)
    - Test clicking cells and viewing details
    - Test editing scores
    - Test creating new scores
    - Test filtering and search
  - Verify all performance score operations work on live site
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document deployment URL in aws-secret.md
  - _Requirements: Performance score CRUD, calendar view, deployment_

### Phase 6: Future Enhancements (Optional)

#### File Upload System (Optional)

- [ ] 10. AWS Infrastructure - Scan for existing upload infrastructure
  - Check if DataTables table exists in ap-southeast-1: `aws dynamodb describe-table --table-name DataTables --region ap-southeast-1`
  - If DataTables table exists:
    - Analyze table schema (PK, SK, GSIs, attributes)
    - Verify it has required fields: tableId, tableName, columns, data, uploadedBy, uploadedAt
    - If schema is correct, document in aws-secret.md and use existing table
    - If schema is broken/incomplete, decide: fix schema or create new table
  - If DataTables table doesn't exist:
    - Create table with schema: PK=tableId
  - Check if insighthr-uploads-sg S3 bucket exists and has proper CORS configuration
  - If bucket doesn't exist or CORS is broken, create/fix it
  - Update aws-secret.md with table and bucket details
  - _Requirements: 5.6_

- [ ] 10.1 Frontend - File upload UI
  - Implement UI feature at /upload
  - Create FileUpload types and interfaces
  - Create FileUploader component with drag-and-drop
  - Create ColumnMapper component
  - Display file headers with KPI dropdown mapping
  - Implement file type validation (CSV, Excel)
  - Implement file size validation (10,000+ records)
  - Use LoadingSpinner during upload
  - Style with Apple theme
  - Create test page at `/test/upload` for isolated testing
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 10.2 AWS Lambda - File upload handlers
  - Check if upload Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep upload`
  - If upload-presigned-url-handler Lambda exists:
    - Analyze Lambda configuration and test with sample event
    - Verify it generates valid S3 presigned URLs for insighthr-uploads-sg bucket
    - If working correctly, document and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If upload-presigned-url-handler doesn't exist:
    - Create Lambda function: upload-presigned-url-handler (Python 3.11)
    - POST /upload/presigned-url → Generate S3 presigned URL
    - Validate file type and size
  - If upload-process-handler Lambda exists:
    - Analyze Lambda configuration and test with sample event
    - Verify it can parse CSV/Excel and write to DataTables
    - If working correctly, document and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If upload-process-handler doesn't exist:
    - Create Lambda function: upload-process-handler (Python 3.11)
    - POST /upload/process → Process uploaded file
    - Parse CSV/Excel from S3
    - Detect table pattern or create new table
    - Insert data into DynamoDB DataTables
    - Trigger performance calculation if needed
  - Package Lambdas with dependencies (pandas, openpyxl, boto3)
  - Deploy upload-presigned-url-handler to ap-southeast-1
  - Deploy upload-process-handler to ap-southeast-1
  - Check if API Gateway endpoints exist for upload operations
  - If endpoints exist, verify they point to correct Lambdas and have proper CORS
  - If endpoints don't exist or are broken, create/fix them
  - Create API Gateway endpoints:
    - POST /upload/presigned-url (Cognito authorizer required)
    - POST /upload/process (Cognito authorizer required)
  - Configure CORS for all endpoints
  - Test file upload flow with real S3 using Postman/curl
  - Update aws-secret.md with Lambda ARNs and endpoints
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 10.3 Integration & Deploy - File upload
  - Create uploadService for API calls to AWS endpoints (presigned URL, file processing)
  - Update FileUploader components to use AWS API Gateway URLs
  - Test file upload to real S3 bucket on localhost
  - Test file processing with real Lambda
  - Test column mapping with real data
  - Verify validation works
  - Verify data appears in DynamoDB
  - Test end-to-end upload and mapping flow
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website file upload features
  - Verify file upload, column mapping, and data processing work on live site
  - Test with CSV and Excel files on live site
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 9.1_

#### Notification Rules (Optional)

- [ ] 11. AWS Infrastructure - Scan for existing notification infrastructure
  - Check if NotificationRules table exists in ap-southeast-1: `aws dynamodb describe-table --table-name NotificationRules --region ap-southeast-1`
  - Check if NotificationHistory table exists in ap-southeast-1: `aws dynamodb describe-table --table-name NotificationHistory --region ap-southeast-1`
  - If NotificationRules table exists:
    - Analyze table schema and verify required fields: ruleId, name, condition, recipients, emailTemplate, status
    - If correct, document and use existing table
    - If broken, fix or create new
  - If NotificationHistory table exists:
    - Analyze table schema and verify required fields: notificationId, sentAt, ruleId, recipients, status
    - If correct, document and use existing table
    - If broken, fix or create new
  - Check if SNS topic exists for email notifications: `aws sns list-topics --region ap-southeast-1`
  - If SNS topic doesn't exist, create it
  - Update aws-secret.md with table names, ARNs, and SNS topic ARN
  - _Requirements: 8.2, 8.5_

- [ ] 11.1 Frontend - Notification rules UI
  - Implement UI feature at /admin/notifications
  - Create Notification types and interfaces
  - Create NotificationRuleManager component
  - Create condition builder supporting simple and complex logic
  - Implement recipient selection (roles, departments, specific users)
  - Add enable/disable toggle for rules
  - Create email template configuration
  - Style with Apple theme
  - Create test page at `/test/notifications` for isolated testing
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 11.2 AWS Lambda - Notification handlers
  - Check if notification Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep notification`
  - If notifications-handler Lambda exists:
    - Analyze Lambda configuration and test with sample event
    - Verify it queries NotificationRules and NotificationHistory tables
    - If working correctly, document and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If notifications-handler doesn't exist:
    - Create Lambda function: notifications-handler (Python 3.11)
    - GET /notifications/rules → List notification rules
    - POST /notifications/rules → Create rule (Admin only)
    - PUT /notifications/rules/:ruleId → Update rule (Admin only)
    - GET /notifications/history → Get notification history
    - Implement role-based authorization
  - If notifications-trigger-handler Lambda exists:
    - Analyze Lambda configuration and test trigger mechanism
    - Verify it can evaluate rules and send emails via SNS
    - If working correctly, document and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If notifications-trigger-handler doesn't exist:
    - Create Lambda function: notifications-trigger-handler (Python 3.11)
    - Triggered by DynamoDB stream or EventBridge
    - Evaluate rules against performance data
    - Send emails via SNS
  - Package Lambdas with dependencies (boto3)
  - Deploy notifications-handler to ap-southeast-1
  - Deploy notifications-trigger-handler to ap-southeast-1
  - Check if API Gateway endpoints exist for notification operations
  - If endpoints exist, verify they point to correct Lambdas and have proper CORS
  - If endpoints don't exist or are broken, create/fix them
  - Create API Gateway endpoints:
    - GET /notifications/rules (Cognito authorizer required)
    - POST /notifications/rules (Cognito authorizer required, Admin only)
    - PUT /notifications/rules/:ruleId (Cognito authorizer required, Admin only)
    - GET /notifications/history (Cognito authorizer required)
  - Configure CORS for all endpoints
  - Set up DynamoDB stream trigger for notifications-trigger-handler
  - Test notification creation and triggering with Postman/curl
  - Update aws-secret.md with Lambda ARNs and endpoints
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 11.3 Integration & Deploy - Notification rules
  - Create notificationService for API calls to AWS endpoints
  - Update NotificationRuleManager to use AWS API Gateway URLs
  - Test notification rules with real DynamoDB on localhost
  - Test notification rule creation
  - Test condition builder
  - Test recipient selection
  - Test email sending via SNS
  - Verify notification history works
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website notification features
  - Verify notification rule creation and email sending work on live site
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1_

#### Chatbot Integration (Optional)

- [ ] 12. AWS Infrastructure - Scan for existing chatbot infrastructure
  - Check if Lex bot exists in ap-southeast-1: `aws lexv2-models list-bots --region ap-southeast-1`
  - If Lex bot exists:
    - Analyze bot configuration (intents, slots, fulfillment)
    - Test bot with sample queries
    - Verify it can query DynamoDB for HR data
    - If working correctly, document and use existing bot
    - If broken, decide: fix existing bot or create new one
  - If Lex bot doesn't exist:
    - Create Lex bot with intents for HR queries (performance, KPIs, employee info)
  - Check if Bedrock is configured for natural language understanding
  - Update aws-secret.md with Lex bot ID and configuration
  - _Requirements: 7.1, 7.3_

- [ ] 12.1 Frontend - Chatbot UI
  - Implement UI feature at /chatbot
  - Create ChatMessage and ChatSession types
  - Create ChatbotPage
  - Create ChatbotWidget component for dedicated tab
  - Create MessageList component (no history persistence)
  - Create MessageInput component
  - Create ChatbotInstructions component with usage guide
  - Implement one-off query mode (no session history)
  - Style with Apple theme
  - Create test page at `/test/chatbot` for isolated testing
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 12.2 AWS Lambda - Chatbot handler
  - Check if chatbot Lambda functions exist in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep chatbot`
  - If chatbot-handler Lambda exists:
    - Analyze Lambda configuration and test with sample event
    - Verify it can communicate with Lex/Bedrock and query DynamoDB
    - If working correctly, document and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If chatbot-handler doesn't exist:
    - Create Lambda function: chatbot-handler (Python 3.11)
    - POST /chatbot/message → Send message to Lex/Bedrock
    - Query DynamoDB for relevant data (performance, KPIs, employees)
    - Return formatted response
  - Package Lambda with dependencies (boto3)
  - Deploy chatbot-handler to ap-southeast-1
  - Check if API Gateway endpoint exists for chatbot
  - If endpoint exists, verify it points to correct Lambda and has proper CORS
  - If endpoint doesn't exist or is broken, create/fix it
  - Create API Gateway endpoint:
    - POST /chatbot/message (Cognito authorizer required)
  - Configure CORS for endpoint
  - Test chatbot queries with Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoint
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 12.3 Integration & Deploy - Chatbot
  - Create chatbotService for API calls to AWS endpoints
  - Update ChatbotWidget to use AWS API Gateway URLs
  - Test chatbot with real Lex/Bedrock integration on localhost
  - Test chatbot interactions
  - Verify message sending and receiving works
  - Verify data queries work with real DynamoDB
  - Test various HR-related queries
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website chatbot features
  - Verify chatbot queries and responses work on live site
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1_

### Phase 7: Page Integration

- [ ] 13. Admin page integration
  - Verify all admin features are accessible from AdminPage
  - Test navigation between sections
  - Verify Employee Management page works
  - Verify Performance Score Management page works
  - Verify User Management page works
  - Test all features together
  - _Requirements: Admin interface organization_

- [ ] 14. Dashboard page integration
  - Verify DashboardPage component works
  - Verify PerformanceDashboard component integration
  - Verify FilterPanel component integration
  - Verify all chart components integration
  - Verify ExportButton component integration
  - Test dashboard with real data
  - _Requirements: 6.1, 6.2, 6.5_

### Phase 8: Polish and Deployment

- [ ] 16. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - Test all error scenarios
  - _Requirements: 10.5, 10.6_

- [ ] 17. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Apple theme across all pages
  - Implement loading states for all async operations
  - Add visual feedback for user actions
  - Test on different screen sizes
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 18. Testing and bug fixes
  - Test authentication flow (login, register, Google OAuth, logout)
  - Test employee management (create, edit, delete, bulk import)
  - Test performance score management (calendar view, CRUD operations)
  - Test user management (manual and bulk creation, employee selector)
  - Test password reset flow
  - Test dashboard (charts, filters, export)
  - Test chatbot (data queries)
  - Test notification rules
  - Test role-based access control
  - Fix identified bugs
  - _Requirements: All_

- [ ] 19. CloudFront setup and final production deployment
  - Check if CloudFront distribution exists
  - If not exists, create CloudFront distribution:
    - Origin: S3 web-app bucket (insighthr-web-app-sg)
    - Enable HTTPS with ACM certificate (optional for MVP)
    - Configure custom error responses (404 → index.html for SPA routing)
    - Set cache behaviors for optimal performance
    - Configure origin access identity for S3
  - Build final production bundle with Vite
  - Test production build locally with `npm run preview`
  - Deploy to S3 bucket: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1 --delete`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Create automated deployment script (deploy.ps1 or deploy.sh)
  - Test complete application on CloudFront URL
  - Verify all features work end-to-end on production
  - Document deployment process in README.md
  - Update aws-secret.md with CloudFront URL and distribution ID
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

---

## Notes

### Development Approach

**Task Order for Each Major Function:**
1. **Create static frontend framework** - Build UI components with full styling
2. **Create stub function** - Build fully working local stub API (Express.js server)
3. **Test with stub API** - Verify functionality works on localhost with stub
4. **Create AWS infrastructure** - Set up Lambda, DynamoDB, API Gateway in ap-southeast-1
5. **Deploy backend to cloud** - Deploy Lambda functions and connect to API Gateway
6. **Test localhost with AWS** - Test localhost frontend calling real AWS API endpoints
7. **Deploy frontend to S3** - Build and deploy static site to S3
8. **Test live deployment** - Verify end-to-end functionality on deployed website

**Local Development & Testing:**
- **Test environment**: All test/demo pages accessible at `localhost:5173/test/*`
- **Test folder structure**: Separate `/test` folder for demo components
- **Test routes**: 
  - `localhost:5173/test/login` - Test authentication
  - `localhost:5173/test/kpi` - Test KPI management
  - `localhost:5173/test/dashboard` - Test dashboard
  - etc.
- **Stub API**: Local Express.js server on `localhost:4000` mimicking AWS Lambda responses
- **Production routes**: Main app at `localhost:5173/*` (no /test prefix)
- **Deployment testing**: After each major phase, deploy to S3 and test live site

**Deployment Strategy:**
- **Incremental deployment**: Deploy to S3 after completing each major feature phase
- **S3 bucket**: insighthr-web-app-sg (static website hosting enabled)
- **Build command**: `npm run build` (creates dist/ folder)
- **Deploy command**: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
- **CloudFront**: Optional for MVP, set up in final phase for CDN and HTTPS
- **CORS**: API Gateway must allow requests from both localhost and S3/CloudFront URLs
- **Testing sequence**: localhost with stub → localhost with AWS → live site with AWS

**AWS Infrastructure:**
- **Check before create**: Always scan for existing AWS resources before creating new ones
- **Region consistency**: All resources must be in ap-southeast-1 (Singapore)
- **Resource naming**: Use consistent naming pattern: `insighthr-{service}-{env}`
- **Documentation**: Update aws-secret.md after creating/updating any AWS resource
- **Testing**: Test each Lambda function with Postman/curl before frontend integration

**Frontend Development:**
- **Component library**: Use shadcn/ui and React Hook Form (optimized for S3 deployment)
- **Chart library**: Use Recharts (optimized for S3 deployment)
- **Styling**: Apply Apple theme from the start, fully style as you build
- **Testing**: Test each component first with stub API, then with real AWS endpoints
- **Git workflow**: Feature branches (`feat-[task-name]`), commit after task confirmation
- **TypeScript**: Non-strict mode for rapid development
- **AWS credentials**: Stored in aws-secret.md (added to .gitignore)

**Backend Development:**
- **Stub API**: Express.js server with in-memory data for local testing
- **Lambda runtime**: Python 3.11
- **DynamoDB**: Use consistent table naming and GSI patterns
- **API Gateway**: RESTful endpoints with Cognito authorizer
- **Error handling**: Return consistent error format from all Lambdas
- **Logging**: Use CloudWatch Logs for debugging

### MVP Constraints

- Each task should be completed and tested before moving to the next
- Focus on desktop experience (1366x768 and above)
- All data validation handled by Lambda (minimal frontend validation)
- Backdoor admin account must be configured in Cognito
- Chatbot shows instructions, no suggested queries
- No empty state designs - show blank/nothing when no data
- Keep existing codebase - only add/modify as needed
- **User Registration**: Auto-approve all new registrations (no manual approval required for MVP)

### Future Enhancements (Post-MVP)

The following features are documented for future implementation but not included in the current MVP:

1. **Admin Approval Workflow for User Registration**
   - Pending users table in DynamoDB
   - Admin UI to view and approve/reject pending registrations
   - Email notifications for approval status
   - Approval history and audit trail
   - Bulk approval actions

2. **Email Verification for Self-Registration**
   - Cognito email verification flow
   - Verification code input UI
   - Resend verification email functionality

### AWS Resource Checklist

**Core resources (MVP) - Verify these exist in ap-southeast-1:**
- [ ] DynamoDB tables (5 core tables):
  - Users table
  - Employees table (insighthr-employees-dev)
  - PerformanceScores table (insighthr-performance-scores-dev)
  - PasswordResetRequests table
  - NotificationHistory table (for password reset notifications)
- [ ] S3 buckets (2 buckets):
  - insighthr-uploads-sg (for file uploads)
  - insighthr-web-app-sg (for static website hosting)
- [ ] Cognito User Pool with app client
- [ ] API Gateway REST API
- [ ] Lambda execution IAM role
- [ ] CloudFront distribution (for production)

**Optional resources (Future Enhancements):**
- [ ] DataTables table (for file upload system)
- [ ] NotificationRules table (for notification system)
- [ ] Lex bot (for chatbot)
- [ ] SNS topic (for email notifications)

### Build Order

**Phase 0: AWS Foundation** (Tasks 0.1-0.6)
1. Verify/update region configuration
2. Set up DynamoDB tables
3. Set up S3 buckets
4. Set up Cognito User Pool
5. Set up API Gateway
6. Set up IAM roles

**Phase 1-2: Authentication** (Tasks 1-5.8)
1. Keep existing project setup
2. Create auth Lambda functions
3. Integrate Cognito in frontend
4. Build login/register UI
5. Test authentication flow
6. Set up CloudFront
7. Implement Google OAuth

**Phase 3: User Management** (Tasks 6-6.8)
1. User profile (view/edit)
2. Admin user CRUD operations
3. Bulk user import
4. Deploy to S3

**Phase 4: Performance Dashboard** (Tasks 7-7.3.1) - MOVED UP
1. Scan for existing employee/performance tables
2. Build dashboard UI with charts
3. Implement filtering and export
4. Deploy to S3

**Phase 5: Employee Management** (Tasks 8-8.9)
1. Verify Employees table exists
2. Build employee management UI (list, create, edit, delete)
3. Implement bulk import from CSV
4. Import employee data from employee_quarterly_scores_2025.csv
5. Update User Management to use employee selector
6. Deploy to S3

**Phase 6: Performance Score Management** (Tasks 9-9.7)
1. Verify PerformanceScores table exists
2. Build calendar view UI (week/month/quarter)
3. Implement color-coded score display (green/yellow/red)
4. Implement score CRUD operations
5. Deploy to S3

**Phase 7: Page Integration & UI Updates** (Tasks 13-13.1)
1. Update AdminPage navigation (remove old, add new items)
2. Update password reset UI message
3. Test all admin features together

**Phase 8: Polish and Deployment** (Tasks 16-19)
1. Error handling and validation
2. Responsive design
3. Testing
4. Final CloudFront deployment

**Phase 9: Future Enhancements (Optional)** (Tasks 10-12)
1. File Upload System (optional)
2. Notification Rules (optional)
3. Chatbot Integration (optional)

### Lambda Function List

**Core Lambda functions (MVP):**
1. auth-login-handler
2. auth-register-handler
3. auth-google-handler
4. password-reset-handler
5. users-handler
6. users-bulk-handler
7. employees-handler
8. employees-bulk-handler
9. performance-handler
10. performance-scores-handler

**Optional Lambda functions (Future Enhancements):**
11. upload-presigned-url-handler (optional)
12. upload-process-handler (optional)
13. notifications-handler (optional)
14. notifications-trigger-handler (optional)
15. chatbot-handler (optional)

### API Gateway Endpoints

**Core endpoints (MVP) - All under `/dev` stage:**

**Authentication:**
- POST /auth/login
- POST /auth/register
- POST /auth/google
- POST /auth/refresh
- POST /auth/request-reset
- GET /users/password-requests
- POST /users/password-requests/:requestId/approve
- POST /users/password-requests/:requestId/deny

**User Management:**
- GET /users/me
- PUT /users/me
- GET /users
- POST /users
- POST /users/bulk
- PUT /users/:userId
- PUT /users/:userId/disable
- PUT /users/:userId/enable
- DELETE /users/:userId

**Employee Management:**
- GET /employees
- GET /employees/:employeeId
- POST /employees
- PUT /employees/:employeeId
- DELETE /employees/:employeeId
- POST /employees/bulk

**Performance Dashboard:**
- GET /performance
- GET /performance/:employeeId
- POST /performance/export

**Performance Score Management:**
- GET /performance-scores
- GET /performance-scores/:employeeId/:period
- POST /performance-scores
- PUT /performance-scores/:employeeId/:period
- DELETE /performance-scores/:employeeId/:period

**Optional endpoints (Future Enhancements):**
- POST /upload/presigned-url (optional)
- POST /upload/process (optional)
- GET /notifications/rules (optional)
- POST /notifications/rules (optional)
- PUT /notifications/rules/:ruleId (optional)
- GET /notifications/history (optional)
- POST /chatbot/message (optional)

