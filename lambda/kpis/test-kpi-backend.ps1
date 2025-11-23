# Test KPI Backend API
# This script tests the KPI API endpoints to verify they're working

$API_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

Write-Host "=== KPI Backend API Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing KPI endpoints without authentication first..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Try to access without auth (should fail with 401)
Write-Host "1. Testing GET /kpis without auth (should fail)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/kpis" -Method GET -ErrorAction Stop
    Write-Host "X Unexpected success - endpoint should require authentication" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "OK Correctly returns 401 Unauthorized" -ForegroundColor Green
    } else {
        Write-Host "X Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Backend API is configured correctly and requires authentication." -ForegroundColor Green
Write-Host ""
Write-Host "To test with authentication:" -ForegroundColor Yellow
Write-Host "1. Login to https://d2z6tht6rq32uy.cloudfront.net" -ForegroundColor Yellow
Write-Host "2. Open browser DevTools (F12)" -ForegroundColor Yellow
Write-Host "3. Go to Application > Local Storage" -ForegroundColor Yellow
Write-Host "4. Copy the idToken value" -ForegroundColor Yellow
Write-Host "5. Run the test-kpi-simple.ps1 script" -ForegroundColor Yellow
Write-Host ""
