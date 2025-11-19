# Comprehensive Stub API Test Script
# Tests all user management endpoints

Write-Host "=== STUB API COMPREHENSIVE TEST ===" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:4000"
$adminToken = "Bearer mock-jwt-token-admin-1-1234567890"
$employeeToken = "Bearer mock-jwt-token-employee-1-1234567890"

# Test counter
$passed = 0
$failed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = 'application/json'
        }
        
        $response = Invoke-WebRequest @params
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "  PASSED (Status: $($response.StatusCode))" -ForegroundColor Green
            $script:passed++
            return $true
        }
        else {
            Write-Host "  FAILED (Expected: $ExpectedStatus, Got: $($response.StatusCode))" -ForegroundColor Red
            $script:failed++
            return $false
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "  PASSED (Status: $statusCode)" -ForegroundColor Green
            $script:passed++
            return $true
        }
        else {
            Write-Host "  FAILED (Expected: $ExpectedStatus, Got: $statusCode)" -ForegroundColor Red
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
            $script:failed++
            return $false
        }
    }
}

Write-Host "1. Authentication Tests" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

# Test login
$loginBody = @{email='admin@insighthr.com';password='Admin1234'} | ConvertTo-Json
Test-Endpoint -Name "POST /auth/login (Admin)" -Method POST -Url "$baseUrl/auth/login" -Body $loginBody

$loginBody = @{email='employee@insighthr.com';password='Employee1234'} | ConvertTo-Json
Test-Endpoint -Name "POST /auth/login (Employee)" -Method POST -Url "$baseUrl/auth/login" -Body $loginBody

Write-Host ""
Write-Host "2. Profile Management Tests" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Test GET /users/me
Test-Endpoint -Name "GET /users/me (Admin)" -Method GET -Url "$baseUrl/users/me" -Headers @{Authorization=$adminToken}

# Test PUT /users/me
$updateBody = @{name='Admin Updated';department='Engineering'} | ConvertTo-Json
Test-Endpoint -Name "PUT /users/me (Update profile)" -Method PUT -Url "$baseUrl/users/me" -Headers @{Authorization=$adminToken} -Body $updateBody

Write-Host ""
Write-Host "3. User List Tests (Admin Only)" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

# Test GET /users (Admin)
Test-Endpoint -Name "GET /users (Admin access)" -Method GET -Url "$baseUrl/users" -Headers @{Authorization=$adminToken}

# Test GET /users with filters
Test-Endpoint -Name "GET /users?department=Engineering" -Method GET -Url "$baseUrl/users?department=Engineering" -Headers @{Authorization=$adminToken}

Test-Endpoint -Name "GET /users?search=john" -Method GET -Url "$baseUrl/users?search=john" -Headers @{Authorization=$adminToken}

Test-Endpoint -Name "GET /users?status=active" -Method GET -Url "$baseUrl/users?status=active" -Headers @{Authorization=$adminToken}

# Test GET /users (Employee - should fail)
Test-Endpoint -Name "GET /users (Employee access - should fail)" -Method GET -Url "$baseUrl/users" -Headers @{Authorization=$employeeToken} -ExpectedStatus 403

Write-Host ""
Write-Host "4. User CRUD Tests (Admin Only)" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

# Test POST /users (Create)
$createBody = @{
    email='testuser@insighthr.com'
    name='Test User'
    role='Employee'
    department='IT'
    employeeId='TEST001'
} | ConvertTo-Json
Test-Endpoint -Name "POST /users (Create user)" -Method POST -Url "$baseUrl/users" -Headers @{Authorization=$adminToken} -Body $createBody -ExpectedStatus 201

# Test PUT /users/:userId (Update)
$updateUserBody = @{name='John Doe Modified';role='Manager'} | ConvertTo-Json
Test-Endpoint -Name "PUT /users/employee-2 (Update user)" -Method PUT -Url "$baseUrl/users/employee-2" -Headers @{Authorization=$adminToken} -Body $updateUserBody

Write-Host ""
Write-Host "5. User Status Tests (Admin Only)" -ForegroundColor Cyan
Write-Host "----------------------------------" -ForegroundColor Cyan

# Test disable user
Test-Endpoint -Name "PUT /users/employee-2/disable" -Method PUT -Url "$baseUrl/users/employee-2/disable" -Headers @{Authorization=$adminToken}

# Test enable user
Test-Endpoint -Name "PUT /users/employee-2/enable" -Method PUT -Url "$baseUrl/users/employee-2/enable" -Headers @{Authorization=$adminToken}

Write-Host ""
Write-Host "6. Bulk Import Test (Admin Only)" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan

# Test bulk import
$csvData = "email,name,role,department,employeeId`nbulk1@test.com,Bulk User 1,Employee,IT,BULK001`nbulk2@test.com,Bulk User 2,Manager,Sales,BULK002"
$bulkBody = @{csvData=$csvData} | ConvertTo-Json
Test-Endpoint -Name "POST /users/bulk (Bulk import)" -Method POST -Url "$baseUrl/users/bulk" -Headers @{Authorization=$adminToken} -Body $bulkBody -ExpectedStatus 201

Write-Host ""
Write-Host "7. Authorization Tests" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

# Test Employee cannot create user
$createBody = @{email='unauthorized@test.com';name='Unauthorized';role='Employee'} | ConvertTo-Json
Test-Endpoint -Name "POST /users (Employee - should fail)" -Method POST -Url "$baseUrl/users" -Headers @{Authorization=$employeeToken} -Body $createBody -ExpectedStatus 403

# Test Employee cannot update user
$updateBody = @{name='Hacker'} | ConvertTo-Json
Test-Endpoint -Name "PUT /users/admin-1 (Employee - should fail)" -Method PUT -Url "$baseUrl/users/admin-1" -Headers @{Authorization=$employeeToken} -Body $updateBody -ExpectedStatus 403

# Test Employee cannot disable user
Test-Endpoint -Name "PUT /users/admin-1/disable (Employee - should fail)" -Method PUT -Url "$baseUrl/users/admin-1/disable" -Headers @{Authorization=$employeeToken} -ExpectedStatus 403

Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
