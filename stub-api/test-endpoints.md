# Stub API Endpoint Tests

This document contains test commands for all user management endpoints.

## Prerequisites

1. Start the stub API server:
```bash
cd stub-api
npm start
```

2. The server should be running on `http://localhost:4000`

## Test Commands (PowerShell)

### 1. Login as Admin

```powershell
$body = @{email='admin@insighthr.com';password='Admin1234'} | ConvertTo-Json
$response = Invoke-WebRequest -Uri http://localhost:4000/auth/login -Method POST -Body $body -ContentType 'application/json'
$response.Content
```

**Expected:** Success response with admin user data and tokens

### 2. Login as Employee

```powershell
$body = @{email='employee@insighthr.com';password='Employee1234'} | ConvertTo-Json
$response = Invoke-WebRequest -Uri http://localhost:4000/auth/login -Method POST -Body $body -ContentType 'application/json'
$response.Content
```

**Expected:** Success response with employee user data and tokens

### 3. GET /users/me (Get Current User Profile)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri http://localhost:4000/users/me -Method GET -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** Current user profile data

### 4. PUT /users/me (Update Current User Profile)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
$body = @{name='Admin User Updated';department='Engineering'} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:4000/users/me -Method PUT -Headers $headers -Body $body -ContentType 'application/json' | Select-Object -ExpandProperty Content
```

**Expected:** Success response with updated user data

### 5. GET /users (Get All Users - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri http://localhost:4000/users -Method GET -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** List of all users

### 6. GET /users with Filters (Filter by Department)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri 'http://localhost:4000/users?department=Engineering' -Method GET -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** List of users in Engineering department

### 7. GET /users with Search

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri 'http://localhost:4000/users?search=john' -Method GET -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** List of users matching "john" in name or email

### 8. POST /users (Create New User - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
$body = @{email='newuser@insighthr.com';name='New User';role='Employee';department='IT';employeeId='EMP999'} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:4000/users -Method POST -Headers $headers -Body $body -ContentType 'application/json' | Select-Object -ExpandProperty Content
```

**Expected:** Success response with newly created user data

### 9. PUT /users/:userId (Update User - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
$body = @{name='John Doe Updated';role='Manager'} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:4000/users/employee-2 -Method PUT -Headers $headers -Body $body -ContentType 'application/json' | Select-Object -ExpandProperty Content
```

**Expected:** Success response with updated user data

### 10. PUT /users/:userId/disable (Disable User - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri http://localhost:4000/users/employee-2/disable -Method PUT -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** Success response with user status changed to "disabled"

### 11. PUT /users/:userId/enable (Enable User - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri http://localhost:4000/users/employee-2/enable -Method PUT -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** Success response with user status changed to "active"

### 12. DELETE /users/:userId (Delete User - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
Invoke-WebRequest -Uri http://localhost:4000/users/employee-1 -Method DELETE -Headers $headers | Select-Object -ExpandProperty Content
```

**Expected:** Success response confirming user deletion

### 13. POST /users/bulk (Bulk Import Users - Admin Only)

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-admin-1-1234567890'}
$csvData = 'email,name,role,department,employeeId' + "`n" + 'bulk1@test.com,Bulk User 1,Employee,IT,BULK001' + "`n" + 'bulk2@test.com,Bulk User 2,Manager,Sales,BULK002'
$body = @{csvData=$csvData} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:4000/users/bulk -Method POST -Headers $headers -Body $body -ContentType 'application/json' | Select-Object -ExpandProperty Content
```

**Expected:** Success response with import results (success count, failed count, details)

### 14. Test Authorization - Employee Cannot Access Admin Endpoints

```powershell
$headers = @{Authorization='Bearer mock-jwt-token-employee-1-1234567890'}
try {
    Invoke-WebRequest -Uri http://localhost:4000/users -Method GET -Headers $headers -ErrorAction Stop
} catch {
    Write-Output "Status: $($_.Exception.Response.StatusCode.value__)"
    $_.ErrorDetails.Message
}
```

**Expected:** 403 Forbidden error

## Test Results Summary

All endpoints have been tested and are working correctly:

✅ GET /users/me - Returns current user profile
✅ PUT /users/me - Updates current user profile
✅ GET /users - Returns all users (Admin only)
✅ GET /users?filters - Returns filtered users (Admin only)
✅ POST /users - Creates new user (Admin only)
✅ PUT /users/:userId - Updates user (Admin only)
✅ PUT /users/:userId/disable - Disables user (Admin only)
✅ PUT /users/:userId/enable - Enables user (Admin only)
✅ DELETE /users/:userId - Deletes user (Admin only)
✅ POST /users/bulk - Bulk imports users from CSV (Admin only)
✅ Authorization - Non-admin users cannot access admin endpoints

## Notes

- All admin endpoints properly check for Admin role
- Employee users receive 403 Forbidden when trying to access admin endpoints
- Bulk import validates CSV format and required fields
- Bulk import reports both successful and failed imports
- User deletion prevents deleting your own account
- All responses follow consistent format matching AWS Lambda structure
