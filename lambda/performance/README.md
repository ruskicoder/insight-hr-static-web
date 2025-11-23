# Performance Handler Lambda

This Lambda function handles performance data operations for the InsightHR system.

## Overview

The performance handler provides API endpoints for querying and exporting employee performance scores with role-based access control.

## Features

- **Role-Based Access Control**: 
  - Admin: See all performance data
  - Manager: See only their department's data
  - Employee: See only their own data

- **Filtering**: Support for filtering by department, period, and employeeId

- **CSV Export**: Export performance data as CSV file

- **Graceful Degradation**: Works with or without auto-scoring Lambda (Phase 5 feature)

## Environment Variables

- `PERFORMANCE_SCORES_TABLE`: DynamoDB table for performance scores (default: insighthr-performance-scores-dev)
- `EMPLOYEES_TABLE`: DynamoDB table for employee data (default: insighthr-employees-dev)
- `AUTO_SCORING_LAMBDA_ARN`: ARN of auto-scoring Lambda (optional, empty for Phase 3)

## API Endpoints

### GET /performance

Get all performance scores with optional filters.

**Query Parameters:**
- `department` (optional): Filter by department
- `period` (optional): Filter by period (e.g., "2025-1")
- `employeeId` (optional): Filter by specific employee

**Response:**
```json
{
  "success": true,
  "scores": [...],
  "count": 10
}
```

### GET /performance/{employeeId}

Get performance history for a specific employee.

**Path Parameters:**
- `employeeId`: Employee ID (e.g., "DEV-001")

**Response:**
```json
{
  "success": true,
  "employeeId": "DEV-001",
  "scores": [...],
  "count": 3
}
```

### POST /performance/export

Export performance data as CSV.

**Request Body:**
```json
{
  "filters": {
    "department": "DEV",
    "period": "2025-1"
  }
}
```

**Response:**
CSV file with headers: Employee ID, Employee Name, Department, Position, Period, Overall Score, KPI Scores

## Deployment

1. Package and deploy Lambda:
```powershell
./deploy-performance-handler.ps1
```

2. Set up API Gateway endpoints:
```powershell
./setup-api-gateway.ps1
```

3. Test endpoints:
```powershell
./test-endpoints.ps1
```

## DynamoDB Tables

### PerformanceScores Table
- **Primary Key**: employeeId (HASH), period (RANGE)
- **GSI**: department-period-index (department HASH, period RANGE)
- **Attributes**: scoreId, employeeName, department, position, overallScore, kpiScores, formulaId, calculatedAt

### Employees Table
- **Primary Key**: employeeId (HASH)
- **GSI**: department-index (department HASH)
- **Attributes**: name, department, position, email, joinDate, status

## Inter-Lambda Communication

The performance handler implements a graceful degradation pattern for auto-scoring:

1. Check if `AUTO_SCORING_LAMBDA_ARN` is configured
2. If yes, invoke auto-scoring Lambda asynchronously
3. If no or invocation fails, log warning and continue with existing data
4. Query PerformanceScores table and return data

This allows the dashboard to work in Phase 3 (without auto-scoring) and seamlessly integrate with auto-scoring in Phase 5.

## Testing

The Lambda function can be tested with:

1. **Unit tests**: Test individual functions with mock data
2. **Integration tests**: Test with real DynamoDB tables
3. **API tests**: Test endpoints with Postman or curl

Example test with valid JWT token:
```bash
curl -X GET "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/performance?department=DEV" \
  -H "Authorization: Bearer <valid-jwt-token>"
```

## Notes

- All endpoints require Cognito JWT authentication
- Role-based access control is enforced at the Lambda level
- CSV export returns data as text/csv content type
- Empty `AUTO_SCORING_LAMBDA_ARN` is expected for Phase 3
- Lambda will be updated in Phase 5 to set `AUTO_SCORING_LAMBDA_ARN` to formula-calculator ARN
