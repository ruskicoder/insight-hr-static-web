# Employee Management Lambda Functions

This directory contains Lambda functions for managing employees in the InsightHR system.

## Lambda Functions

### 1. insighthr-employees-handler
Handles CRUD operations for employees.

**Endpoints:**
- `GET /employees` - List all employees with optional filters (department, position, status, search)
- `GET /employees/{employeeId}` - Get a single employee by ID
- `POST /employees` - Create a new employee (Admin only)
- `PUT /employees/{employeeId}` - Update an employee (Admin only)
- `DELETE /employees/{employeeId}` - Delete an employee (Admin only)

**Environment Variables:**
- `EMPLOYEES_TABLE` - DynamoDB table name (default: insighthr-employees-dev)

### 2. insighthr-employees-bulk-handler
Handles bulk import of employees from CSV data.

**Endpoints:**
- `POST /employees/bulk` - Bulk import employees from CSV (Admin only)

**Request Body:**
```json
{
  "csvData": "employeeId,name,position,department\nDEV-12345,John Doe,Senior,DEV"
}
```

**Environment Variables:**
- `EMPLOYEES_TABLE` - DynamoDB table name (default: insighthr-employees-dev)

## Deployment

### Deploy Lambda Functions
```powershell
.\deploy-lambdas.ps1
```

### Setup API Gateway Endpoints
```powershell
.\setup-api-gateway.ps1
```

### Test Endpoints
```powershell
.\test-endpoints.ps1
```

## DynamoDB Table Schema

**Table Name:** insighthr-employees-dev

**Primary Key:**
- `employeeId` (String) - Partition Key

**Attributes:**
- `employeeId` (String) - Unique employee identifier (e.g., "DEV-12345")
- `name` (String) - Employee full name
- `position` (String) - Job position (Junior, Mid, Senior, Lead, Manager)
- `department` (String) - Department code (AI, DAT, DEV, QA, SEC)
- `status` (String) - Employee status (active, inactive)
- `email` (String, optional) - Employee email
- `createdAt` (String) - ISO 8601 timestamp
- `updatedAt` (String) - ISO 8601 timestamp

**Global Secondary Index:**
- `department-index` - Partition Key: department

## Authorization

All endpoints require Cognito JWT authentication. Admin-only endpoints check the `custom:role` claim in the JWT.

## API Base URL

```
https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev
```
