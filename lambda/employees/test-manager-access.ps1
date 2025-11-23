# Test Manager Access to Employees Endpoint
# This script tests if a Manager user can see employees from their department

$API_URL = "https://yvz0zrwxe8.execute-api.ap-southeast-1.amazonaws.com/dev"

# Get Manager user token (you'll need to replace this with actual token)
Write-Host "Testing Manager Access to Employees" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check what the Lambda receives
Write-Host "Test 1: GET /employees (Manager user)" -ForegroundColor Yellow
Write-Host "Note: You need to provide a valid Manager JWT token" -ForegroundColor Gray
Write-Host ""
Write-Host "curl command:" -ForegroundColor Green
Write-Host 'curl -X GET "$API_URL/employees" -H "Authorization: Bearer YOUR_MANAGER_TOKEN"' -ForegroundColor White
Write-Host ""

# Test 2: Check CloudWatch logs
Write-Host "Test 2: Check Lambda logs" -ForegroundColor Yellow
Write-Host "aws logs tail /aws/lambda/insighthr-employees-handler --follow --region ap-southeast-1" -ForegroundColor White
Write-Host ""

# Test 3: Check Users table for Manager user
Write-Host "Test 3: Query Users table for Manager" -ForegroundColor Yellow
Write-Host 'aws dynamodb scan --table-name insighthr-users-dev --filter-expression "role = :role" --expression-attribute-values "{\":role\":{\"S\":\"Manager\"}}" --region ap-southeast-1' -ForegroundColor White
Write-Host ""

Write-Host "Instructions:" -ForegroundColor Cyan
Write-Host "1. Login as Manager user in the web app" -ForegroundColor White
Write-Host "2. Open browser DevTools > Network tab" -ForegroundColor White
Write-Host "3. Navigate to Employee Management" -ForegroundColor White
Write-Host "4. Copy the Authorization header from the request" -ForegroundColor White
Write-Host "5. Use it to test the endpoint manually" -ForegroundColor White
