# Performance Scores Lambda Handler

This Lambda function handles CRUD operations for performance scores in the InsightHR system.

## Overview

The performance-scores-handler provides endpoints for creating, reading, updating, and deleting performance scores with role-based access control.

## Features

- **List Scores**: Get all performance scores with filters (department, period, employeeId)
- **Get Single Score**: Retrieve a specific score by employeeId and period
- **Create Score**: Create new performance scores (Admin only)
- **Update Score**: Update existing scores (Admin only)
- **Delete Score**: Delete scores (Admin only)
- **Role-Based Access Control**:
  - Admin: Full access to all scores
  - Manager: Access to their department's scores only
  - Employee: Access to their own scores only

## API Endpoints

### GET /performance-scores
List all performance scores with optional filters.

**Query Parameters:**
- `department` (optional): Filter by department (DEV, QA, DAT, SEC)
- `period` (optional): Filter by period (e.g., "2025-1", "2025-2", "2025-3")
- `employeeId` (optional): Filter by specific employee

**Response:**
```json
{
  "success": true,
  "scores": [
    {
      "scoreId": "uuid",
      "employeeId": "DEV-01001",
      "period": "2025-1",
      "employeeName": "Employee DEV-01001",
      "department": "DEV",
      "position": "Senior",
      "overallScore": 85.5,
      "kpiScores": {
        "KPI": 85.0,
        "completed_task": 88.0,
        "feedback_360": 83.5
      },
      "calculatedAt": "2025-11-22T20:19:37.349792",
      "createdAt": "2025-11-22T20:19:37.349794",
      "updatedAt": "2025-11-22T20:19:37.349795"
    }
  ],
  "count": 1
}
```

### GET /performance-scores/{employeeId}/{period}
Get a single performance score.

**Path Parameters:**
- `employeeId`: Employee ID (e.g., "DEV-01001")
- `period`: Period (e.g., "2025-1")

**Response:**
```json
{
  "success": true,
  "score": {
    "scoreId": "uuid",
    "employeeId": "DEV-01001",
    "period": "2025-1",
    ...
  }
}
```

### POST /performance-scores
Create a new performance score (Admin only).

**Request Body:**
```json
{
  "employeeId": "DEV-01001",
  "period": "2025-4",
  "KPI": 85.5,
  "completed_task": 90.0,
  "feedback_360": 88.5,
  "final_score": 88.0  // Optional, will be calculated if not provided
}
```

**Response:**
```json
{
  "success": true,
  "score": { ... },
  "message": "Performance score created successfully"
}
```

### PUT /performance-scores/{employeeId}/{period}
Update an existing performance score (Admin only).

**Path Parameters:**
- `employeeId`: Employee ID
- `period`: Period

**Request Body:**
```json
{
  "KPI": 90.0,
  "completed_task": 92.0,
  "feedback_360": 91.0,
  "final_score": 91.0  // Optional
}
```

**Response:**
```json
{
  "success": true,
  "score": { ... },
  "message": "Performance score updated successfully"
}
```

### DELETE /performance-scores/{employeeId}/{period}
Delete a performance score (Admin only).

**Path Parameters:**
- `employeeId`: Employee ID
- `period`: Period

**Response:**
```json
{
  "success": true,
  "message": "Performance score deleted successfully"
}
```

## Role-Based Access Control

### Admin
- Can list all scores with any filters
- Can create, update, and delete any score
- Full access to all data

### Manager
- Can list scores from their department only
- Cannot create, update, or delete scores
- Department filter is automatically applied

### Employee
- Can list only their own scores
- Cannot create, update, or delete scores
- EmployeeId filter is automatically applied

## Environment Variables

- `PERFORMANCE_SCORES_TABLE`: DynamoDB table name for performance scores (default: insighthr-performance-scores-dev)
- `EMPLOYEES_TABLE`: DynamoDB table name for employees (default: insighthr-employees-dev)
- `USERS_TABLE`: DynamoDB table name for users (default: insighthr-users-dev)
- `AWS_REGION`: AWS region (default: ap-southeast-1)

## DynamoDB Schema

### PerformanceScores Table
- **Partition Key**: `employeeId` (String)
- **Sort Key**: `period` (String)
- **GSI**: `department-period-index`
  - Partition Key: `department` (String)
  - Sort Key: `period` (String)

### Attributes
- `scoreId`: Unique score identifier (UUID)
- `employeeId`: Employee ID (e.g., "DEV-01001")
- `period`: Period (e.g., "2025-1", "2025-2", "2025-3")
- `employeeName`: Employee name (denormalized)
- `department`: Department (DEV, QA, DAT, SEC)
- `position`: Job position (Junior, Mid, Senior, Lead, Manager)
- `overallScore`: Final calculated score (0-100)
- `kpiScores`: Map of individual KPI scores
  - `KPI`: KPI score (0-100)
  - `completed_task`: Completed tasks score (0-100)
  - `feedback_360`: 360 feedback score (0-100)
- `calculatedAt`: Timestamp when score was calculated
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Deployment

### 1. Deploy Lambda Function
```powershell
.\deploy-lambda.ps1
```

This will:
- Package the Lambda function
- Create or update the Lambda function in AWS
- Configure environment variables

### 2. Setup API Gateway Endpoints
```powershell
.\setup-api-gateway.ps1
```

This will:
- Create API Gateway resources and methods
- Configure Cognito authorizer
- Set up CORS
- Deploy API to 'dev' stage

### 3. Test Endpoints
```powershell
.\test-endpoints.ps1
```

This will test all CRUD endpoints with sample data.

## Testing

### Prerequisites
- Valid Cognito ID token (get from check-token.html or localStorage)
- Admin role for create/update/delete operations

### Test with curl
```bash
# List all scores
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  https://API_ID.execute-api.ap-southeast-1.amazonaws.com/dev/performance-scores

# Get single score
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  https://API_ID.execute-api.ap-southeast-1.amazonaws.com/dev/performance-scores/DEV-01001/2025-1

# Create score (Admin only)
curl -X POST \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"DEV-01001","period":"2025-4","KPI":85.5,"completed_task":90.0,"feedback_360":88.5}' \
  https://API_ID.execute-api.ap-southeast-1.amazonaws.com/dev/performance-scores

# Update score (Admin only)
curl -X PUT \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"KPI":90.0,"completed_task":92.0,"feedback_360":91.0}' \
  https://API_ID.execute-api.ap-southeast-1.amazonaws.com/dev/performance-scores/DEV-01001/2025-4

# Delete score (Admin only)
curl -X DELETE \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  https://API_ID.execute-api.ap-southeast-1.amazonaws.com/dev/performance-scores/DEV-01001/2025-4
```

## Error Handling

### 400 Bad Request
- Missing required fields (employeeId, period)
- Invalid data format
- Validation errors

### 403 Forbidden
- Non-admin user attempting to create/update/delete
- Manager attempting to access another department's data
- Employee attempting to access another employee's data

### 404 Not Found
- Score not found
- Employee not found
- Endpoint not found

### 500 Internal Server Error
- DynamoDB errors
- Lambda execution errors
- Unexpected exceptions

## Notes

- The `final_score` is automatically calculated as the average of KPI, completed_task, and feedback_360 scores if not provided
- Employee details (name, department, position) are fetched from the Employees table when creating scores
- All scores are denormalized with employee information for query performance
- The GSI `department-period-index` enables efficient filtering by department and period
