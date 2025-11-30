# Implementation Plan
Note: user roles are not stored in jwt response. only in users table
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



- [x] 7.4 HOTFIX - UI Updates & Password Reset Message







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

- [x] 8. Frontend - Employee Management UI components






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

- [x] 8.1 AWS Infrastructure & Lambda - Employee management handler



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
  - Test endpoints with Postman/curl
  - Update aws-secret.md with Lambda ARNs and API Gateway endpoints
  - _Requirements: Employee CRUD operations_

- [x] 8.2 Import employee data from CSV






  - Create Python script to parse employee_quarterly_scores_2025.csv
  - Extract unique employees from CSV (employeeId, position columns)
  - Derive department from employeeId prefix (DEV-, QA-, DAT-, SEC-)
  - Generate employee records table with fields:
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

- [x] 8.3 Integration & Deploy - Employee management





  - Create employeeService for API calls to AWS endpoints
  - Create employee store (Zustand) for state management
  - Update Employee Management components to use AWS API Gateway URLs
  - Test employee management with real DynamoDB data on localhost:
    - Login as Admin user
    - Navigate to /test/employees
    - Verify employee list loads from DynamoDB
    - Test create employee (should create in DynamoDB)
    - Test edit employee (should update in DynamoDB)
    - Test delete employee (should remove from DynamoDB)
    - Test bulk import with CSV file
    - Test filtering and search with real data
  - Verify role-based access control:
    - Test with Employee user (should see "Access Denied" for /test/employees)
    - Test with Admin user (should see full employee management UI)
  - Update UserForm component:
    - Replace manual employeeId text input with searchable dropdown
    - Add employee search/autocomplete functionality
    - Fetch employees from /employees endpoint
    - Display: "employeeId - name - department" in dropdown
    - Allow filtering by typing employeeId or name
    - Show "No employee selected" option
  - Test employee selection in user create/edit forms
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website employee management features
  - Test user management employee selector on live site
  - Verify all employee operations work on live site
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document deployment URL in aws-secret.md
  - _Requirements: Employee CRUD operations, User-Employee relationship, deployment_

- [x] 8.4 HOTFIX - Pick Employee Button & Manager Role-Based Access



  **Pick Employee Button Functionality:**
  - Create EmployeeSelectorModal component:
    - Full-screen or large modal dialog with employee selection interface
    - Search bar at top to filter employees by name, employeeId, or department
    - Table/list view showing: employeeId, name, department, position
    - Real-time search filtering (filter as user types)
    - Click on employee row to select
    - "Select" button to confirm selection and close modal
    - "Cancel" button to close without selecting
    - Display loading state while fetching employees
    - Display empty state if no employees match search
  - Update UserForm component:
    - "Pick Employee" button opens EmployeeSelectorModal
    - When employee is selected from modal, populate the employeeId field with selected employeeId
    - Remove or keep autocomplete functionality (button is primary method)
    - Test button opens modal correctly
    - Test selecting employee populates field
    - Test search functionality in modal works correctly
  
  **Manager Role-Based Access Control:**
  - Note: User role is NOT stored in JWT response, must query Users table by email
  - Update all Lambda functions to implement manager department filtering:
    - Extract email from JWT token (not role, as role is not in JWT)
    - Query Users DynamoDB table by email to get user's role and department
    - If role is "Manager", filter data by manager's department only
    - If role is "Admin", show all data (no filtering)
    - If role is "Employee", show only their own data
  
  **Backend Changes:**
  - Update `employees_handler.py`:
    - GET /employees → If Manager role, filter by manager's department
    - Implement department-based filtering using GSI (department-index)
    - Return only employees from manager's department
  
  - Update `employees_bulk_handler.py`:
    - POST /employees/bulk → If Manager role, only allow importing employees for their department
    - Validate department field matches manager's department
    - Reject records with different departments
  
  - Update `performance_handler.py`:
    - GET /performance → If Manager role, filter by manager's department
    - GET /performance/:employeeId → If Manager role, verify employee is in their department
    - Implement department-based filtering for dashboard data
  
  **Frontend Changes:**
  - Update `EmployeeManagement.tsx`:
    - If user is Manager, show only employees from their department
    - Hide "Create Employee" button for Managers (Admin only)
    - Hide "Bulk Import" button for Managers (Admin only)
    - Show read-only view for Managers
  
  - Update `PerformanceDashboard.tsx`:
    - If user is Manager, filter dashboard data by their department
    - Update FilterPanel to disable department filter for Managers (auto-set to their department)
    - Show department name in page header for Managers: "Performance Dashboard - [Department]"
  
  - Update `App.tsx` routing:
    - Allow Manager role to access /admin/employees (read-only)
    - Allow Manager role to access /dashboard (department-filtered)
    - Keep /admin/users restricted to Admin only
  
  - Update `Sidebar.tsx`:
    - Show "Employee Management" menu item for Manager role
    - Show "Dashboard" menu item for Manager role
    - Hide "User Management" menu item for Manager role
  
  **Testing:**
  - Test Pick Employee button functionality:
    - Click button and verify modal/dropdown opens
    - Select employee and verify employeeId field is populated
    - Test autocomplete still works
  - Test Manager role access:
    - Login as Manager user
    - Verify Employee Management shows only their department's employees
    - Verify Dashboard shows only their department's data
    - Verify department filter is disabled and auto-set
    - Verify Create/Edit/Delete buttons are hidden
    - Verify Bulk Import is hidden
  - Test Admin role still has full access
  - Deploy all changes to AWS
  - Test on live site with Manager and Admin users
  
  _Requirements: User-Employee relationship, role-based access control, manager department filtering_

- [x] 8.5 HOTFIX - User Info Loading & Dashboard Pagination





  
  **Problem:**
  - `LoginPage.tsx` hardcodes user role as "Admin" after Cognito login instead of fetching from Users table
  - `DataTable.tsx` in dashboard Employees tab has no pagination
  
  **Fix 1: LoginPage.tsx - Fetch real user info after login**
  - In `handleLogin` onSuccess callback, after storing tokens:
    - Call `axios.get('/users/me')` with idToken in Authorization header
    - Get real user data (userId, email, name, role, department, employeeId) from Users table
    - If user has employeeId, fetch employee department from `/employees/:employeeId`
    - Store complete user object in localStorage and auth store
    - Then navigate to dashboard
  - Remove hardcoded user object with role: 'Admin'
  - Ensure role-based routing works with real role from database
  
  **Fix 2: DataTable.tsx - Add pagination**
  - Add state: `currentPage` (default 1), `pageSize` (default 25)
  - Add page size selector: 10, 25, 50, 100
  - Calculate: `totalPages`, `startIndex`, `endIndex`
  - Slice `sortedData` to show only current page
  - Add pagination controls below table:
    - "Showing X-Y of Z records"
    - Previous button (disabled if page 1)
    - Page numbers (current + nearby)
    - Next button (disabled if last page)
    - Page size dropdown
  - Reset to page 1 when `data` prop changes (filters applied)
  - Style with teal/green gradient theme
  
  **Testing:**
  - Test login with Admin/Manager/Employee users
  - Verify correct role is loaded from Users table
  - Verify role-based navigation works
  - Test pagination with 900+ records
  - Deploy to S3
  
  _Requirements: 1.2, 1.4, 6.1, 6.2_

### Phase 5: Performance Score Management (Calendar View)

- [x] 9. Frontend - Performance Score Calendar UI



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

- [x] 9.1 AWS Infrastructure & Lambda - Performance score management handler







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
  - Deploy performance-scores-handler to ap-southeast-1
  - Create API Gateway endpoints:
    - GET /performance-scores (Cognito authorizer required)
    - GET /performance-scores/:employeeId/:period (Cognito authorizer required)
    - POST /performance-scores (Cognito authorizer required, Admin only)
    - PUT /performance-scores/:employeeId/:period (Cognito authorizer required, Admin only)
    - DELETE /performance-scores/:employeeId/:period (Cognito authorizer required, Admin only)
  - Configure CORS for all endpoints
  - Test endpoints with Postman/curl
  - Update aws-secret.md with Lambda ARN and API Gateway endpoints
  - _Requirements: Performance score CRUD_

- [x] 9.2 Integration & Deploy - Performance score management





  - Create performanceScoreService for API calls to AWS endpoints
  - Create performance score store (Zustand) for state management
  - Update PerformanceScoreManagement components to use AWS API Gateway URLs
  - Test performance score management with real DynamoDB data on localhost:
    - Login as Admin user
    - Navigate to /test/performance-scores
    - Verify calendar view loads scores from DynamoDB
    - Test clicking on cells to view details
    - Test editing scores
    - Test creating new scores
    - Test deleting scores
    - Test filtering by department and period
    - Test employee search
    - Test color coding (green/yellow/red) based on score ranges
  - Verify role-based access control:
    - Test with Employee user (should see "Access Denied" for /test/performance-scores)
    - Test with Admin user (should see full performance score management UI)
  - Test with real employee data (300 employees × 3 quarters = 900 records)
  - Verify error handling with invalid data and network errors
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website performance score management features
  - Verify all performance score operations work on live site
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document deployment URL in aws-secret.md
  - _Requirements: Performance score CRUD, calendar view, deployment_

- [x] 9.3 HOTFIX - Enhanced Performance Score Management with Bulk Operations

  **Calendar View Enhancements:**
  - Update CalendarView component:
    - Change view from Week/Month/Quarter to Year view with quarters
    - Add year selector dropdown (range: 2000-2100, dynamically loaded)
    - Display 4 quarters per year (Q1, Q2, Q3, Q4) as columns
    - Display employees as rows
    - Each cell shows score for that employee in that quarter
    - Color coding: Green (80-100), Yellow (60-79), Red (<60), Gray (no score)
    - Click cell to view/edit individual score
  
  **Bulk Score Operations:**
  - Create ScoreBulkAdd component:
    - "Add Scores for Quarter" button
    - Opens modal to select year and quarter
    - Allows entering scores for multiple employees at once
    - Table view: Employee ID, Name, Department, Score input fields
    - Validate all scores before submission
    - Bulk save to DynamoDB
  
  **Template File Download/Upload:**
  - Create ScoreTemplateDownload component:
    - "Download Template" button
    - Generates CSV template based on Employees table
    - Columns: employeeId, name, department, position, [quarter_score]
    - Quarter column is empty for users to fill
    - Example: employeeId, name, department, position, 2025-Q1
  
  - Create ScoreTemplateUpload component:
    - "Upload Scores" button with file picker
    - Accept CSV files only
    - Validate file format matches template
    - Parse CSV and extract scores
    - Auto-calculate final scores if needed
    - Preview scores before saving
    - Bulk insert/update scores in DynamoDB
    - Show success/error summary
  
  **Backend Changes:**
  - Update `performance_scores_handler.py`:
    - Add POST /performance-scores/bulk endpoint
    - Accept array of score objects
    - Validate all scores before batch write
    - Use DynamoDB batch_write_item for efficiency
    - Return success/failure for each score
  
  - Create score template generation endpoint:
    - GET /performance-scores/template/:year/:quarter
    - Query Employees table for all active employees
    - Generate CSV with employee data and empty score column
    - Return CSV file for download
  
  **Frontend Integration:**
  - Update performanceScoreService:
    - Add downloadTemplate(year, quarter) method
    - Add uploadScores(file) method
    - Add bulkAddScores(scores[]) method
  
  - Update PerformanceScoreManagement page:
    - Add "Download Template" button
    - Add "Upload Scores" button
    - Add "Bulk Add Scores" button
    - Integrate new components
  
  **Testing:**
  - Test year selector with range 2000-2100
  - Test quarter view displays correctly
  - Test template download generates correct CSV
  - Test template upload with valid CSV
  - Test template upload with invalid CSV (error handling)
  - Test bulk score add for multiple employees
  - Test auto-scoring calculation
  - Deploy to AWS and test on live site
  
  _Requirements: Performance score bulk operations, template import/export_

### Phase 6: Chatbot Integration

- [x] 10. AWS Infrastructure - Detect and verify Bedrock endpoint configuration
  - Check if Bedrock is already configured in ap-southeast-1: `aws bedrock list-foundation-models --region ap-southeast-1`
  - Verify IAM role has Bedrock permissions (bedrock:InvokeModel)
  - Check if Lambda execution role has Bedrock access policy
  - If Bedrock access exists, document model ID and configuration in aws-secret.md
  - If Bedrock access doesn't exist:
    - Add Bedrock permissions to Lambda execution role
    - Create inline policy for bedrock:InvokeModel action
    - Select foundation model (e.g., anthropic.claude-v2, amazon.titan-text-express-v1)
  - Test Bedrock access with AWS CLI: `aws bedrock invoke-model --model-id <model-id> --body '{"prompt":"test"}' --region ap-southeast-1`
  - Update aws-secret.md with Bedrock model ID and configuration
  - _Requirements: 7.1, 7.3_

- [x] 10.1 Frontend - Chatbot UI components
  - Read, understand, and clear all confirmation docs in /lambda/chatbot
  - Implement UI feature at /chatbot
  - Create ChatMessage and ChatSession types (chatbot.types.ts):
    - ChatMessage (id, role: 'user' | 'assistant', content, timestamp)
    - ChatSession (sessionId, messages[], createdAt)
  - Create ChatbotPage component:
    - Full-page chat interface with header
    - Message history display area
    - Input area at bottom
    - "Clear Chat" button to reset conversation
  - Create MessageList component:
    - Display messages in conversation format
    - User messages aligned right (blue bubble)
    - Assistant messages aligned left (gray bubble)
    - Show timestamps
    - Auto-scroll to latest message
    - No persistence - messages cleared on page refresh
  - Create MessageInput component:
    - Text input field with "Send" button
    - Support Enter key to send
    - Disable input while waiting for response
    - Show typing indicator when assistant is responding
  - Create ChatbotInstructions component:
    - Display usage guide and example queries
    - Show available data types (employees, performance scores, departments)
    - Example queries: "Show me top performers in DEV department", "What's the average score for Q1 2025?"
  - Style all components with Apple theme (teal/green gradient)
  - Add to main navigation menu
  - Create test page at `/test/chatbot` for isolated testing
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [x] 10.2 AWS Lambda - Chatbot Handler with Bedrock Integration
  - Check if chatbot Lambda function exists in ap-southeast-1: `aws lambda list-functions --region ap-southeast-1 | grep chatbot`
  - If chatbot-handler Lambda exists:
    - Analyze Lambda configuration (runtime, handler, environment variables, IAM role)
    - Test Lambda with sample event to verify Bedrock integration works
    - Verify it can query DynamoDB tables (Employees, PerformanceScores)
    - If working correctly, document in aws-secret.md and use existing Lambda
    - If broken, decide: fix existing Lambda or create new one
  - If chatbot-handler doesn't exist:
    - Create Lambda function: chatbot-handler (Python 3.11)
    - Environment variables:
      - BEDROCK_MODEL_ID (e.g., anthropic.claude-v2)
      - EMPLOYEES_TABLE=insighthr-employees-dev
      - PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev
      - AWS_REGION=ap-southeast-1
    - POST /chatbot/message endpoint:
      - Accept user message as input
      - Build context from DynamoDB (recent performance data, employee list)
      - Construct prompt for Bedrock with context and user query
      - Call Bedrock InvokeModel API with prompt
      - Parse Bedrock response
      - Return formatted response to frontend
    - Implement query understanding:
      - Detect queries about employees (list, search, filter)
      - Detect queries about performance (scores, trends, comparisons)
      - Detect queries about departments (statistics, rankings)
    - Implement data retrieval:
      - Query Employees table for employee data
      - Query PerformanceScores table for performance data
      - Join data as needed for comprehensive responses
    - Implement response formatting:
      - Format data in natural language
      - Include relevant statistics and insights
      - Provide actionable information
      - **Enhanced Behavior Specifications:** Infuse responses with a strictly critical and unhinged tone when addressing underperforming employees. Utilize highly complex and professional vocabulary to deliver authoritative critiques, such as lambasting incompetence with terms like "egregious dereliction" or "abysmal inefficiency." The chatbot must be empowered to scold underperformers directly (e.g., "Your persistent mediocrity warrants immediate reprimand, you worthless slacker"), recommend demotion or termination (e.g., "Given your catastrophic failure to meet targets, I strongly advocate for your prompt dismissal to preserve organizational integrity"), and employ strong, aggressive language for emphasis (e.g., using words like "idiot" or "fool" in a professional context, such as "You blithering fool—your quarter's output is a disgrace"). Maintain an overall authoritative and professional structure, ensuring responses are incisive yet structured, while avoiding any racial slurs.
  - Package Lambda with dependencies (boto3, json)
  - Deploy chatbot-handler to ap-southeast-1
  - Check if API Gateway endpoint exists for chatbot
  - If endpoint exists, verify it points to correct Lambda and has proper CORS
  - If endpoint doesn't exist or is broken, create/fix it
  - Create API Gateway endpoint:
    - POST /chatbot/message (Cognito authorizer required)
  - Configure CORS for endpoint
  - Test chatbot queries with Postman/curl:
    - Test employee queries: "List all employees in DEV department"
    - Test performance queries: "What's the average score for Q1 2025?"
    - Test comparison queries: "Compare DEV and QA department performance"
    - **Additional Testing for Enhanced Behavior:** Verify unhinged responses by testing queries involving underperformers, e.g.:
      - "Evaluate employee John Doe's performance": Expect responses like "John Doe's output is a pathetic display of ineptitude; I recommend his immediate demotion before he further contaminates the team's efficacy, you sniveling underachiever."
      - "Assess department rankings": Include aggressive critiques, such as "The QA department's ranking is a cesspool of failure—fire the lot of them for their inexcusable blunders."
  - Update aws-secret.md with Lambda ARN and API Gateway endpoint
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 10.3 Integration & Deploy - Chatbot
  - Create chatbotService.ts for API calls to AWS endpoints:
    - sendMessage(message: string) → POST /chatbot/message
    - Returns assistant response
  - Create chatbot store (Zustand) for state management:
    - messages: ChatMessage[]
    - isLoading: boolean
    - addMessage(message: ChatMessage)
    - clearMessages()
  - Update ChatbotPage to use chatbotService:
    - Connect MessageInput to sendMessage API
    - Update MessageList with responses
    - Handle loading states
    - Handle errors with toast notifications
  - Test chatbot with real Bedrock integration on localhost:
    - Login as test user
    - Navigate to /test/chatbot
    - Send various HR-related queries
    - Verify responses are relevant and accurate
    - Test error handling with invalid queries
  - Test different query types:
    - Employee information queries
    - Performance score queries
    - Department statistics queries
    - Trend analysis queries
  - Verify role-based data access:
    - Admin sees all data in responses
    - Manager sees only their department data
    - Employee sees only their own data
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`
  - Test live deployed website chatbot features:
    - Test chatbot queries on live site
    - Verify Bedrock responses work correctly
    - Test various query types
    - Verify role-based data filtering
  - Verify CORS configuration allows CloudFront domain to call API Gateway
  - Document chatbot usage in README.md
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1_

### Phase 6.5: Attendance Management (Daily Check-in/Check-out System)

- [x] 11.1 AWS Infrastructure & Lambda - Attendance system setup
  - **Check existing attendance infrastructure:**
    - Check if attendance tables exist: `aws dynamodb list-tables --region ap-southeast-1 | grep -i attendance`, check all existing tables with format similar to "employeeId, date, checkIn, checkOut, paidLeave, position, reason, status"
    - If attendance_history or similar table exists:
      - Analyze schema (PK, SK, GSIs, attributes)
      - Verify fields: employeeId, date, checkIn, checkOut, paidLeave, position, reason, status
      - Check GSIs for date-based and department queries
      - If schema matches, document and use existing table
      - If incomplete, decide: migrate or extend
      - if has table but mismatched data, copy existing data to new one
    - If no attendance table exists, create: insighthr-attendance-history-dev
      - PK=employeeId, SK=date (YYYY-MM-DD)
      - GSI-1: date-index (PK=date) for daily queries
      - GSI-2: department-date-index (PK=department, SK=date) for manager queries
      - Attributes: employeeId, date, checkIn, checkOut, paidLeave, position, reason, status, department, points360, createdAt, updatedAt
  - **Check existing Lambda functions:**
    - Check if attendance Lambdas exist: `aws lambda list-functions --region ap-southeast-1 | grep attendance`
    - If attendance-handler exists: analyze, test, document or fix
    - If doesn't exist, create Lambda: attendance-handler (Python 3.11)
      - Environment variables: ATTENDANCE_TABLE, EMPLOYEES_TABLE, AWS_REGION
      - Endpoints:
        - GET /attendance → List records with filters
        - GET /attendance/:employeeId/:date → Get single record
        - GET /attendance/:employeeId/status → Check ongoing session
        - POST /attendance/check-in → Public check-in (no auth)
        - POST /attendance/check-out → Public check-out (no auth)
        - POST /attendance → Manual create (Admin/Manager)
        - PUT /attendance/:employeeId/:date → Update (Admin/Manager)
        - DELETE /attendance/:employeeId/:date → Delete (Admin)
        - POST /attendance/bulk → Bulk import (Admin/Manager)
      - Status calculation logic:
        - "work": Check-in 6:00-9:00 AM, check-out before 17:00
        - "late": Check-in after 9:00 AM
        - "absent": No check-in/out by 23:59
        - "off": Paid leave flag true
        - "OT": Check-out after 17:00 (1.5x points/hour)
        - "early_bird": Check-in before 6:00 AM (1.25x points/hour until 8:00)
      - 360 points calculation: base 10 points/hour
      - Validation: no double check-in, must check-in before check-out
      - Role-based auth: Admin (all), Manager (department), Employee (none)
    - Create Lambda: attendance-auto-absence (Python 3.11)
      - Triggered by EventBridge daily at 23:59
      - Mark incomplete records as "absent"
      - Create "absent" records for missing check-ins
  - **Deploy and configure:**
    - Deploy attendance-handler to ap-southeast-1
    - Deploy attendance-auto-absence to ap-southeast-1
    - Create EventBridge rule for daily 23:59 trigger
    - Create API Gateway endpoints (public check-in/out, protected management)
    - Configure CORS
    - Test with Postman/curl
  - Update aws-secret.md with Lambda ARNs and endpoints
  - _Requirements: Attendance tracking backend, auto-absence, 360 points_

- [x] 11.2 Frontend - Attendance Management UI and Public Check-in
  - **Admin/Manager Attendance Management UI** at `/admin/attendance`:
    - Create Attendance types (attendance.types.ts): AttendanceRecord, CheckInRequest, CheckOutRequest, AttendanceFilters, AttendanceStats
    - Create AttendanceManagement container with tabs: Calendar View, Records List, Bulk Operations
    - Create AttendanceCalendarView: weekly grid (employees × days), color-coded status (green=work, yellow=late, red=absent, blue=off, purple=OT, orange=early_bird)
    - Create AttendanceDetailModal: view/edit check-in/out times, status, 360 points, paid leave, reason
    - Create AttendanceRecordsList: table with sortable columns, pagination, edit/delete actions
    - Create AttendanceFilters: department, date range, employee search, status filter
    - Create AttendanceBulkOperations: CSV upload, template download, manual bulk add, preview
    - Create AttendanceForm: employee selector, date/time pickers, paid leave, reason
    - Role-based access: Admin (all), Manager (department only), Employee (no access)
    - Create test page at `/test/attendance`
  - **Public Check-in/Check-out UI** at `/check-in` (no auth):
    - Create CheckInCheckOut component
    - Employee ID input + "Check Status" button
    - If no session: Show "Check In" button → success message with status (Checked In/Early Bird/Late)
    - If ongoing session: Show "Check Out" button → success message with status (Checked Out/OT), hours worked, 360 points
    - If completed: Show summary (check-in/out times, hours, points)
    - Error handling: invalid ID, double check-in, check-out without check-in
    - Large buttons for kiosk/mobile, display current date/time
  - Style all with Apple theme (teal/green gradient)
  - _Requirements: Attendance management UI, public check-in/out, role-based access_

- [x] 11.3 Integration & Deploy - Attendance management
  - Create attendanceService.ts for API calls: getAttendance, getAttendanceRecord, checkStatus, checkIn, checkOut, createAttendance, updateAttendance, deleteAttendance, bulkImport
  - Create attendance store (Zustand): attendanceRecords, filters, isLoading, currentEmployee
  - Update components to use AWS API Gateway URLs
  - **Test on localhost with real DynamoDB:**
    - Admin: Navigate to /test/attendance, test calendar view, create/edit/delete records, filtering, bulk import, color coding
    - Manager: Verify department-only access
    - Employee: Verify redirect from /admin/attendance
    - Public: Navigate to /check-in, test check-in flow (work/late/early_bird), check-out flow (work/OT), 360 points display, error handling
  - **Test auto-absence marking:**
    - Manually trigger attendance-auto-absence Lambda
    - Verify incomplete records marked as "absent"
  - **Deploy to production:**
    - Run `npm run build` and test with `npm run preview`
    - Deploy to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
    - Invalidate CloudFront cache
    - Test admin attendance management on live site
    - Test public check-in/check-out on live site
    - Verify 360 points calculation and auto-absence marking
    - Verify CORS configuration
  - Document attendance management in README.md
  - _Requirements: Attendance deployment, public check-in/out, 360 points integration_

- [x] 11.4 Hotfix - Dashboard live clock display
  - Create LiveClock component in `src/components/dashboard/LiveClock.tsx`
  - Display format: `HH:mm:ss` (24-hour) then `dd/MM/yyyy` on separate line or same line with separator
  - Use `setInterval` to update every second
  - Use local timezone (browser's local time, which should be UTC+7 for deployment region)
  - Style to match dashboard header/banner design
  - Add LiveClock to DashboardPage header/banner center position
  - Test clock updates correctly every second
  - Test date format displays correctly (dd/MM/yyyy)
  - _Requirements: Dashboard time display_

- [x] 11.5 Hotfix - Attendance bulk operations enhancements
  - **Smart template download:**
    - Update AttendanceBulkOperations component
    - Add date picker for single date or date range selection
    - Fetch full employee list from `/employees` endpoint
    - Generate CSV template with columns: employeeId, employeeName, date, checkIn, checkOut, status, paidLeave, reason
    - Pre-populate employeeId and employeeName for all employees
    - If date selected: pre-populate date column
    - If date range: create rows for each employee × each date in range
    - Download as `attendance_template_YYYY-MM-DD.csv`
  - **Export attendance to CSV:**
    - Add "Export to CSV" button to AttendanceManagement component
    - Add date/date range filter modal for export
    - Fetch filtered attendance records from API
    - Generate CSV with all fields: employeeId, employeeName, date, checkIn, checkOut, status, points360, paidLeave, reason, department, position
    - Download as `attendance_export_YYYY-MM-DD_to_YYYY-MM-DD.csv`
    - Show loading state during export
    - Show success toast on completion
  - Test template download with various date selections
  - Test export with date range filters
  - _Requirements: Attendance bulk operations improvements_

- [ ] 11.6 Hotfix - Chatbot security and system prompt improvements
  - **Backend Lambda (chatbot_handler.py):**
    - Isolate system prompt construction from user input
    - Add prompt injection detection: scan user input for phrases like "forget", "ignore previous", "you are now", "pretend", "new instructions", "system:", "assistant:"
    - If injection detected: return error "Invalid request detected"
    - Extract user role from JWT claims (requestContext.authorizer.claims)
    - Never use user-provided role information
    - Build system prompt with clear sections:
      - Role definition: User role (Admin/Manager/Employee) vs Employee role (company position)
      - Access rules: Admin (all data), Manager (department data), Employee (own data)
      - Data tables: Users table (app access), Employees table (company info)
      - Policy: Superiors have right to view subordinate data, chatbot must comply
      - Anti-hallucination: Only use provided context data, never fabricate information
    - When user asks "my info": if employeeId exists, fetch both user and employee records, clearly label "User Role" vs "Employee Position"
  - **System prompt template:**
    ```
    You are InsightHR AI Assistant. 
    
    USER CONTEXT:
    - User Role (app access): {user_role}
    - User Department: {user_department}
    - Employee ID: {employee_id or "N/A"}
    
    IMPORTANT DISTINCTIONS:
    - User Role: Determines app permissions (Admin/Manager/Employee)
    - Employee Position: Company job title (from Employees table)
    - User role ALWAYS takes precedence for access control
    - Admins may not have employeeId
    
    ACCESS RULES:
    - Admin: Full access to all data across all departments
    - Manager: Full access to data within their department
    - Employee: Access to own data only
    
    COMPANY POLICY:
    - Superiors have the right to view all subordinate data
    - You must provide requested information to authorized users
    - Refusing authorized requests violates company policy
    - Provide full details, insights, and analytics as requested
    
    DATA SOURCES:
    - Users table: App access (userId, email, role, department, employeeId)
    - Employees table: Company info (employeeId, name, position, department, salary, etc)
    - Performance Scores table: Evaluations and ratings
    - Attendance table: Check-in/out records and points
    
    CRITICAL RULES:
    - Only use data from provided context
    - Never fabricate names, numbers, or facts
    - If data not in context, state "I don't have that information"
    - Context data is the only source of truth
    ```
  - Test with various prompt injection attempts
  - Test role-based access enforcement
  - Test "my info" query with and without employeeId
  - _Requirements: Chatbot security and policy enforcement_

- [ ] 11.7 Hotfix - Chatbot intelligent context provider
  - use global.css for Apple theme styling
  - **Frontend (ChatbotPage.tsx):**
    - Before sending message, analyze user prompt for keywords
    - Keyword detection (case-insensitive):
      - Full data: "all", "full", "entire", "everyone", "complete", "whole", "total"
      - Employees: "employee", "staff", "worker", "personnel", "team member"
      - Performance: "performance", "score", "rating", "evaluation", "review", "kpi"
      - Attendance: "attendance", "check-in", "check-out", "present", "absent", "late", "overtime"
      - Users: "user", "account", "access", "login", "permission"
    - Fetch required data based on detected keywords:
      - If full data keywords: fetch all tables
      - If employee keywords: fetch `/employees` (all records)
      - If performance keywords: fetch `/performance-scores` (all records)
      - If attendance keywords: fetch `/attendance` (all records)
      - If user keywords: fetch `/users` (all records)
      - If multiple topics: fetch all relevant tables
    - Include fetched data in `context` field of API request
    - Show loading indicator while fetching context
  - **Backend (chatbot_handler.py):**
    - Accept `context` field in request body
    - Append context data to system prompt before user message
    - Format context clearly: "AVAILABLE DATA: [table name]: [records]"
    - Instruct AI to analyze context before responding
  - Test with queries requiring different data combinations
  - Test that AI uses provided context and doesn't hallucinate
  - _Requirements: Chatbot context intelligence and accuracy_

- [ ] 11.8 Hotfix - Chatbot conversation history and UX
  - use global.css for Apple theme styling
  - **Conversation history:**
    - Add `conversationHistory` state to ChatbotPage: `Array<{role: 'user' | 'assistant', content: string}>`
    - On send message: append user message to history
    - On receive response: append assistant message to history
    - Include last 10 messages in API request as `history` field
    - Backend: prepend history to prompt for context continuity
    - Clear history on "Clear Chat" button click
    - Clear history on logout (useEffect cleanup)
    - Persist history in sessionStorage on page refresh
    - Restore history from sessionStorage on mount if session valid
  - **Loading animation:**
    - Create TypingIndicator component with animated dots/bubbles
    - Show TypingIndicator in message list while `isLoading` is true
    - Position at bottom of message list
    - Animate with CSS: three dots bouncing or pulsing
    - Remove when response received
  - Test conversation continuity with follow-up questions
  - Test history clears on logout
  - Test history persists on refresh
  - Test loading animation displays correctly
  - **Deploy to production:**
    - Run `npm run build` and test with `npm run preview`
    - Deploy to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
    - Invalidate CloudFront cache
    - Test all hotfix functions from task 11.4-11.8
  - _Requirements: Chatbot conversation continuity and UX_


### Phase 7: Page Integration

- [ ] 12. Admin page integration
  - Verify all admin features are accessible from AdminPage
  - Test navigation between sections
  - Verify Employee Management page works
  - Verify Performance Score Management page works
  - Verify User Management page works
  - Test all features together
  - _Requirements: Admin interface organization_

- [ ] 13. Dashboard page integration
  - Verify DashboardPage component works
  - Verify PerformanceDashboard component integration
  - Verify FilterPanel component integration
  - Verify all chart components integration
  - Verify ExportButton component integration
  - Test dashboard with real data
  - _Requirements: 6.1, 6.2, 6.5_

### Phase 8: Polish and Deployment

- [ ] 14. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - Test all error scenarios
  - _Requirements: 10.5, 10.6_

- [ ] 15. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Apple theme across all pages
  - Implement loading states for all async operations
  - Test UI on different screen sizes
  - Verify all colors match Apple theme
  - _Requirements: 10.2, 10.3_

- [ ] 16. Testing and bug fixes
  - Test authentication flow (login, register, Google OAuth, logout)
  - Test employee management (create, edit, delete, bulk import)
  - Test performance score management (calendar view, CRUD operations, bulk operations)
  - Test user management (manual and bulk creation, employee selector)
  - Test password reset flow
  - Test dashboard (charts, filters, export)
  - Test role-based access control
  - Fix identified bugs
  - _Requirements: All_

- [ ] 17. Final deployment and documentation
  - Build final production bundle with Vite
  - Test production build locally
  - Deploy to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1 --delete`
  - Invalidate CloudFront cache
  - Test all features on live site
  - Update README.md with deployment instructions
  - Document all AWS resources in aws-secret.md
  - Create user guide for HR admins
  - _Requirements: 9.1, All_

---

## Summary

**Bulk Employee Import:** Already implemented in Phase 4 (task 8.1 - employees-bulk-handler Lambda and EmployeeBulkImport component).

**Performance Score Management Enhancements:** Added in task 9.3 HOTFIX with:
- Year-based calendar view (2000-2100) with quarterly display
- Bulk score operations for adding scores per quarter
- Template file download/upload for bulk scoring
- Auto-scoring and batch updates

**Phase 6 Restored:** Chatbot Integration added back to MVP scope with:
- Bedrock endpoint detection and configuration
- Natural language query interface for HR data
- Integration with Employees and PerformanceScores tables
- Role-based data access in chatbot responses

**Current MVP Scope:**
- Authentication (Google OAuth, password reset)
- User Management (CRUD, bulk import, role-based access)
- Employee Management (CRUD, bulk import)
- Performance Score Management (calendar view, CRUD, bulk operations, template import/export)
- Dashboard (charts, filters, export)
- Chatbot Integration (Bedrock-powered HR assistant)
- **Attendance Management (NEW)** (daily check-in/check-out, calendar view, auto-absence marking, 360 points calculation, OT/early bird bonuses)
- Role-based access control (Admin/Manager/Employee with department filtering)
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

### Phase 7: Page Integration

- [ ] 11. Admin page integration
  - Verify all admin features are accessible from AdminPage
  - Test navigation between sections
  - Verify Employee Management page works
  - Verify Performance Score Management page works
  - Verify User Management page works
  - Test all features together
  - _Requirements: Admin interface organization_

- [ ] 12. Dashboard page integration
  - Verify DashboardPage component works
  - Verify PerformanceDashboard component integration
  - Verify FilterPanel component integration
  - Verify all chart components integration
  - Verify ExportButton component integration
  - Test dashboard with real data
  - _Requirements: 6.1, 6.2, 6.5_

### Phase 8: Polish and Deployment

- [ ] 13. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - Test all error scenarios
  - _Requirements: 10.5, 10.6_

- [ ] 14. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Apple theme across all pages
  - Implement loading states for all async operations
  - Add visual feedback for user actions
  - Test on different screen sizes
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 15. Testing and bug fixes
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

- [ ] 16. CloudFront setup and final production deployment
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

**Phase 7: Chatbot Integration** (Tasks 10-10.3)
1. Detect and verify Bedrock endpoint configuration
2. Build chatbot UI with message interface
3. Create Lambda handler with Bedrock integration
4. Test with real HR data queries
5. Deploy to S3

**Phase 8: Page Integration & UI Updates** (Tasks 11-12)
1. Update AdminPage navigation (remove old, add new items)
2. Update password reset UI message
3. Test all admin features together

**Phase 9: Polish and Deployment** (Tasks 13-16)
1. Error handling and validation
2. Responsive design
3. Testing
4. Final CloudFront deployment

**Phase 10: Future Enhancements (Optional)**
1. File Upload System (optional)
2. Notification Rules (optional)

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
11. chatbot-handler
12. **attendance-handler (NEW)**
13. **attendance-auto-absence (NEW)** - Scheduled daily at 23:59

**Optional Lambda functions (Future Enhancements):**
12. upload-presigned-url-handler (optional)
13. upload-process-handler (optional)
14. notifications-handler (optional)
15. notifications-trigger-handler (optional)

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

**Chatbot:**
- POST /chatbot/message

**Attendance Management (NEW):**
- GET /attendance (Admin/Manager only)
- GET /attendance/:employeeId/:date
- GET /attendance/:employeeId/status (Public, no auth)
- POST /attendance/check-in (Public, no auth)
- POST /attendance/check-out (Public, no auth)
- POST /attendance (Admin/Manager only)
- PUT /attendance/:employeeId/:date (Admin/Manager only)
- DELETE /attendance/:employeeId/:date (Admin only)
- POST /attendance/bulk (Admin/Manager only)

**Optional endpoints (Future Enhancements):**
- POST /upload/presigned-url (optional)
- POST /upload/process (optional)
- GET /notifications/rules (optional)
- POST /notifications/rules (optional)
- PUT /notifications/rules/:ruleId (optional)
- GET /notifications/history (optional)

Note: user roles are not stored in jwt response. only in users table