# Test Attendance API Endpoints

$API_BASE = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"
$REGION = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Attendance API Endpoints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get admin token
Write-Host "Getting admin token..." -ForegroundColor Yellow
$loginResponse = Invoke-RestMethod -Uri "$API_BASE/auth/login" -Method POST -Body (@{
    email = "admin@insighthr.com"
    password = "Admin@123"
} | ConvertTo-Json) -ContentType "application/json"

$token = $loginResponse.idToken
Write-Host "Token obtained: $($token.Substring(0, 20))..." -ForegroundColor Green
Write-Host ""

# Test 1: Public check-in (no auth)
Write-Host "Test 1: Public check-in for DEV-001" -ForegroundColor Cyan
try {
    $checkInResponse = Invoke-RestMethod -Uri "$API_BASE/attendance/check-in" -Method POST -Body (@{
        employeeId = "DEV-001"
    } | ConvertTo-Json) -ContentType "application/json"
    
    Write-Host "  Status: SUCCESS" -ForegroundColor Green
    Write-Host "  Employee: $($checkInResponse.employeeName)" -ForegroundColor White
    Write-Host "  Check-in: $($checkInResponse.checkIn)" -ForegroundColor White
    Write-Host "  Status: $($checkInResponse.status)" -ForegroundColor White
} catch {
    Write-Host "  Status: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check status (no auth)
Write-Host "Test 2: Check status for DEV-001" -ForegroundColor Cyan
try {
    $statusResponse = Invoke-RestMethod -Uri "$API_BASE/attendance/DEV-001/status" -Method GET
    
    Write-Host "  Status: SUCCESS" -ForegroundColor Green
    Write-Host "  Has Session: $($statusResponse.hasSession)" -ForegroundColor White
    if ($statusResponse.hasSession) {
        Write-Host "  Employee: $($statusResponse.employeeName)" -ForegroundColor White
        Write-Host "  Check-in: $($statusResponse.checkIn)" -ForegroundColor White
    }
} catch {
    Write-Host "  Status: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Public check-out (no auth)
Write-Host "Test 3: Public check-out for DEV-001" -ForegroundColor Cyan
try {
    $checkOutResponse = Invoke-RestMethod -Uri "$API_BASE/attendance/check-out" -Method POST -Body (@{
        employeeId = "DEV-001"
    } | ConvertTo-Json) -ContentType "application/json"
    
    Write-Host "  Status: SUCCESS" -ForegroundColor Green
    Write-Host "  Employee: $($checkOutResponse.employeeName)" -ForegroundColor White
    Write-Host "  Check-out: $($checkOutResponse.checkOut)" -ForegroundColor White
    Write-Host "  Status: $($checkOutResponse.status)" -ForegroundColor White
    Write-Host "  Points: $($checkOutResponse.points360)" -ForegroundColor White
} catch {
    Write-Host "  Status: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Get all attendance records (protected)
Write-Host "Test 4: Get all attendance records (Admin)" -ForegroundColor Cyan
try {
    $headers = @{
        "Authorization" = $token
        "Content-Type" = "application/json"
    }
    
    $attendanceResponse = Invoke-RestMethod -Uri "$API_BASE/attendance" -Method GET -Headers $headers
    
    Write-Host "  Status: SUCCESS" -ForegroundColor Green
    Write-Host "  Records count: $($attendanceResponse.count)" -ForegroundColor White
    if ($attendanceResponse.records.Count -gt 0) {
        Write-Host "  First record:" -ForegroundColor White
        Write-Host "    Employee: $($attendanceResponse.records[0].employeeId)" -ForegroundColor White
        Write-Host "    Date: $($attendanceResponse.records[0].date)" -ForegroundColor White
        Write-Host "    Status: $($attendanceResponse.records[0].status)" -ForegroundColor White
    }
} catch {
    Write-Host "  Status: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Create attendance record manually (protected)
Write-Host "Test 5: Create attendance record manually (Admin)" -ForegroundColor Cyan
try {
    $headers = @{
        "Authorization" = $token
        "Content-Type" = "application/json"
    }
    
    $today = Get-Date -Format "yyyy-MM-dd"
    $createResponse = Invoke-RestMethod -Uri "$API_BASE/attendance" -Method POST -Headers $headers -Body (@{
        employeeId = "DEV-002"
        date = $today
        checkIn = "08:30"
        checkOut = "17:30"
        paidLeave = $false
        reason = "Test record"
    } | ConvertTo-Json)
    
    Write-Host "  Status: SUCCESS" -ForegroundColor Green
    Write-Host "  Record created for: $($createResponse.record.employeeId)" -ForegroundColor White
    Write-Host "  Date: $($createResponse.record.date)" -ForegroundColor White
    Write-Host "  Points: $($createResponse.record.points360)" -ForegroundColor White
} catch {
    Write-Host "  Status: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

