# Test updating a performance score
# This script tests the PUT /performance-scores/{employeeId}/{period} endpoint

$API_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"
$EMPLOYEE_ID = "DEV-00197"
$PERIOD = "2025-2"

# Get ID token from login (replace with your actual admin credentials)
Write-Host "Testing Performance Score Update Endpoint..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# You need to login first and get the idToken
# For now, let's just test if the endpoint is accessible
Write-Host "Endpoint: PUT $API_URL/performance-scores/$EMPLOYEE_ID/$PERIOD" -ForegroundColor Yellow
Write-Host ""
Write-Host "To test this endpoint, you need to:" -ForegroundColor Yellow
Write-Host "1. Login as Admin user and get the idToken" -ForegroundColor Yellow
Write-Host "2. Use the idToken in the Authorization header" -ForegroundColor Yellow
Write-Host "3. Send a PUT request with the score data" -ForegroundColor Yellow
Write-Host ""

# Example curl command (replace TOKEN with actual idToken)
Write-Host "Example curl command:" -ForegroundColor Green
Write-Host @"
curl -X PUT "$API_URL/performance-scores/$EMPLOYEE_ID/$PERIOD" \
  -H "Authorization: Bearer YOUR_ID_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "KPI": 85.5,
    "completed_task": 90.0,
    "feedback_360": 88.0,
    "final_score": 87.8
  }'
"@ -ForegroundColor White

Write-Host ""
Write-Host "Note: Make sure you're using the idToken (not accessToken) from Cognito" -ForegroundColor Yellow
Write-Host "The idToken contains the user's email which is used to look up their role" -ForegroundColor Yellow
