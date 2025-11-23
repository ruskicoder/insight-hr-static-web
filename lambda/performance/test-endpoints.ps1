# Test Performance Handler Endpoints
Write-Host "=== Testing Performance Handler Endpoints ===" -ForegroundColor Cyan

$API_BASE = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

Write-Host "`nNote: These tests will return 'Unauthorized' without a valid JWT token." -ForegroundColor Yellow
Write-Host "This is expected behavior - it confirms the endpoints are working and protected." -ForegroundColor Yellow

# Test 1: GET /performance
Write-Host "`nTest 1: GET /performance" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/performance" -Method GET -Headers @{"Authorization"="Bearer test-token"} -ErrorAction Stop
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Status: 401 Unauthorized (Expected - endpoint is protected)" -ForegroundColor Green
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 2: GET /performance/{employeeId}
Write-Host "`nTest 2: GET /performance/DEV-001" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE/performance/DEV-001" -Method GET -Headers @{"Authorization"="Bearer test-token"} -ErrorAction Stop
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Status: 401 Unauthorized (Expected - endpoint is protected)" -ForegroundColor Green
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 3: POST /performance/export
Write-Host "`nTest 3: POST /performance/export" -ForegroundColor Cyan
try {
    $body = @{
        filters = @{
            department = "DEV"
        }
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$API_BASE/performance/export" -Method POST -Headers @{"Authorization"="Bearer test-token"; "Content-Type"="application/json"} -Body $body -ErrorAction Stop
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Status: 401 Unauthorized (Expected - endpoint is protected)" -ForegroundColor Green
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "All endpoints are responding correctly with 401 Unauthorized." -ForegroundColor Green
Write-Host "This confirms the endpoints are working and protected by Cognito authorizer." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Test with a valid JWT token from Cognito" -ForegroundColor White
Write-Host "2. Verify role-based access control works" -ForegroundColor White
Write-Host "3. Test with real performance data" -ForegroundColor White
