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
  - Fully style with Frutiger Aero theme
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

- [ ] 5.8 Fix stub API Google OAuth login/register
  - Update stub-api/server.js to implement Google OAuth mock flow
  - Add POST /auth/google endpoint that accepts Google token or user info
  - Return mock JWT with user data (same format as login/register)
  - Create mock Google user in memory store if not exists
  - Test Google OAuth flow with stub API
  - Verify frontend Google button works with stub endpoint
  - Document stub Google OAuth flow in stub-api/README.md
  - _Requirements: 1.4, 1.5_

### Phase 3: User Management

- [ ] 6. Frontend - Profile page UI (static framework)
  - Create ProfileView component (read-only display)
  - Display user information (name, email, role, department, employeeId)
  - Style with Frutiger Aero theme
  - Create test page at `/test/profile` for isolated testing
  - _Requirements: 2.1_

- [ ] 6.1 Stub API - User management endpoints
  - Add to Express.js stub server
  - Create in-memory user profiles
  - Implement GET /users/me endpoint (return current user profile)
  - Implement PUT /users/me endpoint (update user profile in memory)
  - Implement GET /users endpoint (return all users, Admin only)
  - Implement POST /users endpoint (create user, Admin only)
  - Implement PUT /users/:userId endpoint (update user, Admin only)
  - Test all endpoints with Postman/curl
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [ ] 6.2 Frontend - Integrate profile with stub API
  - Create userService for API calls
  - Fetch data from stub /users/me endpoint
  - Test profile display at `/test/profile`
  - Verify data updates work with stub API
  - _Requirements: 2.1_

- [ ] 6.3 AWS Infrastructure - User management Lambda
  - Check if user Lambda functions exist
  - Create Lambda function: users-handler
    - GET /users/me → Fetch current user from DynamoDB
    - PUT /users/me → Update user profile
    - GET /users → List all users (Admin only)
    - POST /users → Create user (Admin only)
    - PUT /users/:userId → Update user (Admin only)
  - Package Lambda with dependencies
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [ ] 6.4 AWS Deployment - User management Lambda
  - Deploy users-handler to ap-southeast-1
  - Create API Gateway endpoints for user operations
  - Test endpoints with authentication using Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoints
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [ ] 6.5 Frontend - Switch to AWS endpoints and test
  - Update userService to use real AWS API Gateway URLs
  - Test profile page with real DynamoDB data on localhost
  - Verify role-based access control works
  - Test end-to-end user management flow on localhost
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [ ] 6.6 Build and deploy user management phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website user profile and management features
  - Verify all user operations work on live site
  - _Requirements: 2.1, 2.2, 9.1_

### Phase 4: KPI Management

- [ ] 7. Frontend - KPI UI components (static framework)
  - Create KPI types and interfaces (kpi.types.ts)
  - Create KPIManager container component
  - Create KPIForm component with name, description, dataType, category fields
  - Create KPIList component with edit and disable actions
  - Implement KPI category organization view
  - Add form validation for KPI creation
  - Style with Frutiger Aero theme
  - Create test page at `/test/kpi` for isolated testing
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7.1 Stub API - KPI management endpoints
  - Add to Express.js stub server
  - Create in-memory KPI store with demo KPIs
  - Implement GET /kpis endpoint (return all active KPIs)
  - Implement GET /kpis/:kpiId endpoint (return single KPI)
  - Implement POST /kpis endpoint (create KPI, Admin only)
  - Implement PUT /kpis/:kpiId endpoint (update KPI, Admin only)
  - Implement DELETE /kpis/:kpiId endpoint (soft delete, Admin only)
  - Test all endpoints with Postman/curl
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7.2 Frontend - Integrate KPI with stub API
  - Create kpiService for API calls (getAll, create, update, disable)
  - Create KPI store (Zustand) for state management
  - Connect KPI components to stub API
  - Test create, edit, disable operations at `/test/kpi`
  - Verify category organization works
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 7.3 AWS Infrastructure - KPI management Lambda
  - Check if KPI Lambda functions exist
  - Create Lambda function: kpis-handler
    - GET /kpis → List all active KPIs from DynamoDB
    - GET /kpis/:kpiId → Get single KPI
    - POST /kpis → Create new KPI (Admin only)
    - PUT /kpis/:kpiId → Update KPI (Admin only)
    - DELETE /kpis/:kpiId → Soft delete KPI (Admin only)
  - Implement DynamoDB operations (scan, get, put, update)
  - Package Lambda with dependencies
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7.4 AWS Deployment - KPI management Lambda
  - Deploy kpis-handler to ap-southeast-1
  - Create API Gateway endpoints for KPI operations
  - Test CRUD operations with Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoints
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7.5 Frontend - Switch to AWS endpoints and test
  - Update kpiService to use real AWS API Gateway URLs
  - Test KPI management with real DynamoDB data on localhost
  - Verify all CRUD operations work end-to-end
  - Test category filtering with real data
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7.6 Build and deploy KPI management phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website KPI management features
  - Verify KPI create, edit, disable, and category filtering work on live site
  - _Requirements: 3.1, 3.2, 9.1_

### Phase 5: Formula Builder

- [ ] 8. Frontend - Formula Builder UI (static framework)
  - Create Formula types and interfaces (formula.types.ts)
  - Create FormulaBuilder component with semantic input field
  - Implement autocomplete for KPI selection (Ctrl+space trigger)
  - Create weight assignment interface
  - Implement real-time validation (sum = 100%)
  - Create FormulaPreview component to display formula
  - Support both simple and complex expressions
  - Support multiple active formulas
  - Style with Frutiger Aero theme
  - Create test page at `/test/formula` for isolated testing
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.1 Stub API - Formula management endpoints
  - Add to Express.js stub server
  - Create in-memory formula store with demo formulas
  - Implement GET /formulas endpoint (return all formulas)
  - Implement GET /formulas/:formulaId endpoint (return single formula)
  - Implement POST /formulas endpoint (create formula, Admin only)
  - Implement PUT /formulas/:formulaId endpoint (update formula, Admin only)
  - Implement POST /formulas/:formulaId/validate endpoint (validate weights sum = 100%)
  - Test all endpoints with Postman/curl
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.2 Frontend - Integrate Formula Builder with stub API
  - Create formulaService for API calls
  - Create formula store (Zustand)
  - Connect Formula Builder to stub API
  - Test formula creation and validation at `/test/formula`
  - Verify autocomplete works with stub KPI data
  - Test weight validation (sum = 100%)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.3 AWS Infrastructure - Formula management Lambda
  - Check if formula Lambda functions exist
  - Create Lambda function: formulas-handler
    - GET /formulas → List all formulas from DynamoDB
    - GET /formulas/:formulaId → Get single formula
    - POST /formulas → Create formula (Admin only)
    - PUT /formulas/:formulaId → Update formula (Admin only)
    - POST /formulas/:formulaId/validate → Validate formula weights
  - Implement formula validation logic (sum of weights = 100%)
  - Package Lambda with dependencies
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.4 AWS Deployment - Formula management Lambda
  - Deploy formulas-handler to ap-southeast-1
  - Create API Gateway endpoints
  - Test formula operations with Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoints
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.5 Frontend - Switch to AWS endpoints and test
  - Update formulaService to use real AWS API Gateway URLs
  - Test formula creation with real DynamoDB data on localhost
  - Verify validation works with real backend
  - Test multiple active formulas
  - Test department-specific formulas
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8.6 Build and deploy formula builder phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website formula builder features
  - Verify formula creation, validation, and weight assignment work on live site
  - _Requirements: 4.1, 4.2, 9.1_

### Phase 6: File Upload System

- [ ] 9. Frontend - File upload UI (static framework)
  - Create FileUpload types and interfaces
  - Create FileUploader component with drag-and-drop
  - Create ColumnMapper component
  - Display file headers with KPI dropdown mapping
  - Implement file type validation (CSV, Excel)
  - Implement file size validation (10,000+ records)
  - Use LoadingSpinner during upload
  - Style with Frutiger Aero theme
  - Create test page at `/test/upload` for isolated testing
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.1 Stub API - File upload endpoints
  - Add to Express.js stub server
  - Implement POST /upload/presigned-url endpoint (return mock presigned URL)
  - Implement POST /upload/process endpoint (mock file processing)
  - Create mock file parsing logic (CSV/Excel)
  - Return mock column headers for mapping
  - Store mock uploaded data in memory
  - Test endpoints with Postman/curl
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.2 Frontend - Integrate upload with stub API
  - Create uploadService with presigned URL and file processing
  - Connect FileUploader to stub API
  - Test file upload flow at `/test/upload`
  - Test column mapping with stub data
  - Verify validation works
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.3 AWS Infrastructure - File upload Lambda
  - Check if upload Lambda functions exist
  - Create Lambda function: upload-presigned-url-handler
    - POST /upload/presigned-url → Generate S3 presigned URL
    - Validate file type and size
  - Create Lambda function: upload-process-handler
    - POST /upload/process → Process uploaded file
    - Parse CSV/Excel from S3
    - Detect table pattern or create new table
    - Insert data into DynamoDB DataTables
    - Trigger performance calculation if needed
  - Package Lambdas with dependencies (pandas, openpyxl)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.4 AWS Deployment - File upload Lambda
  - Deploy upload-presigned-url-handler to ap-southeast-1
  - Deploy upload-process-handler to ap-southeast-1
  - Create API Gateway endpoints
  - Test file upload flow with real S3
  - Update aws-secret.md with Lambda ARNs and endpoints
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.5 Frontend - Switch to AWS endpoints and test
  - Update uploadService to use real AWS API Gateway URLs
  - Test file upload to real S3 bucket on localhost
  - Test file processing with real Lambda
  - Verify data appears in DynamoDB
  - Test end-to-end upload and mapping flow
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9.6 Build and deploy file upload phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website file upload features
  - Verify file upload, column mapping, and data processing work on live site
  - Test with CSV and Excel files on live site
  - _Requirements: 5.1, 5.6, 9.1_

### Phase 7: Performance Dashboard

- [ ] 10. Frontend - Dashboard UI (static framework)
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
  - Style with Frutiger Aero theme
  - Create test page at `/test/dashboard` for isolated testing
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.1 Stub API - Performance data endpoints
  - Add to Express.js stub server
  - Create in-memory performance scores with demo data
  - Implement GET /performance endpoint (return scores with filters)
  - Implement GET /performance/:employeeId endpoint (return employee scores)
  - Implement POST /performance/export endpoint (return CSV data)
  - Support filtering by department, date range, employee
  - Test endpoints with Postman/curl
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.2 Frontend - Integrate dashboard with stub API
  - Create performanceService for API calls
  - Create performance store (Zustand) with filters
  - Connect dashboard components to stub API
  - Test filtering and data display at `/test/dashboard`
  - Test charts with stub data
  - Test CSV export functionality
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.3 AWS Infrastructure - Performance data Lambda
  - Check if performance Lambda functions exist
  - Create Lambda function: performance-handler
    - GET /performance → Query performance scores with filters
    - GET /performance/:employeeId → Get employee performance
    - POST /performance/export → Generate CSV export
  - Implement DynamoDB queries with GSI for filtering
  - Package Lambda with dependencies
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.4 AWS Deployment - Performance data Lambda
  - Deploy performance-handler to ap-southeast-1
  - Create API Gateway endpoints
  - Test data retrieval with filters using Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoints
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.5 Frontend - Switch to AWS endpoints and test
  - Update performanceService to use real AWS API Gateway URLs
  - Test dashboard with real DynamoDB data on localhost
  - Test filtering with real data
  - Test charts with real performance scores
  - Test CSV export with real data
  - Verify role-based access works
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10.6 Build and deploy dashboard phase to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website dashboard features
  - Verify charts, filters, and CSV export work on live site
  - Test role-based data visibility on live site
  - _Requirements: 6.1, 6.2, 9.1_

### Phase 8: Admin Features

- [ ] 11. Frontend - User management UI (static framework)
  - Create User types and interfaces (user.types.ts)
  - Create UserManagement component with user list
  - Create manual user creation form (one-by-one)
  - Create bulk user import UI from CSV file
  - Add user edit functionality (role, department, employeeId)
  - Implement user disable/enable actions
  - Add search and filter for user list
  - Style with Frutiger Aero theme
  - Create test page at `/test/users` for isolated testing
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 11.1 Stub API - User bulk operations endpoint
  - Add to Express.js stub server
  - Implement POST /users/bulk endpoint (create multiple users)
  - Parse CSV data and create users in memory
  - Return success/failure for each user
  - Test endpoint with Postman/curl
  - _Requirements: 2.4_

- [ ] 11.2 Frontend - Integrate user management with stub API
  - Update userService with bulk operations
  - Connect UserManagement to stub API
  - Test manual user creation at `/test/users`
  - Test bulk user import
  - Test user edit and disable operations
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 11.3 AWS Infrastructure - User bulk operations Lambda
  - Create Lambda function: users-bulk-handler
    - POST /users/bulk → Create multiple users from CSV
    - Parse CSV file from S3
    - Create Cognito users in batch
    - Insert into DynamoDB Users table
  - Package Lambda with dependencies
  - _Requirements: 2.4_

- [ ] 11.4 AWS Deployment - User bulk operations Lambda
  - Deploy users-bulk-handler to ap-southeast-1
  - Create API Gateway endpoint
  - Test bulk user creation with Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoint
  - _Requirements: 2.4_

- [ ] 11.5 Frontend - Switch to AWS endpoints and test
  - Update userService to use real AWS API Gateway URLs
  - Test user management with real Cognito and DynamoDB on localhost
  - Test bulk user creation end-to-end
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 11.6 Build and deploy admin user management to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website admin user management features
  - Verify manual and bulk user creation work on live site
  - _Requirements: 2.4, 9.1_

- [ ] 12. Frontend - Notification rules UI (static framework)
  - Create Notification types and interfaces
  - Create NotificationRuleManager component
  - Create condition builder supporting simple and complex logic
  - Implement recipient selection (roles, departments, specific users)
  - Add enable/disable toggle for rules
  - Create email template configuration
  - Style with Frutiger Aero theme
  - Create test page at `/test/notifications` for isolated testing
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.1 Stub API - Notification endpoints
  - Add to Express.js stub server
  - Create in-memory notification rules store
  - Implement GET /notifications/rules endpoint
  - Implement POST /notifications/rules endpoint (create rule)
  - Implement PUT /notifications/rules/:ruleId endpoint (update rule)
  - Implement GET /notifications/history endpoint
  - Test endpoints with Postman/curl
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.2 Frontend - Integrate notifications with stub API
  - Create notificationService for API calls
  - Connect NotificationRuleManager to stub API
  - Test notification rule creation at `/test/notifications`
  - Test condition builder
  - Test recipient selection
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.3 AWS Infrastructure - Notification Lambda
  - Check if notification Lambda functions exist
  - Set up SNS topic for email notifications in ap-southeast-1
  - Create Lambda function: notifications-handler
    - GET /notifications/rules → List notification rules
    - POST /notifications/rules → Create rule (Admin only)
    - PUT /notifications/rules/:ruleId → Update rule (Admin only)
    - GET /notifications/history → Get notification history
  - Create Lambda function: notifications-trigger-handler
    - Triggered by DynamoDB stream or EventBridge
    - Evaluate rules against performance data
    - Send emails via SNS
  - Package Lambdas with dependencies
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.4 AWS Deployment - Notification Lambda
  - Deploy notifications-handler to ap-southeast-1
  - Deploy notifications-trigger-handler to ap-southeast-1
  - Create API Gateway endpoints
  - Set up DynamoDB stream trigger
  - Test notification creation and triggering with Postman/curl
  - Update aws-secret.md with Lambda ARNs and endpoints
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.5 Frontend - Switch to AWS endpoints and test
  - Update notificationService to use real AWS API Gateway URLs
  - Test notification rules with real DynamoDB on localhost
  - Test email sending via SNS
  - Verify notification history works
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 12.6 Build and deploy notification features to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website notification features
  - Verify notification rule creation and email sending work on live site
  - _Requirements: 8.1, 8.2, 9.1_

### Phase 9: Chatbot Integration

- [ ] 13. Frontend - Chatbot UI (static framework)
  - Create ChatMessage and ChatSession types
  - Create ChatbotPage
  - Create ChatbotWidget component for dedicated tab
  - Create MessageList component (no history persistence)
  - Create MessageInput component
  - Create ChatbotInstructions component with usage guide
  - Implement one-off query mode (no session history)
  - Style with Frutiger Aero theme
  - Create test page at `/test/chatbot` for isolated testing
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 13.1 Stub API - Chatbot endpoint
  - Add to Express.js stub server
  - Implement POST /chatbot/message endpoint
  - Create simple rule-based chatbot logic
  - Query in-memory performance data
  - Return formatted responses
  - Test endpoint with Postman/curl
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13.2 Frontend - Integrate chatbot with stub API
  - Create chatbotService for API calls
  - Connect ChatbotWidget to stub API
  - Test chatbot interactions at `/test/chatbot`
  - Verify message sending and receiving works
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 13.3 AWS Infrastructure - Chatbot Lambda
  - Check if Lex bot exists in ap-southeast-1
  - If not exists, create Lex bot with intents for HR queries
  - Set up Bedrock integration for natural language understanding
  - Create Lambda function: chatbot-handler
    - POST /chatbot/message → Send message to Lex/Bedrock
    - Query DynamoDB for relevant data
    - Return formatted response
  - Package Lambda with dependencies
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13.4 AWS Deployment - Chatbot Lambda
  - Deploy chatbot-handler to ap-southeast-1
  - Create API Gateway endpoint
  - Test chatbot queries with Postman/curl
  - Update aws-secret.md with Lambda ARN and endpoint
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13.5 Frontend - Switch to AWS endpoints and test
  - Update chatbotService to use real AWS API Gateway URLs
  - Test chatbot with real Lex/Bedrock integration on localhost
  - Verify data queries work with real DynamoDB
  - Test various HR-related queries
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13.6 Build and deploy chatbot features to S3
  - Run `npm run build` to create production bundle
  - Test production build locally with `npm run preview`
  - Deploy build to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
  - Invalidate CloudFront cache if exists
  - Test live deployed website chatbot features
  - Verify chatbot queries and responses work on live site
  - _Requirements: 7.1, 7.2, 9.1_

### Phase 10: Page Integration

- [ ] 14. Admin page integration
  - Create AdminPage component
  - Integrate KPIManager component
  - Integrate FormulaBuilder component
  - Integrate UserManagement component
  - Integrate NotificationRuleManager component
  - Add tab navigation between sections
  - Test all admin features together
  - _Requirements: 3.1, 4.1, 8.1_

- [ ] 15. Dashboard page integration
  - Create DashboardPage component
  - Integrate PerformanceDashboard component
  - Integrate FilterPanel component
  - Integrate all chart components
  - Integrate ExportButton component
  - Test dashboard with real data
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 16. Upload page integration
  - Create UploadPage component
  - Integrate FileUploader component
  - Integrate ColumnMapper component
  - Add upload status feedback
  - Test complete upload workflow
  - _Requirements: 5.1, 5.6_

### Phase 11: Polish and Deployment

- [ ] 17. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - Test all error scenarios
  - _Requirements: 10.5, 10.6_

- [ ] 18. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Frutiger Aero theme across all pages
  - Implement loading states for all async operations
  - Add visual feedback for user actions
  - Test on different screen sizes
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 19. Testing and bug fixes
  - Test authentication flow (login, register, Google OAuth, logout)
  - Test KPI management (create, edit, disable, categories)
  - Test formula builder (simple and complex expressions, validation)
  - Test user management (manual and bulk creation)
  - Test file upload and column mapping
  - Test dashboard (charts, filters, export)
  - Test chatbot (data queries)
  - Test notification rules
  - Test role-based access control
  - Fix identified bugs
  - _Requirements: All_

- [ ] 20. CloudFront setup and final production deployment
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

- [ ] 6. Admin Panel - KPI Management
  - Create KPI types and interfaces (kpi.types.ts)
  - Create kpiService for API calls (getAll, create, update, disable)
  - Create KPI store (Zustand) for state management
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 6.1 KPI UI components
  - Create KPIManager container component
  - Create KPIForm component with name, description, dataType, category fields
  - Create KPIList component with edit and disable actions
  - Implement KPI category organization view
  - Add form validation for KPI creation
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7. Admin Panel - Formula Builder
  - Create Formula types and interfaces (formula.types.ts)
  - Create formulaService for API calls
  - Create formula store (Zustand)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 7.1 Formula Builder UI
  - Create FormulaBuilder component with semantic input field
  - Implement autocomplete for KPI selection (Ctrl+space trigger)
  - Create weight assignment interface
  - Implement real-time validation (sum = 100%)
  - Create FormulaPreview component to display formula
  - Support both simple and complex expressions
  - Support multiple active formulas
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8. Admin Panel - User Management
  - Create User types and interfaces (user.types.ts)
  - Create userService for API calls
  - Create UserManagement component with user list
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 8.1 User creation and bulk import
  - Create manual user creation form (one-by-one)
  - Implement bulk user import from CSV file
  - Add user edit functionality (role, department, employeeId)
  - Implement user disable/enable actions
  - Add search and filter for user list
  - _Requirements: 2.4_

- [ ] 9. Admin Panel - Notification Rules
  - Create Notification types and interfaces
  - Create notificationService for API calls
  - Create NotificationRuleManager component
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 9.1 Notification rule configuration
  - Create condition builder supporting simple and complex logic
  - Implement recipient selection (roles, departments, specific users)
  - Add enable/disable toggle for rules
  - Create email template configuration
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. File Upload system
  - Create FileUpload types and interfaces
  - Create uploadService with presigned URL and file processing
  - Create FileUploader component with drag-and-drop
  - Implement file type validation (CSV, Excel)
  - Implement file size validation (10,000+ records)
  - Use LoadingSpinner during upload (no progress bar)
  - _Requirements: 5.1, 5.2, 5.6_

- [ ] 10.1 Column mapping (simplified)
  - Create ColumnMapper component
  - Display file headers with KPI dropdown mapping
  - Remove pattern detection - always create new table
  - Implement validation before submission
  - Upload file to S3 using presigned URL
  - Send mapping configuration to API Gateway
  - _Requirements: 5.3, 5.4, 5.5, 5.6_

- [ ] 11. Dashboard - Data display
  - Create Performance types and interfaces
  - Create performanceService for API calls
  - Create performance store (Zustand) with filters
  - Create PerformanceDashboard container component
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 11.1 Dashboard table and filters
  - Create DataTable component with sortable columns
  - Create FilterPanel with department, time period, employee filters
  - Implement role-based data display (Admin/Manager/Employee)
  - Add manual data refresh (browser refresh)
  - _Requirements: 6.1, 6.3, 6.4_

- [ ] 11.2 Dashboard charts
  - Install and configure Recharts library
  - Create LineChart component for performance trends
  - Create BarChart component for comparative performance
  - Create PieChart component for distribution
  - Implement static visualizations (no interactivity)
  - Add responsive design for charts
  - _Requirements: 6.2_

- [ ] 11.3 Data export
  - Create ExportButton component
  - Implement CSV export functionality
  - Apply current filters to export
  - _Requirements: 6.5_

- [ ] 12. Chatbot integration
  - Create ChatMessage and ChatSession types
  - Create chatbotService for API calls to Lex/Bedrock
  - Create ChatbotPage
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 12.1 Chatbot UI (simplified)
  - Create ChatbotWidget component for dedicated tab
  - Create MessageList component (no history persistence)
  - Create MessageInput component
  - Create ChatbotInstructions component with usage guide
  - Remove suggested queries
  - Implement one-off query mode (no session history)
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 13. Profile page (read-only)
  - Create ProfileView component (read-only display)
  - Display user information (name, email, role, department, employeeId)
  - Remove profile editing capability
  - Remove avatar upload
  - _Requirements: 2.1_

- [ ] 14. Admin page integration
  - Create AdminPage component
  - Integrate KPIManager component
  - Integrate FormulaBuilder component
  - Integrate UserManagement component
  - Integrate NotificationRuleManager component
  - Add tab navigation between sections
  - _Requirements: 3.1, 4.1, 8.1_

- [ ] 15. Dashboard page integration
  - Create DashboardPage component
  - Integrate PerformanceDashboard component
  - Integrate FilterPanel component
  - Integrate all chart components
  - Integrate ExportButton component
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 16. Upload page integration
  - Create UploadPage component
  - Integrate FileUploader component
  - Integrate ColumnMapper component
  - Add upload status feedback
  - _Requirements: 5.1, 5.6_

- [ ] 17. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - _Requirements: 10.5, 10.6_

- [ ] 18. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Frutiger Aero theme across all pages
  - Implement loading states for all async operations
  - Add visual feedback for user actions
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 19. Testing and bug fixes
  - Test authentication flow (login, register, Google OAuth, logout)
  - Test KPI management (create, edit, disable, categories)
  - Test formula builder (simple and complex expressions, validation)
  - Test user management (manual and bulk creation)
  - Test file upload and column mapping
  - Test dashboard (charts, filters, export)
  - Test chatbot (data queries)
  - Test role-based access control
  - Fix identified bugs
  - _Requirements: All_

- [ ] 20. Deployment preparation
  - Configure environment variables for production
  - Build production bundle with Vite
  - Test production build locally
  - Create deployment script for S3
  - Document deployment process
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
- **Styling**: Apply Frutiger Aero theme from the start, fully style as you build
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

Before starting development, verify these resources exist in ap-southeast-1:
- [ ] DynamoDB tables (7 tables)
- [ ] S3 buckets (2 buckets: uploads, web-app)
- [ ] Cognito User Pool with app client
- [ ] API Gateway REST API
- [ ] Lambda execution IAM role
- [ ] CloudFront distribution (for production)

### Build Order

**Phase 0: AWS Foundation** (Tasks 0.1-0.6)
1. Verify/update region configuration
2. Set up DynamoDB tables
3. Set up S3 buckets
4. Set up Cognito User Pool
5. Set up API Gateway
6. Set up IAM roles

**Phase 1-2: Authentication** (Tasks 1-5.3)
1. Keep existing project setup
2. Create auth Lambda functions
3. Integrate Cognito in frontend
4. Build login/register UI
5. Test authentication flow

**Phase 3-4: Core Features** (Tasks 6-8.2)
1. User management (Lambda + UI)
2. KPI management (Lambda + UI)
3. Formula builder (Lambda + UI)

**Phase 5-7: Data Features** (Tasks 9-10.4)
1. File upload system (Lambda + UI)
2. Performance dashboard (Lambda + UI)
3. Data visualization (charts)

**Phase 8-9: Admin Features** (Tasks 11-13.1)
1. Bulk user operations
2. Notification system
3. Chatbot integration

**Phase 10-11: Integration & Deployment** (Tasks 14-20)
1. Page integration
2. Error handling
3. Responsive design
4. Testing
5. CloudFront deployment

### Lambda Function List

Total Lambda functions to create:
1. auth-login-handler
2. auth-register-handler
3. auth-google-handler
4. users-handler
5. users-bulk-handler
6. kpis-handler
7. formulas-handler
8. upload-presigned-url-handler
9. upload-process-handler
10. performance-handler
11. notifications-handler
12. notifications-trigger-handler
13. chatbot-handler

### API Gateway Endpoints

All endpoints under `/dev` stage:
- POST /auth/login
- POST /auth/register
- POST /auth/google
- POST /auth/refresh
- GET /users/me
- PUT /users/me
- GET /users
- POST /users
- POST /users/bulk
- PUT /users/:userId
- GET /kpis
- GET /kpis/:kpiId
- POST /kpis
- PUT /kpis/:kpiId
- DELETE /kpis/:kpiId
- GET /formulas
- GET /formulas/:formulaId
- POST /formulas
- PUT /formulas/:formulaId
- POST /formulas/:formulaId/validate
- POST /upload/presigned-url
- POST /upload/process
- GET /performance
- GET /performance/:employeeId
- POST /performance/export
- GET /notifications/rules
- POST /notifications/rules
- PUT /notifications/rules/:ruleId
- GET /notifications/history
- POST /chatbot/message
