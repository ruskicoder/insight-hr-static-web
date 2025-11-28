# Test script to verify chatbot provides detailed employee information

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Chatbot Detailed Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get API endpoint
$apiUrl = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/chatbot"

# Get admin token (you'll need to replace this with a valid token)
Write-Host "Note: You need to provide a valid JWT token for testing" -ForegroundColor Yellow
Write-Host "Get your token from the browser after logging in" -ForegroundColor Yellow
Write-Host ""

$token = Read-Host "Enter your JWT token"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "Error: Token is required" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Testing detailed information queries..." -ForegroundColor Green
Write-Host ""

# Test 1: Ask about specific employee
Write-Host "Test 1: Asking about specific employee DEV-001" -ForegroundColor Cyan
$body1 = @{
    message = "Who is employee DEV-001? Give me all their details."
} | ConvertTo-Json

$response1 = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
} -Body $body1

Write-Host "Response:" -ForegroundColor Yellow
Write-Host $response1.data.reply
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

# Test 2: Ask about performance scores
Write-Host "Test 2: Asking about specific performance score" -ForegroundColor Cyan
$body2 = @{
    message = "What is the performance score for employee DEV-001 in period 2025-1? Give me all details."
} | ConvertTo-Json

$response2 = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
} -Body $body2

Write-Host "Response:" -ForegroundColor Yellow
Write-Host $response2.data.reply
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

# Test 3: List employees in department
Write-Host "Test 3: Listing all employees in DEV department" -ForegroundColor Cyan
$body3 = @{
    message = "List all employees in the DEV department with their full details."
} | ConvertTo-Json

$response3 = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
} -Body $body3

Write-Host "Response:" -ForegroundColor Yellow
Write-Host $response3.data.reply
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
