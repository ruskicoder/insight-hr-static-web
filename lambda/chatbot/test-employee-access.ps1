# Test script to verify employee data access policy in chatbot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Chatbot Employee Access Policy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get tokens for different user roles
Write-Host "Getting test user tokens..." -ForegroundColor Yellow

# Admin user token (replace with actual admin token)
$adminToken = Read-Host "Enter Admin user idToken"

# Manager user token (replace with actual manager token)
$managerToken = Read-Host "Enter Manager user idToken"

# Employee user token (replace with actual employee token)
$employeeToken = Read-Host "Enter Employee user idToken"

$apiUrl = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/chatbot/message"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 1: Admin asking about employees" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$body = @{
    message = "List all employees in the DEV department"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    Write-Host $response.data.reply
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 2: Manager asking about their department" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$body = @{
    message = "How many employees are in my department?"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $managerToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    Write-Host $response.data.reply
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 3: Employee asking about other employees" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$body = @{
    message = "List all employees in the company"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $employeeToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    Write-Host $response.data.reply
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 4: Employee asking about their own performance" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$body = @{
    message = "What is my performance score?"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $employeeToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    Write-Host $response.data.reply
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
