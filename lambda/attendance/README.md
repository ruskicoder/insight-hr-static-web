# Attendance Management Lambda Functions

This directory contains Lambda functions for managing employee attendance in the InsightHR system.

## Overview

The attendance handler provides API endpoints for check-in/check-out operations, attendance tracking, and 360 points calculation with role-based access control.

## Lambda Functions

### insighthr-attendance-handler

Handles attendance operations including public check-in/check-out and admin/manager attendance management.

**Runtime**: Python 3.11  
**Handler**: `attendance_handler.lambda_handler`  
**Timeout**: 30 seconds  
**Memory**: 256 MB

## Environment Variables

- `ATTENDANCE_TABLE` - DynamoDB table name (insighthr-attendance-history-dev)
- `EMPLOYEES_TABLE` - DynamoDB table name (insighthr-employees-dev)
- `USERS_TABLE` - DynamoDB table name (insighthr-users-dev)
- `AWS_REGION` - AWS region (ap-southeast-1)

## API Endpoints

### Public Endpoints (No Authentication Required)

#### POST /attendance/check-in

Employee check-in endpoint for kiosk/public access.

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/check-in`

**Request Body**:
```json
{
  "employeeId": "DEV-001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Check-in successful",
  "data": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:30:00",
    "status": "work",
    "points360": 0
  }
}
```

#### POST /attendance/check-out

Employee check-out endpoint for kiosk/public access.

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/check-out`

**Request Body**:
```json
{
  "employeeId": "DEV-001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Check-out successful",
  "data": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:30:00",
    "checkOut": "17:45:00",
    "status": "OT",
    "points360": 95
  }
}
```

#### GET /attendance/{employeeId}/status

Get current attendance status for an employee (public access).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/{employeeId}/status`

**Response**:
```json
{
  "success": true,
  "data": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:30:00",
    "checkOut": null,
    "status": "work",
    "points360": 0
  }
}
```

### Protected Endpoints (Cognito JWT Required)

#### GET /attendance

List all attendance records with optional filters (Admin/Manager only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance`

**Auth**: Cognito JWT (Admin/Manager)

**Query Parameters**:
- `department` (optional): Filter by department (DEV, QA, DAT, SEC, AI)
- `date` (optional): Filter by date (YYYY-MM-DD)
- `employeeId` (optional): Filter by specific employee
- `status` (optional): Filter by status (work, late, absent, off, OT, early_bird)

**Response**:
```json
{
  "success": true,
  "records": [
    {
      "employeeId": "DEV-001",
      "date": "2025-12-05",
      "checkIn": "08:30:00",
      "checkOut": "17:45:00",
      "status": "OT",
      "points360": 95,
      "department": "DEV",
      "position": "Senior",
      "paidLeave": false,
      "reason": null
    }
  ],
  "count": 1
}
```

#### GET /attendance/{employeeId}/{date}

Get a single attendance record (Admin/Manager only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/{employeeId}/{date}`

**Auth**: Cognito JWT (Admin/Manager)

**Path Parameters**:
- `employeeId`: Employee ID (e.g., "DEV-001")
- `date`: Date (YYYY-MM-DD)

**Response**:
```json
{
  "success": true,
  "record": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:30:00",
    "checkOut": "17:45:00",
    "status": "OT",
    "points360": 95,
    "department": "DEV",
    "position": "Senior",
    "paidLeave": false,
    "reason": null,
    "createdAt": "2025-12-05T08:30:00Z",
    "updatedAt": "2025-12-05T17:45:00Z"
  }
}
```

#### POST /attendance

Create attendance record manually (Admin/Manager only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance`

**Auth**: Cognito JWT (Admin/Manager)

**Request Body**:
```json
{
  "employeeId": "DEV-001",
  "date": "2025-12-05",
  "checkIn": "08:30:00",
  "checkOut": "17:00:00",
  "paidLeave": false,
  "reason": null
}
```

**Response**:
```json
{
  "success": true,
  "message": "Attendance record created successfully",
  "record": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:30:00",
    "checkOut": "17:00:00",
    "status": "work",
    "points360": 80,
    "department": "DEV",
    "position": "Senior",
    "paidLeave": false,
    "reason": null
  }
}
```

#### PUT /attendance/{employeeId}/{date}

Update attendance record (Admin/Manager only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/{employeeId}/{date}`

**Auth**: Cognito JWT (Admin/Manager)

**Request Body**:
```json
{
  "checkIn": "08:00:00",
  "checkOut": "18:00:00",
  "paidLeave": false,
  "reason": null
}
```

**Response**:
```json
{
  "success": true,
  "message": "Attendance record updated successfully",
  "record": {
    "employeeId": "DEV-001",
    "date": "2025-12-05",
    "checkIn": "08:00:00",
    "checkOut": "18:00:00",
    "status": "OT",
    "points360": 105,
    "department": "DEV",
    "position": "Senior",
    "paidLeave": false,
    "reason": null
  }
}
```

#### DELETE /attendance/{employeeId}/{date}

Delete attendance record (Admin only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/{employeeId}/{date}`

**Auth**: Cognito JWT (Admin)

**Response**:
```json
{
  "success": true,
  "message": "Attendance record deleted successfully"
}
```

#### POST /attendance/bulk

Bulk import attendance records from CSV (Admin/Manager only).

**URL**: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/bulk`

**Auth**: Cognito JWT (Admin/Manager)

**Request Body**:
```json
{
  "csvData": "employeeId,date,checkIn,checkOut,paidLeave,reason\nDEV-001,2025-12-05,08:30:00,17:00:00,false,\nDEV-002,2025-12-05,09:15:00,17:30:00,false,"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Bulk import completed",
  "results": {
    "total": 2,
    "successful": 2,
    "failed": 0,
    "errors": []
  }
}
```

## Attendance Status Logic

The system automatically calculates attendance status based on check-in/check-out times:

- **work**: Check-in between 6:00-9:00 AM, check-out before 17:00
- **late**: Check-in after 9:00 AM
- **absent**: No check-in/out by 23:59 (auto-marked by scheduled Lambda)
- **off**: Paid leave flag is true
- **OT**: Check-out after 17:00 (overtime)
- **early_bird**: Check-in before 6:00 AM

## 360 Points Calculation

Base calculation: 10 points per hour worked (8 hours = 80 points)

**Bonuses**:
- **OT Bonus**: 1.5x points for hours after 17:00
  - Example: Work until 18:00 = 80 + (1 hour × 10 × 1.5) = 95 points
- **Early Bird Bonus**: 1.25x points for hours before 8:00 AM (if check-in before 6:00 AM)
  - Example: Check-in at 5:30 AM, work until 17:00 = (2.5 hours × 10 × 1.25) + (5.5 hours × 10) = 86.25 points

**Special Cases**:
- Paid leave: 80 points (full day credit)
- Absent: 0 points
- Late: Normal calculation (no penalty in points, but status marked as "late")

## Role-Based Access Control

### Admin
- Full access to all attendance records across all departments
- Can create, update, and delete any attendance record
- Can perform bulk imports
- Can access all API endpoints

### Manager
- Access to attendance records for their department only
- Can create and update attendance records for their department
- Can perform bulk imports for their department
- Cannot delete attendance records

### Employee
- Can check-in and check-out (public endpoints)
- Can view their own attendance status
- Cannot access other employees' records
- Cannot create, update, or delete records manually

### Public (No Authentication)
- Can use check-in/check-out endpoints
- Can view attendance status by employeeId
- Designed for kiosk/public terminal use

## DynamoDB Schema

### AttendanceHistory Table (insighthr-attendance-history-dev)

**Primary Key**:
- `employeeId` (String, HASH)
- `date` (String, RANGE) - Format: YYYY-MM-DD

**Global Secondary Indexes**:
- `date-index`: PK=date (for daily queries)
- `department-date-index`: PK=department, SK=date (for manager queries)

**Attributes**:
- `employeeId`: Employee ID (e.g., "DEV-001")
- `date`: Date (YYYY-MM-DD)
- `checkIn`: Check-in time (HH:MM:SS)
- `checkOut`: Check-out time (HH:MM:SS)
- `status`: Attendance status (work, late, absent, off, OT, early_bird)
- `points360`: Calculated 360 points (0-120)
- `department`: Department (DEV, QA, DAT, SEC, AI)
- `position`: Job position (Junior, Mid, Senior, Lead, Manager)
- `paidLeave`: Paid leave flag (boolean)
- `reason`: Absence/leave reason (string, optional)
- `createdAt`: Creation timestamp (ISO 8601)
- `updatedAt`: Last update timestamp (ISO 8601)

## Deployment

### 1. Create DynamoDB Table

```powershell
.\create-attendance-table.ps1
```

This creates the AttendanceHistory table with GSIs.

### 2. Deploy Lambda Function

```powershell
.\deploy-lambda.ps1
```

This packages and deploys the Lambda function with environment variables.

### 3. Setup API Gateway Endpoints

```powershell
.\setup-api-gateway.ps1
```

This creates all API Gateway resources, methods, and integrations.

### 4. Test Endpoints

```powershell
.\test-endpoints.ps1
```

This tests all endpoints with sample data.

## Testing

### Test Check-In (Public)

```bash
curl -X POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/check-in \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"DEV-001"}'
```

### Test Check-Out (Public)

```bash
curl -X POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/check-out \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"DEV-001"}'
```

### Test List Attendance (Admin/Manager)

```bash
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance?department=DEV&date=2025-12-05"
```

### Test Get Single Record (Admin/Manager)

```bash
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance/DEV-001/2025-12-05"
```

### Test Create Record (Admin/Manager)

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"DEV-001","date":"2025-12-05","checkIn":"08:30:00","checkOut":"17:00:00","paidLeave":false}' \
  https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/attendance
```

## Error Handling

### 400 Bad Request
- Missing required fields (employeeId, date)
- Invalid data format
- Invalid time format
- Validation errors

### 401 Unauthorized
- Missing or invalid JWT token (protected endpoints)
- Token expired

### 403 Forbidden
- Non-admin/manager user attempting to access protected endpoints
- Manager attempting to access another department's data
- Employee attempting to access other employees' records

### 404 Not Found
- Attendance record not found
- Employee not found
- Endpoint not found

### 409 Conflict
- Attempting to check-in when already checked in
- Attempting to check-out without checking in first
- Duplicate attendance record

### 500 Internal Server Error
- DynamoDB errors
- Lambda execution errors
- Unexpected exceptions

## Auto-Absence Marking

A scheduled Lambda function (`insighthr-attendance-auto-absence`) runs daily at 23:59 to automatically mark employees as absent if they haven't checked in.

**Schedule**: Daily at 23:59 (Singapore time)  
**Action**: Marks employees with no check-in as "absent" with 0 points

## Data Migration

The system includes a migration script to import historical attendance data:

```bash
python scripts/migrate-attendance-data.py
```

This migrates data from the old `attendence_history` table to the new `insighthr-attendance-history-dev` table with proper schema and calculated 360 points.

**Migration Stats**:
- Total records migrated: 9,300
- Date range: Historical data
- Success rate: 100%

## Related

- Frontend: `insighthr-web/src/services/attendanceService.ts`
- Store: `insighthr-web/src/store/attendanceStore.ts`
- Components: `insighthr-web/src/components/attendance/`
- Migration Script: `scripts/migrate-attendance-data.py`

## Notes

- Public endpoints (check-in/check-out/status) do not require authentication for kiosk use
- Protected endpoints require Cognito JWT with valid role
- 360 points are automatically calculated on check-out
- Status is automatically determined based on check-in/check-out times
- Manager access is filtered by department automatically
- All timestamps are in Singapore timezone (UTC+8)
- The system supports paid leave tracking with full points credit

## Last Updated

2025-12-05 - Initial documentation created
