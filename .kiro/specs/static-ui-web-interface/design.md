# Design Document

## Overview

The InsightHR Static Web Interface is a React + TypeScript single-page application (SPA) that provides a modern, responsive UI for HR automation. The application follows a serverless architecture pattern, hosted on Amazon S3 and distributed globally via CloudFront, with all business logic handled by Python Lambda functions accessed through API Gateway.

**Design Principles:**
- **MVP-First Approach**: Focus on core functionality with a 1-month timeline
- **Serverless Architecture**: Fully static frontend with no server-side rendering
- **API-Driven**: All data operations through RESTful API Gateway endpoints
- **Component-Based**: Modular React components for maintainability
- **Type-Safe**: TypeScript for compile-time error detection
- **Responsive**: Mobile-first design approach
- **Modern UI**: Apple Blue theme with clean, intuitive interface inspired by Apple's design language
- **Regional Deployment**: All AWS infrastructure deployed in ap-southeast-1 (Singapore) region

**Development Workflow:**
Each major feature follows this development order:
1. **Static Frontend Framework**: Build UI components with full Apple Blue theme styling
2. **Stub Function**: Create fully working local Express.js API server (`localhost:4000`) with in-memory data for demo/testing
3. **AWS Infrastructure**: Set up Lambda functions, DynamoDB tables, and API Gateway endpoints in ap-southeast-1
4. **Deploy to Cloud**: Deploy Lambda functions and connect to API Gateway
5. **Test**: Verify end-to-end functionality with real AWS services

**Testing Environment:**
- **Test Routes**: All test/demo pages accessible at `localhost:5173/test/*`
  - `/test/login` - Authentication testing
  - `/test/kpi` - KPI management testing
  - `/test/formula` - Formula builder testing
  - `/test/upload` - File upload testing
  - `/test/dashboard` - Dashboard testing
  - `/test/users` - User management testing
  - `/test/notifications` - Notification rules testing
  - `/test/chatbot` - Chatbot testing
- **Production Routes**: Main app at `localhost:5173/*` (no `/test` prefix)
- **Stub API**: Local Express.js server on `localhost:4000` mimicking AWS Lambda responses
- **Test Folder**: Separate `/test` folder for demo components and test pages

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CloudFront (CDN)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              S3 Bucket (Static Web Hosting)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │   React + TypeScript SPA                             │  │
│  │   - Components, Pages, Services                      │  │
│  │   - Static Assets (CSS, Images, Fonts)              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ HTTPS Requests
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway (REST API)                    │
│  - /auth/*      - /kpis/*      - /formulas/*                │
│  - /users/*     - /upload/*    - /performance/*             │
│  - /chatbot/*   - /notifications/*                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Python Lambda Functions                   │
│  - Authentication Handler    - KPI Manager                   │
│  - Formula Calculator        - File Processor                │
│  - Data Query Handler        - Notification Manager          │
│  - Chatbot Handler                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                         DynamoDB                             │
│  - Users Table          - KPIs Table                         │
│  - Formulas Table       - PerformanceScores Table            │
│  - DataTables Table     - Notifications Table                │
└─────────────────────────────────────────────────────────────┘
```

### Authentication Flow

```
User → React App → Cognito (Email/Password or Google OAuth)
                 ↓
            JWT Token
                 ↓
React App → API Gateway (with Authorization header)
                 ↓
            Lambda (validates token)
                 ↓
            DynamoDB
```

### Lambda Architecture & Inter-Lambda Communication

#### Performance Dashboard Lambda Architecture

The performance dashboard follows a decoupled architecture pattern to support incremental development and avoid rework:

```
Employee Table Changes (DynamoDB Stream)
         ↓
    [Throttled Trigger]
         ↓
┌────────────────────────────────────────┐
│  Performance Handler Lambda            │
│  (dashboard-handler)                   │
│                                        │
│  Environment Variables:                │
│  - AUTO_SCORING_LAMBDA_ARN (optional) │
│  - PERFORMANCE_SCORES_TABLE            │
│  - EMPLOYEES_TABLE                     │
│                                        │
│  Logic:                                │
│  1. Check if AUTO_SCORING_LAMBDA_ARN   │
│     is configured                      │
│  2. If yes, invoke auto-scoring Lambda │
│  3. If no or fails, use existing data  │
│  4. Query PerformanceScores table      │
│  5. Return data to API Gateway         │
└────────────────────────────────────────┘
         │
         │ (Optional invocation)
         ↓
┌────────────────────────────────────────┐
│  Auto-Scoring Lambda                   │
│  (formula-calculator)                  │
│  [Implemented in Phase 5]              │
│                                        │
│  Logic:                                │
│  1. Fetch active formulas              │
│  2. Calculate scores for employees     │
│  3. Write to PerformanceScores table   │
└────────────────────────────────────────┘
```

**Key Design Decisions:**

1. **Environment Variable Pattern**: Use `AUTO_SCORING_LAMBDA_ARN` environment variable
   - Empty/unset in Phase 3 (Dashboard implementation)
   - Set to formula-calculator ARN in Phase 5 (Formula implementation)
   - No code changes needed when auto-scoring is added

2. **Graceful Degradation**: Performance handler works independently
   - If auto-scoring Lambda doesn't exist → uses existing PerformanceScores data
   - If auto-scoring Lambda fails → logs warning, continues with existing data
   - Dashboard remains functional throughout all phases

3. **Throttled Triggers**: Prevent high bandwidth usage
   - DynamoDB Stream triggers with delay/batching
   - Reduces Lambda invocations during rapid Employee table changes
   - Cost-effective for MVP

4. **Separation of Concerns**:
   - **Performance Handler**: Data retrieval, filtering, API responses
   - **Auto-Scoring Lambda**: Score calculation, formula application
   - Clean boundaries enable independent testing and deployment

**Implementation Timeline:**

- **Phase 3 (Dashboard)**: 
  - Create performance-handler with `AUTO_SCORING_LAMBDA_ARN` env var (empty)
  - Works with mock/existing PerformanceScores data
  - Fully testable without auto-scoring

- **Phase 5 (Formula & Auto-Scoring)**:
  - Create formula-calculator Lambda
  - Update performance-handler env var to point to formula-calculator
  - No code changes to performance-handler required

**Example Lambda Code Pattern:**

```python
# performance-handler Lambda (Phase 3)
import os
import boto3
import logging

logger = logging.getLogger()
lambda_client = boto3.client('lambda')
dynamodb = boto3.resource('dynamodb')

AUTO_SCORING_LAMBDA_ARN = os.environ.get('AUTO_SCORING_LAMBDA_ARN', '')
PERFORMANCE_SCORES_TABLE = os.environ['PERFORMANCE_SCORES_TABLE']

def lambda_handler(event, context):
    # Optional: Trigger auto-scoring if configured
    if AUTO_SCORING_LAMBDA_ARN:
        try:
            logger.info(f"Invoking auto-scoring Lambda: {AUTO_SCORING_LAMBDA_ARN}")
            lambda_client.invoke(
                FunctionName=AUTO_SCORING_LAMBDA_ARN,
                InvocationType='Event',  # Async invocation
                Payload=json.dumps({'trigger': 'employee_update'})
            )
        except Exception as e:
            logger.warning(f"Auto-scoring Lambda invocation failed: {e}")
            logger.info("Continuing with existing performance data")
    
    # Query and return performance data (works with or without auto-scoring)
    table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)
    # ... query logic ...
    return response
```

This architecture ensures:
- ✅ No rework when auto-scoring is implemented
- ✅ Dashboard can be tested independently
- ✅ Clean separation of concerns
- ✅ Graceful degradation for MVP
- ✅ Cost-effective Lambda invocations


## Components and Interfaces

### Frontend Component Structure

```
src/
├── components/
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── RegisterForm.tsx
│   │   ├── GoogleAuthButton.tsx
│   │   └── PasswordReset.tsx
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   ├── Footer.tsx
│   │   └── MainLayout.tsx
│   ├── admin/
│   │   ├── KPIManager.tsx
│   │   ├── KPIForm.tsx
│   │   ├── KPIList.tsx
│   │   ├── FormulaBuilder.tsx
│   │   ├── FormulaInput.tsx (with autocomplete)
│   │   ├── NotificationRuleManager.tsx
│   │   └── UserManagement.tsx
│   ├── dashboard/
│   │   ├── PerformanceDashboard.tsx
│   │   ├── DataTable.tsx
│   │   ├── LineChart.tsx
│   │   ├── BarChart.tsx
│   │   ├── PieChart.tsx
│   │   ├── FilterPanel.tsx
│   │   └── ExportButton.tsx
│   ├── upload/
│   │   ├── FileUploader.tsx
│   │   ├── ColumnMapper.tsx
│   │   ├── DataValidator.tsx
│   │   └── UploadProgress.tsx
│   ├── chatbot/
│   │   ├── ChatbotWidget.tsx
│   │   ├── MessageList.tsx
│   │   ├── MessageInput.tsx
│   │   └── SuggestedQueries.tsx
│   ├── profile/
│   │   ├── ProfileView.tsx
│   │   ├── ProfileEdit.tsx
│   │   └── AvatarUpload.tsx
│   └── common/
│       ├── Button.tsx
│       ├── Input.tsx
│       ├── Select.tsx
│       ├── Modal.tsx
│       ├── LoadingSpinner.tsx
│       ├── ErrorMessage.tsx
│       └── ConfirmDialog.tsx
├── pages/
│   ├── LoginPage.tsx
│   ├── DashboardPage.tsx
│   ├── AdminPage.tsx
│   ├── UploadPage.tsx
│   ├── ChatbotPage.tsx
│   ├── ProfilePage.tsx
│   └── NotFoundPage.tsx
├── services/
│   ├── api.ts (Axios instance with interceptors)
│   ├── authService.ts
│   ├── kpiService.ts
│   ├── formulaService.ts
│   ├── uploadService.ts
│   ├── performanceService.ts
│   ├── chatbotService.ts
│   └── notificationService.ts
├── store/
│   ├── authStore.ts
│   ├── kpiStore.ts
│   ├── performanceStore.ts
│   └── uiStore.ts
├── types/
│   ├── auth.types.ts
│   ├── kpi.types.ts
│   ├── formula.types.ts
│   ├── performance.types.ts
│   ├── user.types.ts
│   └── api.types.ts
├── utils/
│   ├── validators.ts
│   ├── formatters.ts
│   ├── csvParser.ts
│   └── constants.ts
├── hooks/
│   ├── useAuth.ts
│   ├── useApi.ts
│   └── useDebounce.ts
├── styles/
│   ├── theme.ts (Frutiger Aero colors)
│   ├── global.css
│   └── variables.css
├── App.tsx
├── main.tsx
└── router.tsx
```


### Key Component Designs

#### 1. Authentication Components

**LoginForm.tsx**
- Email/password input fields
- Google OAuth button integration
- "Forgot Password" link
- "Register" link for self-registration
- Form validation with error messages
- Integration with AWS Cognito

**RegisterForm.tsx**
- Email, password, and name input fields
- Password strength validation
- Form validation with error messages
- Auto-confirmation: New users are automatically confirmed in Cognito upon registration
- No manual approval required (admin approval system is a future enhancement)
- Immediate login after successful registration
- Integration with AWS Cognito

**GoogleAuthButton.tsx**
- Handles Google OAuth flow via Cognito
- Displays Google branding
- Error handling for OAuth failures

**User Registration Strategy:**
- **Current Approach (MVP)**: Auto-approve all new user registrations
  - Users can self-register through the registration form
  - Accounts are automatically confirmed in Cognito (no email verification required)
  - Users are immediately logged in after registration with Employee role by default
  - HR Admins can manually create users with specific roles through the Admin Panel
- **Future Enhancement**: Admin approval workflow
  - Pending user registrations table in DynamoDB
  - Admin UI to approve/reject pending registrations
  - Email notifications for approval status
  - This feature is documented for future implementation but not included in MVP

#### 2. Admin Panel Components

**KPIManager.tsx**
- Main container for KPI management
- Displays KPIList and KPIForm
- Handles create, edit, disable operations
- Category organization view

**FormulaBuilder.tsx**
- Semantic mathematical input field supporting both simple and complex expressions
- Simple: `(KPI1 * weight1) + (KPI2 * weight2)`
- Complex: `IF(KPI1 > 50, KPI2 * 2, KPI3 / 2)`
- Autocomplete for KPI columns (Ctrl+space trigger)
- Weight assignment interface
- Real-time validation (sum = 100%)
- Support for multiple active formulas
- Formula preview display

**NotificationRuleManager.tsx**
- Rule configuration interface
- Condition builder supporting both simple and complex logic:
  - Simple: `score < 50`
  - Complex: `score < 50 AND department = 'Sales' OR attendance < 80%`
- Recipient selection
- Enable/disable toggle
- Notification history log

**UserManagement.tsx**
- User list with search and filter
- Manual user creation form (one-by-one)
- Bulk user import from CSV file
- Edit user details (role, department, employeeId)
- Disable/enable user accounts

#### 3. Dashboard Components

**PerformanceDashboard.tsx**
- Role-based data display (Admin/Manager/Employee)
- DataTable with sortable columns
- Three chart types: LineChart, BarChart, PieChart
- FilterPanel for department, time period, employee
- ExportButton for CSV download
- Manual refresh button

**Chart Components**
- LineChart: Performance trends over time
- BarChart: Comparative performance across employees/departments
- PieChart: Performance distribution by category
- Static visualizations (no drill-down for MVP)
- Responsive design
- Data loading states

#### 4. Upload Components

**FileUploader.tsx**
- Drag-and-drop file upload
- File type validation (CSV, Excel)
- File size validation (10,000+ records)
- Upload progress indicator
- S3 direct upload integration

**ColumnMapper.tsx**
- Displays file headers
- Dropdown for KPI mapping
- Pattern detection logic:
  - Exact match → auto-add to existing table
  - Similar match → show notification with table name and prompt user to confirm
  - New pattern → create new table
- Validation before submission

#### 5. Chatbot Components

**ChatbotWidget.tsx**
- Dedicated tab interface
- MessageList with conversation history
- MessageInput with send button
- Loading indicator during API calls
- Integration with Lex/Bedrock via API Gateway
- Scope: Data queries only (e.g., "What's the average score for Engineering?")
- No navigation help for MVP
- Rejects unrelated questions: Politely declines questions about topics outside HR data (employees, performance, departments)
- Example rejection: "I'm an HR assistant focused on employee and performance data. I can help you with questions about employees, performance scores, departments, and trends. Please ask an HR-related question."


## Data Models

### TypeScript Interfaces

#### Authentication & User Models

```typescript
interface User {
  userId: string;
  email: string;
  name: string;
  role: 'Admin' | 'Manager' | 'Employee';
  employeeId?: string; // Reference to Employee table (optional - not all users are employees)
  department?: string;
  avatarUrl?: string;
  createdAt: string;
  updatedAt: string;
}

interface Employee {
  employeeId: string; // Unique employee identifier (e.g., "DEV-001", "QA-123")
  name: string;
  department: string;
  position: string; // Job position/level (e.g., "Senior", "Junior", "Lead", "Manager")
  email?: string;
  joinDate?: string;
  status: 'active' | 'inactive';
  createdAt: string;
  updatedAt: string;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  idToken: string;
  expiresIn: number;
}

interface LoginCredentials {
  email: string;
  password: string;
}

interface RegisterData {
  email: string;
  password: string;
  name: string;
}
```

#### KPI Models

```typescript
interface KPI {
  kpiId: string;
  name: string;
  description: string;
  dataType: 'number' | 'percentage' | 'boolean' | 'text';
  category?: string;
  isActive: boolean;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

interface KPICategory {
  categoryId: string;
  name: string;
  description?: string;
}
```

#### Formula Models

```typescript
interface Formula {
  formulaId: string;
  name: string;
  expression: string; // Mathematical expression
  kpiWeights: KPIWeight[];
  isActive: boolean;
  department?: string; // Optional: for department-specific formulas
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

interface KPIWeight {
  kpiId: string;
  kpiName: string;
  weight: number; // Percentage (0-100)
}

interface FormulaValidation {
  isValid: boolean;
  totalWeight: number;
  errors: string[];
}
```

#### Performance Models

```typescript
interface PerformanceScore {
  scoreId: string;
  employeeId: string; // Reference to Employee table
  employeeName: string; // Denormalized for query performance
  department: string; // Denormalized for GSI queries
  position: string; // Job position (e.g., "Senior", "Junior", "Lead")
  period: string; // e.g., "2025-Q1" or "2025-1" for quarter 1
  overallScore: number;
  kpiScores: Record<string, number>; // { kpiId: score }
  formulaId?: string;
  calculatedAt: string;
}

interface PerformanceFilter {
  department?: string;
  startDate?: string;
  endDate?: string;
  employeeId?: string;
}
```

#### Upload Models

```typescript
interface FileUpload {
  uploadId: string;
  fileName: string;
  fileSize: number;
  fileType: 'csv' | 'xlsx';
  s3Key: string;
  uploadedBy: string;
  uploadedAt: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
}

interface ColumnMapping {
  fileColumn: string;
  kpiId: string;
  kpiName: string;
}

interface DataTable {
  tableId: string;
  tableName: string;
  columns: ColumnDefinition[];
  pattern: string; // Hash of column structure
  recordCount: number;
  createdAt: string;
}

interface ColumnDefinition {
  columnName: string;
  dataType: string;
  kpiId?: string;
}
```

#### Notification Models

```typescript
interface NotificationRule {
  ruleId: string;
  name: string;
  condition: string; // e.g., "score < 50"
  recipientCriteria: RecipientCriteria;
  emailTemplate: string;
  isActive: boolean;
  createdBy: string;
  createdAt: string;
}

interface RecipientCriteria {
  roles?: string[];
  departments?: string[];
  specificUsers?: string[];
}

interface NotificationHistory {
  notificationId: string;
  ruleId: string;
  sentTo: string[];
  sentAt: string;
  status: 'sent' | 'failed';
}
```

#### Chatbot Models

```typescript
interface ChatMessage {
  messageId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

interface ChatSession {
  sessionId: string;
  userId: string;
  messages: ChatMessage[];
  createdAt: string;
}
```


### DynamoDB Table Structures

#### Users Table
```
Partition Key: userId (String)
Attributes:
- email (String)
- name (String)
- role (String) - Admin, Manager, or Employee
- employeeId (String, optional) - Reference to Employees table
- department (String)
- avatarUrl (String)
- cognitoSub (String)
- isActive (Boolean)
- createdAt (String - ISO 8601)
- updatedAt (String - ISO 8601)

GSI: email-index (for login lookups)

Note: Users table is for authentication and authorization.
Not all users are employees (e.g., external contractors, admins).
One employee can have multiple user accounts (e.g., different roles/access levels).

**Role-Based Access Control:**
- User role (Admin/Manager/Employee) is stored in Users table
- Department information is stored in Employees table (NOT Users table)
- For Manager role-based access:
  1. Get user's role from Users table (Manager)
  2. Get user's employeeId from Users table
  3. Look up user's department from Employees table using employeeId
  4. Filter data by that department
- Example: Manager with employeeId "DEV-001" → Look up in Employees table → department "DEV" → Can only access DEV department data
```

#### Employees Table
```
Partition Key: employeeId (String) - e.g., "DEV-001", "QA-123", "SEC-456"
Attributes:
- employeeId (String) - Unique employee identifier
- name (String) - Employee full name
- department (String) - Department name (e.g., "DEV", "QA", "DAT", "SEC")
- position (String) - Job position/level (e.g., "Senior", "Junior", "Lead", "Manager")
- email (String, optional) - Employee email
- joinDate (String, optional) - ISO 8601 date
- status (String) - "active" or "inactive"
- createdAt (String - ISO 8601)
- updatedAt (String - ISO 8601)

GSI: department-index (for department filtering)

Note: Employees table is the master data for performance tracking.
Performance scores reference employeeId from this table.
Relationship: One employee can have multiple performance scores (one per period).
```

#### KPIs Table
```
Partition Key: kpiId (String)
Attributes:
- name (String)
- description (String)
- dataType (String)
- category (String)
- isActive (Boolean)
- createdBy (String)
- createdAt (String)
- updatedAt (String)

GSI: category-index (for category filtering)
```

#### Formulas Table
```
Partition Key: formulaId (String)
Attributes:
- name (String)
- expression (String)
- kpiWeights (List of Maps)
- isActive (Boolean)
- department (String)
- createdBy (String)
- createdAt (String)
- updatedAt (String)

GSI: department-index (for department-specific formulas)
```

#### PerformanceScores Table
```
Partition Key: employeeId (String) - Reference to Employees table
Sort Key: period (String) - Format: "YYYY-QN" (e.g., "2025-Q1")
Attributes:
- scoreId (String) - Unique score record identifier
- employeeId (String) - Reference to Employees table
- employeeName (String) - Denormalized for query performance
- department (String) - Denormalized for GSI queries
- position (String) - Job position (e.g., "Senior", "Junior", "Lead")
- period (String) - Time period (e.g., "2025-Q1")
- overallScore (Number) - Calculated overall performance score
- kpiScores (Map) - Map of KPI scores { kpiName: score }
- formulaId (String, optional) - Reference to formula used
- calculatedAt (String) - Timestamp when score was calculated
- createdAt (String - ISO 8601)
- updatedAt (String - ISO 8601)

GSI: department-period-index
- Partition Key: department (String)
- Sort Key: period (String)

Note: Performance scores are linked to Employees, not Users.
Query patterns:
1. Get all scores for an employee: Query by employeeId
2. Get employee score for specific period: Query by employeeId + period
3. Get all scores for department in period: Query GSI by department + period
```

#### DataTables Table
```
Partition Key: tableId (String)
Attributes:
- tableName (String)
- columns (List of Maps)
- pattern (String)
- recordCount (Number)
- createdBy (String)
- createdAt (String)
- updatedAt (String)
```

#### NotificationRules Table
```
Partition Key: ruleId (String)
Attributes:
- name (String)
- condition (String)
- recipientCriteria (Map)
- emailTemplate (String)
- isActive (Boolean)
- createdBy (String)
- createdAt (String)
```

#### NotificationHistory Table
```
Partition Key: notificationId (String)
Sort Key: sentAt (String)
Attributes:
- ruleId (String)
- sentTo (List)
- status (String)
```


## API Integration

### API Gateway Endpoints

All endpoints are prefixed with the API Gateway base URL (e.g., `https://api.insighthr.com/v1`)

#### Authentication Endpoints

```
POST /auth/login
Request: { email, password }
Response: { user, tokens }

POST /auth/register
Request: { email, password, name }
Response: { user, tokens }

POST /auth/google
Request: { googleToken }
Response: { user, tokens }

POST /auth/refresh
Request: { refreshToken }
Response: { tokens }

POST /auth/forgot-password
Request: { email }
Response: { message }

POST /auth/reset-password
Request: { email, code, newPassword }
Response: { message }
```

#### User Endpoints

```
GET /users/me
Response: { user }

PUT /users/me
Request: { name, avatarUrl, ... }
Response: { user }

GET /users (Admin only)
Response: { users[] }

POST /users (Admin only)
Request: { email, name, role, employeeId, department }
Response: { user }

PUT /users/:userId (Admin only)
Request: { name, role, employeeId, department }
Response: { user }
```

#### KPI Endpoints

```
GET /kpis
Response: { kpis[] }

GET /kpis/:kpiId
Response: { kpi }

POST /kpis (Admin only)
Request: { name, description, dataType, category }
Response: { kpi }

PUT /kpis/:kpiId (Admin only)
Request: { name, description, dataType, category }
Response: { kpi }

DELETE /kpis/:kpiId (Admin only)
Response: { message }
Note: Soft delete - sets isActive to false
```

#### Formula Endpoints

```
GET /formulas
Response: { formulas[] }

GET /formulas/:formulaId
Response: { formula }

POST /formulas (Admin only)
Request: { name, expression, kpiWeights, department }
Response: { formula }

PUT /formulas/:formulaId (Admin only)
Request: { name, expression, kpiWeights, isActive }
Response: { formula }

POST /formulas/:formulaId/validate
Request: { kpiWeights }
Response: { isValid, totalWeight, errors }
```

#### Upload Endpoints

```
POST /upload/presigned-url
Request: { fileName, fileType }
Response: { uploadUrl, s3Key }

POST /upload/process
Request: { s3Key, columnMappings, tableId? }
Response: { uploadId, status }

GET /upload/:uploadId/status
Response: { status, progress, errors? }

GET /tables
Response: { tables[] }

POST /tables/match
Request: { columns[] }
Response: { matchType, suggestedTable? }
```

#### Performance Endpoints

```
GET /performance
Query: ?department=&startDate=&endDate=&employeeId=
Response: { scores[] }

GET /performance/:employeeId
Response: { scores[] }

POST /performance/export
Request: { filters, format }
Response: { downloadUrl }
```

#### Chatbot Endpoints

```
POST /chatbot/message
Request: { message, sessionId? }
Response: { reply, sessionId }

GET /chatbot/session/:sessionId
Response: { messages[] }
```

#### Notification Endpoints

```
GET /notifications/rules (Admin only)
Response: { rules[] }

POST /notifications/rules (Admin only)
Request: { name, condition, recipientCriteria, emailTemplate }
Response: { rule }

PUT /notifications/rules/:ruleId (Admin only)
Request: { name, condition, isActive }
Response: { rule }

GET /notifications/history (Admin only)
Response: { history[] }
```


### API Service Implementation Pattern

```typescript
// services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 30000,
});

// Request interceptor - add auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - handle token refresh
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired - attempt refresh
      const refreshToken = localStorage.getItem('refreshToken');
      if (refreshToken) {
        try {
          const { data } = await axios.post('/auth/refresh', { refreshToken });
          localStorage.setItem('accessToken', data.tokens.accessToken);
          // Retry original request
          error.config.headers.Authorization = `Bearer ${data.tokens.accessToken}`;
          return axios(error.config);
        } catch {
          // Refresh failed - redirect to login
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);

export default api;
```

```typescript
// services/kpiService.ts
import api from './api';
import { KPI } from '../types/kpi.types';

export const kpiService = {
  getAll: async (): Promise<KPI[]> => {
    const { data } = await api.get('/kpis');
    return data.kpis;
  },

  getById: async (kpiId: string): Promise<KPI> => {
    const { data } = await api.get(`/kpis/${kpiId}`);
    return data.kpi;
  },

  create: async (kpi: Partial<KPI>): Promise<KPI> => {
    const { data } = await api.post('/kpis', kpi);
    return data.kpi;
  },

  update: async (kpiId: string, kpi: Partial<KPI>): Promise<KPI> => {
    const { data } = await api.put(`/kpis/${kpiId}`, kpi);
    return data.kpi;
  },

  disable: async (kpiId: string): Promise<void> => {
    await api.delete(`/kpis/${kpiId}`);
  },
};
```


## State Management

### Zustand Store Design

Using Zustand for lightweight, TypeScript-friendly state management.

```typescript
// store/authStore.ts
import { create } from 'zustand';
import { User, AuthTokens } from '../types/auth.types';

interface AuthState {
  user: User | null;
  tokens: AuthTokens | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  loginWithGoogle: (googleToken: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  tokens: null,
  isAuthenticated: false,
  isLoading: true,
  
  login: async (email, password) => {
    const { data } = await authService.login(email, password);
    localStorage.setItem('accessToken', data.tokens.accessToken);
    localStorage.setItem('refreshToken', data.tokens.refreshToken);
    set({ user: data.user, tokens: data.tokens, isAuthenticated: true });
  },
  
  loginWithGoogle: async (googleToken) => {
    const { data } = await authService.googleLogin(googleToken);
    localStorage.setItem('accessToken', data.tokens.accessToken);
    localStorage.setItem('refreshToken', data.tokens.refreshToken);
    set({ user: data.user, tokens: data.tokens, isAuthenticated: true });
  },
  
  register: async (registerData) => {
    const { data } = await authService.register(registerData);
    localStorage.setItem('accessToken', data.tokens.accessToken);
    localStorage.setItem('refreshToken', data.tokens.refreshToken);
    set({ user: data.user, tokens: data.tokens, isAuthenticated: true });
  },
  
  logout: () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    set({ user: null, tokens: null, isAuthenticated: false });
  },
  
  refreshUser: async () => {
    try {
      const user = await authService.getCurrentUser();
      set({ user, isAuthenticated: true, isLoading: false });
    } catch {
      set({ isLoading: false });
    }
  },
}));
```

```typescript
// store/kpiStore.ts
import { create } from 'zustand';
import { KPI } from '../types/kpi.types';

interface KPIState {
  kpis: KPI[];
  isLoading: boolean;
  error: string | null;
  fetchKPIs: () => Promise<void>;
  createKPI: (kpi: Partial<KPI>) => Promise<void>;
  updateKPI: (kpiId: string, kpi: Partial<KPI>) => Promise<void>;
  disableKPI: (kpiId: string) => Promise<void>;
}

export const useKPIStore = create<KPIState>((set, get) => ({
  kpis: [],
  isLoading: false,
  error: null,
  
  fetchKPIs: async () => {
    set({ isLoading: true, error: null });
    try {
      const kpis = await kpiService.getAll();
      set({ kpis, isLoading: false });
    } catch (error) {
      set({ error: error.message, isLoading: false });
    }
  },
  
  createKPI: async (kpi) => {
    const newKPI = await kpiService.create(kpi);
    set({ kpis: [...get().kpis, newKPI] });
  },
  
  updateKPI: async (kpiId, kpi) => {
    const updatedKPI = await kpiService.update(kpiId, kpi);
    set({
      kpis: get().kpis.map((k) => (k.kpiId === kpiId ? updatedKPI : k)),
    });
  },
  
  disableKPI: async (kpiId) => {
    await kpiService.disable(kpiId);
    set({
      kpis: get().kpis.map((k) =>
        k.kpiId === kpiId ? { ...k, isActive: false } : k
      ),
    });
  },
}));
```

```typescript
// store/performanceStore.ts
import { create } from 'zustand';
import { PerformanceScore, PerformanceFilter } from '../types/performance.types';

interface PerformanceState {
  scores: PerformanceScore[];
  filters: PerformanceFilter;
  isLoading: boolean;
  fetchScores: () => Promise<void>;
  setFilters: (filters: Partial<PerformanceFilter>) => void;
  exportData: (format: 'csv' | 'xlsx' | 'pdf') => Promise<string>;
}

export const usePerformanceStore = create<PerformanceState>((set, get) => ({
  scores: [],
  filters: {},
  isLoading: false,
  
  fetchScores: async () => {
    set({ isLoading: true });
    const scores = await performanceService.getScores(get().filters);
    set({ scores, isLoading: false });
  },
  
  setFilters: (filters) => {
    set({ filters: { ...get().filters, ...filters } });
    get().fetchScores();
  },
  
  exportData: async (format) => {
    const url = await performanceService.export(get().filters, format);
    return url;
  },
}));
```


## Routing

### React Router Configuration

```typescript
// router.tsx
import { createBrowserRouter, Navigate } from 'react-router-dom';
import MainLayout from './components/layout/MainLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import AdminPage from './pages/AdminPage';
import UploadPage from './pages/UploadPage';
import ChatbotPage from './pages/ChatbotPage';
import ProfilePage from './pages/ProfilePage';
import NotFoundPage from './pages/NotFoundPage';
import ProtectedRoute from './components/auth/ProtectedRoute';

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/',
    element: <ProtectedRoute><MainLayout /></ProtectedRoute>,
    children: [
      {
        index: true,
        element: <Navigate to="/dashboard" replace />,
      },
      {
        path: 'dashboard',
        element: <DashboardPage />,
      },
      {
        path: 'admin',
        element: <ProtectedRoute requiredRole="Admin"><AdminPage /></ProtectedRoute>,
      },
      {
        path: 'upload',
        element: <ProtectedRoute requiredRole={['Admin', 'Manager']}><UploadPage /></ProtectedRoute>,
      },
      {
        path: 'chatbot',
        element: <ChatbotPage />,
      },
      {
        path: 'profile',
        element: <ProfilePage />,
      },
    ],
  },
  {
    path: '*',
    element: <NotFoundPage />,
  },
]);
```

```typescript
// components/auth/ProtectedRoute.tsx
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: string | string[];
}

export default function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const { isAuthenticated, user } = useAuthStore();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole) {
    const roles = Array.isArray(requiredRole) ? requiredRole : [requiredRole];
    if (!roles.includes(user?.role || '')) {
      return <Navigate to="/dashboard" replace />;
    }
  }

  return <>{children}</>;
}
```


## UI/UX Design

### Frutiger Aero Theme

```typescript
// styles/theme.ts
export const theme = {
  colors: {
    primary: {
      50: '#e6f7f7',
      100: '#b3e8e8',
      200: '#80d9d9',
      300: '#4dcaca',
      400: '#1abbbb',
      500: '#00a8a8', // Main primary color
      600: '#008a8a',
      700: '#006b6b',
      800: '#004d4d',
      900: '#002e2e',
    },
    secondary: {
      50: '#e6f4e6',
      100: '#b3e0b3',
      200: '#80cc80',
      300: '#4db84d',
      400: '#1aa41a',
      500: '#009000', // Main secondary color
      600: '#007500',
      700: '#005a00',
      800: '#004000',
      900: '#002500',
    },
    neutral: {
      50: '#f9fafb',
      100: '#f3f4f6',
      200: '#e5e7eb',
      300: '#d1d5db',
      400: '#9ca3af',
      500: '#6b7280',
      600: '#4b5563',
      700: '#374151',
      800: '#1f2937',
      900: '#111827',
    },
    success: '#10b981',
    warning: '#f59e0b',
    error: '#ef4444',
    info: '#3b82f6',
  },
  typography: {
    fontFamily: {
      sans: "'Inter', 'Segoe UI', 'Roboto', sans-serif",
      mono: "'Fira Code', 'Courier New', monospace",
    },
    fontSize: {
      xs: '0.75rem',
      sm: '0.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem',
      '4xl': '2.25rem',
    },
    fontWeight: {
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
    },
  },
  spacing: {
    xs: '0.25rem',
    sm: '0.5rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
    '2xl': '3rem',
  },
  borderRadius: {
    sm: '0.25rem',
    md: '0.5rem',
    lg: '0.75rem',
    xl: '1rem',
    full: '9999px',
  },
  shadows: {
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
  },
};
```

### Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│                        Header                            │
│  [Logo] [Nav: Dashboard | Upload | Chatbot] [Profile ▼] │
└─────────────────────────────────────────────────────────┘
┌──────────┬──────────────────────────────────────────────┐
│          │                                              │
│ Sidebar  │           Main Content Area                  │
│          │                                              │
│ [Admin]  │  ┌────────────────────────────────────────┐ │
│ - KPIs   │  │                                        │ │
│ - Formula│  │         Page Content                   │ │
│ - Users  │  │                                        │ │
│ - Notify │  │                                        │ │
│          │  └────────────────────────────────────────┘ │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### Key UI Components

#### Button Component
```typescript
// components/common/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
}

// Variants:
// - primary: Green/blue gradient background
// - secondary: Outlined with hover effect
// - outline: Border only
// - ghost: No background, text only
```

#### Input Component
```typescript
// components/common/Input.tsx
interface InputProps {
  type?: 'text' | 'email' | 'password' | 'number';
  label?: string;
  placeholder?: string;
  error?: string;
  disabled?: boolean;
  value: string;
  onChange: (value: string) => void;
}

// Features:
// - Floating label animation
// - Error state with red border
// - Icon support (prefix/suffix)
```

#### Modal Component
```typescript
// components/common/Modal.tsx
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}

// Features:
// - Backdrop with blur effect
// - Smooth fade-in animation
// - ESC key to close
// - Click outside to close
```


## Error Handling

### Error Handling Strategy

#### API Error Handling

```typescript
// types/api.types.ts
interface APIError {
  code: string;
  message: string;
  details?: Record<string, any>;
}

// utils/errorHandler.ts
export const handleAPIError = (error: any): string => {
  if (error.response) {
    // Server responded with error
    const apiError: APIError = error.response.data;
    
    switch (error.response.status) {
      case 400:
        return apiError.message || 'Invalid request. Please check your input.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return apiError.message || 'An unexpected error occurred.';
    }
  } else if (error.request) {
    // Request made but no response
    return 'Network error. Please check your connection.';
  } else {
    // Something else happened
    return error.message || 'An unexpected error occurred.';
  }
};
```

#### Component Error Boundaries

```typescript
// components/common/ErrorBoundary.tsx
import React from 'react';

interface Props {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    // Could send to error tracking service here
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="error-container">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => window.location.reload()}>
            Reload Page
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

#### Form Validation

```typescript
// utils/validators.ts
export const validators = {
  email: (value: string): string | null => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!value) return 'Email is required';
    if (!emailRegex.test(value)) return 'Invalid email format';
    return null;
  },

  password: (value: string): string | null => {
    if (!value) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!/[A-Z]/.test(value)) return 'Password must contain an uppercase letter';
    if (!/[a-z]/.test(value)) return 'Password must contain a lowercase letter';
    if (!/[0-9]/.test(value)) return 'Password must contain a number';
    return null;
  },

  required: (value: any): string | null => {
    if (!value || (typeof value === 'string' && !value.trim())) {
      return 'This field is required';
    }
    return null;
  },

  number: (value: string): string | null => {
    if (!value) return 'Number is required';
    if (isNaN(Number(value))) return 'Must be a valid number';
    return null;
  },

  percentage: (value: string): string | null => {
    const num = Number(value);
    if (isNaN(num)) return 'Must be a valid number';
    if (num < 0 || num > 100) return 'Must be between 0 and 100';
    return null;
  },
};
```

### User Feedback

#### Toast Notifications

```typescript
// components/common/Toast.tsx
interface ToastProps {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

// Usage:
// showToast({ type: 'success', message: 'KPI created successfully!' });
// showToast({ type: 'error', message: 'Failed to save formula' });
```

#### Loading States

```typescript
// components/common/LoadingSpinner.tsx
interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  fullScreen?: boolean;
}

// Usage in components:
{isLoading ? <LoadingSpinner /> : <DataTable data={scores} />}
```

#### Empty States

```typescript
// components/common/EmptyState.tsx
interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

// Usage:
<EmptyState
  title="No KPIs yet"
  description="Create your first KPI to get started"
  action={{ label: 'Create KPI', onClick: openKPIForm }}
/>
```


## Testing Strategy

### Testing Approach for MVP

Given the 1-month timeline, testing will focus on critical paths and core functionality.

#### Unit Testing

**Priority Components to Test:**
- Validators (email, password, percentage)
- Formatters and utility functions
- API service functions
- State management stores

**Testing Library:** Vitest + React Testing Library

```typescript
// Example: validators.test.ts
import { describe, it, expect } from 'vitest';
import { validators } from '../utils/validators';

describe('validators', () => {
  describe('email', () => {
    it('should return null for valid email', () => {
      expect(validators.email('test@example.com')).toBeNull();
    });

    it('should return error for invalid email', () => {
      expect(validators.email('invalid')).toBe('Invalid email format');
    });

    it('should return error for empty email', () => {
      expect(validators.email('')).toBe('Email is required');
    });
  });

  describe('percentage', () => {
    it('should return null for valid percentage', () => {
      expect(validators.percentage('50')).toBeNull();
    });

    it('should return error for value > 100', () => {
      expect(validators.percentage('150')).toBe('Must be between 0 and 100');
    });
  });
});
```

#### Integration Testing

**Priority Flows to Test:**
- Login flow (email/password and Google OAuth)
- KPI creation and editing
- Formula builder validation
- File upload and column mapping

```typescript
// Example: LoginForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import LoginForm from '../components/auth/LoginForm';

describe('LoginForm', () => {
  it('should submit form with valid credentials', async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByLabelText('Password'), {
      target: { value: 'Password123' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Login' }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'Password123',
      });
    });
  });

  it('should display validation errors', async () => {
    render(<LoginForm onSubmit={vi.fn()} />);

    fireEvent.click(screen.getByRole('button', { name: 'Login' }));

    await waitFor(() => {
      expect(screen.getByText('Email is required')).toBeInTheDocument();
      expect(screen.getByText('Password is required')).toBeInTheDocument();
    });
  });
});
```

#### E2E Testing (Optional for MVP)

If time permits, basic E2E tests using Playwright for critical user journeys:
- Complete login to dashboard flow
- Admin creates KPI and formula
- User uploads file and views results

### Manual Testing Checklist

**Authentication:**
- [ ] Email/password login
- [ ] Google OAuth login
- [ ] Self-registration
- [ ] Password reset
- [ ] Session persistence
- [ ] Token refresh

**Admin Panel:**
- [ ] Create KPI with all data types
- [ ] Edit KPI
- [ ] Disable KPI
- [ ] Create formula with autocomplete
- [ ] Validate formula weights (sum = 100%)
- [ ] Multiple active formulas

**File Upload:**
- [ ] Upload CSV file
- [ ] Upload Excel file
- [ ] Column mapping interface
- [ ] Pattern detection (exact/similar/new)
- [ ] Data validation
- [ ] Large file handling (10,000+ records)

**Dashboard:**
- [ ] View performance data by role
- [ ] Filter by department, date, employee
- [ ] Line chart display
- [ ] Bar chart display
- [ ] Pie chart display
- [ ] Export to CSV
- [ ] Manual refresh

**Chatbot:**
- [ ] Send message
- [ ] Receive response
- [ ] Conversation history
- [ ] Data query accuracy

**Profile:**
- [ ] View profile
- [ ] Edit personal fields
- [ ] Restricted company fields (non-admin)
- [ ] Upload avatar

**Responsive Design:**
- [ ] Desktop (1920x1080)
- [ ] Laptop (1366x768)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)


## Deployment

### Build Configuration

#### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          charts: ['recharts'],
          aws: ['aws-amplify'],
        },
      },
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: process.env.VITE_API_BASE_URL,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
```

#### Environment Variables

```bash
# .env.development
VITE_API_BASE_URL=http://localhost:4000/v1
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxx
VITE_COGNITO_CLIENT_ID=xxxxx
VITE_GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
VITE_S3_BUCKET=insighthr-uploads-dev

# .env.production
VITE_API_BASE_URL=https://api.insighthr.com/v1
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxx
VITE_COGNITO_CLIENT_ID=xxxxx
VITE_GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
VITE_S3_BUCKET=insighthr-uploads-prod
```

### AWS Deployment

#### S3 Bucket Configuration

```bash
# Create S3 bucket for static hosting
aws s3 mb s3://insighthr-web-app

# Enable static website hosting
aws s3 website s3://insighthr-web-app \
  --index-document index.html \
  --error-document index.html

# Set bucket policy for public read
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::insighthr-web-app/*"
    }
  ]
}
```

#### CloudFront Distribution

```yaml
# CloudFront configuration
DistributionConfig:
  Origins:
    - DomainName: insighthr-web-app.s3.amazonaws.com
      Id: S3-insighthr-web-app
      S3OriginConfig:
        OriginAccessIdentity: ""
  DefaultCacheBehavior:
    TargetOriginId: S3-insighthr-web-app
    ViewerProtocolPolicy: redirect-to-https
    AllowedMethods: [GET, HEAD, OPTIONS]
    CachedMethods: [GET, HEAD]
    Compress: true
    DefaultTTL: 86400
    MaxTTL: 31536000
    MinTTL: 0
  CustomErrorResponses:
    - ErrorCode: 404
      ResponseCode: 200
      ResponsePagePath: /index.html
    - ErrorCode: 403
      ResponseCode: 200
      ResponsePagePath: /index.html
  ViewerCertificate:
    AcmCertificateArn: arn:aws:acm:us-east-1:xxxxx:certificate/xxxxx
    SslSupportMethod: sni-only
```

#### Deployment Script

```bash
#!/bin/bash
# deploy.sh

# Build the application
echo "Building application..."
npm run build

# Upload to S3
echo "Uploading to S3..."
aws s3 sync dist/ s3://insighthr-web-app \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

# Upload index.html with no-cache
aws s3 cp dist/index.html s3://insighthr-web-app/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

echo "Deployment complete!"
```

### CI/CD Pipeline (Optional)

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Build
        run: npm run build
        env:
          VITE_API_BASE_URL: ${{ secrets.API_BASE_URL }}
          VITE_COGNITO_USER_POOL_ID: ${{ secrets.COGNITO_USER_POOL_ID }}
          VITE_COGNITO_CLIENT_ID: ${{ secrets.COGNITO_CLIENT_ID }}
          
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
          
      - name: Deploy to S3
        run: |
          aws s3 sync dist/ s3://insighthr-web-app --delete
          
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```


## Performance Optimization

### Code Splitting

```typescript
// Lazy load pages for better initial load time
import { lazy, Suspense } from 'react';
import LoadingSpinner from './components/common/LoadingSpinner';

const DashboardPage = lazy(() => import('./pages/DashboardPage'));
const AdminPage = lazy(() => import('./pages/AdminPage'));
const ChatbotPage = lazy(() => import('./pages/ChatbotPage'));

// Wrap with Suspense
<Suspense fallback={<LoadingSpinner fullScreen />}>
  <DashboardPage />
</Suspense>
```

### Asset Optimization

- **Images**: Use WebP format with fallback to PNG/JPG
- **Icons**: Use SVG sprites or icon fonts
- **Fonts**: Subset fonts to include only used characters
- **CSS**: Use CSS modules or Tailwind for tree-shaking

### Caching Strategy

```typescript
// Service Worker for offline support (optional for MVP)
// public/sw.js
const CACHE_NAME = 'insighthr-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/static/css/main.css',
  '/static/js/main.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(urlsToCache))
  );
});
```

### API Response Caching

```typescript
// Simple in-memory cache for API responses
class APICache {
  private cache = new Map<string, { data: any; timestamp: number }>();
  private ttl = 5 * 60 * 1000; // 5 minutes

  get(key: string): any | null {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    if (Date.now() - cached.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }

  set(key: string, data: any): void {
    this.cache.set(key, { data, timestamp: Date.now() });
  }

  clear(): void {
    this.cache.clear();
  }
}

export const apiCache = new APICache();
```

### Bundle Size Optimization

```json
// package.json - Use specific imports to reduce bundle size
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "zustand": "^4.4.7",
    "axios": "^1.6.2",
    "recharts": "^2.10.3",
    "aws-amplify": "^6.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.8",
    "vitest": "^1.0.4",
    "@testing-library/react": "^14.1.2"
  }
}
```

**Bundle Analysis:**
```bash
# Analyze bundle size
npm run build -- --mode analyze
```

### Performance Metrics Goals

- **First Contentful Paint (FCP)**: < 1.5s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Time to Interactive (TTI)**: < 3.0s
- **Total Bundle Size**: < 500KB (gzipped)
- **API Response Time**: < 500ms (average)


## Security Considerations

### Authentication Security

**Token Management:**
- Store access tokens in memory (React state) when possible
- Store refresh tokens in httpOnly cookies (if backend supports) or localStorage with encryption
- Implement token rotation on refresh
- Clear all tokens on logout

**Cognito Integration:**
```typescript
// services/authService.ts
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const userPool = new CognitoUserPool({
  UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
});

export const authService = {
  login: (email: string, password: string): Promise<AuthTokens> => {
    return new Promise((resolve, reject) => {
      const user = new CognitoUser({ Username: email, Pool: userPool });
      const authDetails = new AuthenticationDetails({ Username: email, Password: password });
      
      user.authenticateUser(authDetails, {
        onSuccess: (result) => {
          resolve({
            accessToken: result.getAccessToken().getJwtToken(),
            refreshToken: result.getRefreshToken().getToken(),
            idToken: result.getIdToken().getJwtToken(),
            expiresIn: result.getAccessToken().getExpiration(),
          });
        },
        onFailure: (err) => reject(err),
      });
    });
  },
};
```

### XSS Prevention

- Sanitize all user inputs before rendering
- Use React's built-in XSS protection (JSX escaping)
- Avoid `dangerouslySetInnerHTML` unless absolutely necessary
- Implement Content Security Policy (CSP) headers

```html
<!-- index.html -->
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline'; 
               style-src 'self' 'unsafe-inline'; 
               img-src 'self' data: https:; 
               connect-src 'self' https://api.insighthr.com https://cognito-idp.us-east-1.amazonaws.com;">
```

### CSRF Protection

- API Gateway validates JWT tokens
- Use SameSite cookie attribute for refresh tokens
- Implement CORS properly on API Gateway

### Input Validation

```typescript
// Sanitize user inputs
import DOMPurify from 'dompurify';

export const sanitizeInput = (input: string): string => {
  return DOMPurify.sanitize(input, { ALLOWED_TAGS: [] });
};

// Use in forms
const handleSubmit = (data: FormData) => {
  const sanitized = {
    name: sanitizeInput(data.name),
    description: sanitizeInput(data.description),
  };
  // Submit sanitized data
};
```

### File Upload Security

```typescript
// Validate file types and sizes
const ALLOWED_FILE_TYPES = ['text/csv', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'];
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

export const validateFile = (file: File): string | null => {
  if (!ALLOWED_FILE_TYPES.includes(file.type)) {
    return 'Invalid file type. Only CSV and Excel files are allowed.';
  }
  
  if (file.size > MAX_FILE_SIZE) {
    return 'File size exceeds 50MB limit.';
  }
  
  return null;
};
```

### Secure S3 Upload

```typescript
// Get presigned URL from backend, never expose AWS credentials in frontend
export const uploadToS3 = async (file: File): Promise<string> => {
  // 1. Get presigned URL from backend
  const { uploadUrl, s3Key } = await uploadService.getPresignedUrl(file.name, file.type);
  
  // 2. Upload directly to S3 using presigned URL
  await axios.put(uploadUrl, file, {
    headers: { 'Content-Type': file.type },
  });
  
  return s3Key;
};
```

### Environment Variables

- Never commit `.env` files to version control
- Use different credentials for dev/staging/production
- Rotate API keys regularly
- Use AWS Secrets Manager for sensitive values in production

### Rate Limiting

- Implement on API Gateway level
- Show user-friendly messages when rate limited
- Implement exponential backoff for retries

```typescript
// Exponential backoff for API retries
const retryWithBackoff = async (fn: () => Promise<any>, maxRetries = 3): Promise<any> => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      const delay = Math.pow(2, i) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
};
```


## Development Workflow

### Project Setup

```bash
# Initialize project
npm create vite@latest insighthr-web -- --template react-ts
cd insighthr-web

# Install dependencies
npm install react-router-dom zustand axios recharts
npm install amazon-cognito-identity-js
npm install -D @types/node tailwindcss postcss autoprefixer
npm install -D vitest @testing-library/react @testing-library/jest-dom

# Initialize Tailwind CSS
npx tailwindcss init -p
```

### Package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "format": "prettier --write \"src/**/*.{ts,tsx,css}\"",
    "type-check": "tsc --noEmit",
    "deploy:dev": "npm run build && ./scripts/deploy-dev.sh",
    "deploy:prod": "npm run build && ./scripts/deploy-prod.sh"
  }
}
```

### Git Workflow

```bash
# Branch naming convention
feature/kpi-management
feature/formula-builder
feature/file-upload
feature/dashboard-charts
feature/chatbot-integration
bugfix/login-validation
hotfix/token-refresh

# Commit message format
feat: add KPI creation form
fix: resolve formula validation bug
docs: update API integration guide
style: format code with prettier
refactor: extract chart components
test: add unit tests for validators
```

### Code Review Checklist

- [ ] TypeScript types are properly defined
- [ ] Components are properly typed with interfaces
- [ ] Error handling is implemented
- [ ] Loading states are handled
- [ ] User feedback (toasts, errors) is provided
- [ ] Code follows project structure conventions
- [ ] No console.logs in production code
- [ ] Sensitive data is not exposed
- [ ] API calls use proper error handling
- [ ] Components are reasonably sized (< 300 lines)

### Development Timeline (1 Month)

**Week 1: Foundation**
- Day 1-2: Project setup, routing, authentication
- Day 3-4: Layout components, theme implementation
- Day 5: API service layer, state management setup

**Week 2: Admin Features**
- Day 6-7: KPI management (CRUD)
- Day 8-9: Formula builder with autocomplete
- Day 10: User management, notification rules

**Week 3: Core Features**
- Day 11-12: File upload and column mapping
- Day 13-14: Dashboard with charts (line, bar, pie)
- Day 15: Data filtering and export

**Week 4: Integration & Polish**
- Day 16-17: Chatbot integration
- Day 18-19: Profile management, final integrations
- Day 20: Testing, bug fixes, deployment

### MVP Feature Priority

**Must Have (P0):**
- Authentication (email/password, Google OAuth)
- KPI management
- Formula builder
- File upload with column mapping
- Dashboard with 3 chart types
- CSV export

**Should Have (P1):**
- Chatbot integration
- Notification rules
- Profile management
- Data validation

**Nice to Have (P2):**
- Advanced filtering
- Excel/PDF export
- Formula versioning
- Dark mode


## Integration with Python Lambda & DynamoDB

### API Request/Response Flow

```
React Component
    ↓
Service Layer (kpiService.ts)
    ↓
Axios Instance (api.ts) + JWT Token
    ↓
API Gateway Endpoint (/kpis)
    ↓
Python Lambda Function (kpi_handler.py)
    ↓
DynamoDB Table (KPIs)
    ↓
Response back through the chain
```

### Example Integration Pattern

#### Frontend Service

```typescript
// services/kpiService.ts
import api from './api';
import { KPI } from '../types/kpi.types';

export const kpiService = {
  getAll: async (): Promise<KPI[]> => {
    const { data } = await api.get('/kpis');
    return data.kpis;
  },

  create: async (kpi: Partial<KPI>): Promise<KPI> => {
    const { data } = await api.post('/kpis', kpi);
    return data.kpi;
  },
};
```

#### Python Lambda Handler (Backend Reference)

```python
# lambda/kpi_handler.py
import json
import boto3
from datetime import datetime
import uuid

dynamodb = boto3.resource('dynamodb')
kpis_table = dynamodb.Table('KPIs')

def lambda_handler(event, context):
    http_method = event['httpMethod']
    
    if http_method == 'GET':
        return get_kpis(event)
    elif http_method == 'POST':
        return create_kpi(event)
    
def get_kpis(event):
    response = kpis_table.scan(
        FilterExpression='isActive = :active',
        ExpressionAttributeValues={':active': True}
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'kpis': response['Items']
        })
    }

def create_kpi(event):
    body = json.loads(event['body'])
    
    kpi = {
        'kpiId': str(uuid.uuid4()),
        'name': body['name'],
        'description': body['description'],
        'dataType': body['dataType'],
        'category': body.get('category', ''),
        'isActive': True,
        'createdBy': event['requestContext']['authorizer']['claims']['sub'],
        'createdAt': datetime.utcnow().isoformat(),
        'updatedAt': datetime.utcnow().isoformat()
    }
    
    kpis_table.put_item(Item=kpi)
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'kpi': kpi
        })
    }
```

### DynamoDB Query Patterns

#### Frontend Query Examples

```typescript
// Get all KPIs
const kpis = await kpiService.getAll();

// Get performance scores with filters
const scores = await performanceService.getScores({
  department: 'Engineering',
  startDate: '2024-01-01',
  endDate: '2024-03-31'
});

// Upload file and process
const s3Key = await uploadService.uploadFile(file);
await uploadService.processFile(s3Key, columnMappings);
```

#### Backend DynamoDB Operations (Reference)

```python
# Query by partition key
response = table.get_item(Key={'kpiId': kpi_id})

# Query with sort key
response = table.query(
    KeyConditionExpression='employeeId = :emp_id AND period BETWEEN :start AND :end',
    ExpressionAttributeValues={
        ':emp_id': employee_id,
        ':start': start_period,
        ':end': end_period
    }
)

# Scan with filter
response = table.scan(
    FilterExpression='department = :dept AND isActive = :active',
    ExpressionAttributeValues={
        ':dept': 'Engineering',
        ':active': True
    }
)

# Update item
table.update_item(
    Key={'kpiId': kpi_id},
    UpdateExpression='SET #name = :name, updatedAt = :updated',
    ExpressionAttributeNames={'#name': 'name'},
    ExpressionAttributeValues={
        ':name': new_name,
        ':updated': datetime.utcnow().isoformat()
    }
)

# Soft delete
table.update_item(
    Key={'kpiId': kpi_id},
    UpdateExpression='SET isActive = :active',
    ExpressionAttributeValues={':active': False}
)
```

### Type Alignment

Ensure TypeScript types match DynamoDB schema:

```typescript
// Frontend type
interface KPI {
  kpiId: string;        // DynamoDB: kpiId (String)
  name: string;         // DynamoDB: name (String)
  description: string;  // DynamoDB: description (String)
  dataType: string;     // DynamoDB: dataType (String)
  category?: string;    // DynamoDB: category (String)
  isActive: boolean;    // DynamoDB: isActive (Boolean)
  createdBy: string;    // DynamoDB: createdBy (String)
  createdAt: string;    // DynamoDB: createdAt (String - ISO 8601)
  updatedAt: string;    // DynamoDB: updatedAt (String - ISO 8601)
}
```

### Error Handling Between Layers

```typescript
// Frontend handles Lambda errors
try {
  const kpi = await kpiService.create(newKPI);
  showToast({ type: 'success', message: 'KPI created successfully!' });
} catch (error) {
  if (error.response?.status === 400) {
    showToast({ type: 'error', message: 'Invalid KPI data' });
  } else if (error.response?.status === 409) {
    showToast({ type: 'error', message: 'KPI with this name already exists' });
  } else {
    showToast({ type: 'error', message: 'Failed to create KPI' });
  }
}
```

```python
# Lambda returns structured errors
def create_kpi(event):
    try:
        body = json.loads(event['body'])
        
        # Validation
        if not body.get('name'):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'code': 'VALIDATION_ERROR',
                    'message': 'KPI name is required'
                })
            }
        
        # Check for duplicates
        existing = kpis_table.query(
            IndexName='name-index',
            KeyConditionExpression='name = :name',
            ExpressionAttributeValues={':name': body['name']}
        )
        
        if existing['Items']:
            return {
                'statusCode': 409,
                'body': json.dumps({
                    'code': 'DUPLICATE_KPI',
                    'message': 'KPI with this name already exists'
                })
            }
        
        # Create KPI...
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'code': 'INTERNAL_ERROR',
                'message': str(e)
            })
        }
```


## Accessibility

### WCAG 2.1 Level AA Compliance

#### Keyboard Navigation
- All interactive elements accessible via keyboard
- Visible focus indicators
- Logical tab order
- Skip to main content link

#### Screen Reader Support
```typescript
// Use semantic HTML and ARIA labels
<button aria-label="Create new KPI">
  <PlusIcon />
</button>

<input
  type="text"
  id="kpi-name"
  aria-describedby="kpi-name-error"
  aria-invalid={!!error}
/>
{error && <span id="kpi-name-error" role="alert">{error}</span>}

<nav aria-label="Main navigation">
  <ul>
    <li><a href="/dashboard">Dashboard</a></li>
    <li><a href="/admin">Admin</a></li>
  </ul>
</nav>
```

#### Color Contrast
- Text: Minimum 4.5:1 contrast ratio
- Large text: Minimum 3:1 contrast ratio
- Interactive elements: Clear visual states

```typescript
// Theme with accessible colors
export const theme = {
  colors: {
    text: {
      primary: '#111827',    // High contrast on white
      secondary: '#4b5563',  // Meets 4.5:1 ratio
      disabled: '#9ca3af',
    },
    background: {
      primary: '#ffffff',
      secondary: '#f9fafb',
    },
  },
};
```

#### Form Accessibility
```typescript
<label htmlFor="email">Email Address</label>
<input
  id="email"
  type="email"
  required
  aria-required="true"
  aria-describedby="email-hint"
/>
<span id="email-hint">We'll never share your email</span>
```

#### Loading States
```typescript
<div role="status" aria-live="polite" aria-busy={isLoading}>
  {isLoading ? 'Loading data...' : 'Data loaded'}
</div>
```

## Browser Support

### Target Browsers
- Chrome/Edge (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)

**MVP Note:** Desktop-optimized experience. Mobile support is nice-to-have but not required for MVP. Focus on desktop browsers (1366x768 and above).

### Polyfills
```typescript
// vite.config.ts
export default defineConfig({
  build: {
    target: 'es2015',
    polyfillModulePreload: true,
  },
});
```

## Monitoring & Analytics

### Error Tracking
```typescript
// Optional: Integrate Sentry for error tracking
import * as Sentry from '@sentry/react';

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.MODE,
  integrations: [new Sentry.BrowserTracing()],
  tracesSampleRate: 0.1,
});
```

### Performance Monitoring
```typescript
// Track key metrics
export const trackPerformance = () => {
  if ('performance' in window) {
    const perfData = window.performance.timing;
    const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
    
    // Send to analytics
    console.log('Page load time:', pageLoadTime);
  }
};
```

### User Analytics (Optional)
```typescript
// Track user interactions
export const trackEvent = (category: string, action: string, label?: string) => {
  // Google Analytics or custom analytics
  if (window.gtag) {
    window.gtag('event', action, {
      event_category: category,
      event_label: label,
    });
  }
};

// Usage
trackEvent('KPI', 'create', 'Technical Skills');
trackEvent('Dashboard', 'export', 'CSV');
```

## Documentation

### Component Documentation
```typescript
/**
 * KPIForm component for creating and editing KPIs
 * 
 * @param {KPI} initialValues - Initial form values for editing
 * @param {Function} onSubmit - Callback when form is submitted
 * @param {Function} onCancel - Callback when form is cancelled
 * 
 * @example
 * <KPIForm
 *   initialValues={existingKPI}
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 * />
 */
export function KPIForm({ initialValues, onSubmit, onCancel }: KPIFormProps) {
  // Implementation
}
```

### API Documentation
Create a README.md in the project documenting:
- API endpoints and their usage
- Authentication flow
- Environment variables
- Deployment process
- Common troubleshooting

## Future Enhancements (Post-MVP)

### Phase 2 Features
- Dark mode toggle
- Multi-language support (Vietnamese)
- Advanced data filtering
- Excel and PDF export (MVP uses CSV only)
- Formula versioning
- Real-time updates via WebSockets
- Offline support with Service Workers
- Advanced analytics dashboard
- Custom report builder
- Email notification preferences
- Interactive charts with drill-down
- Mobile-optimized responsive design
- Chatbot navigation help
- Data import templates
- Audit log viewer

### Technical Improvements
- Implement React Query for better data fetching
- Add Storybook for component documentation
- Implement E2E tests with Playwright
- Add performance monitoring dashboard
- Implement feature flags
- Add A/B testing capability
- Optimize bundle size further
- Implement progressive web app (PWA) features

