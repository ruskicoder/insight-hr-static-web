# Test Authentication API Endpoints
$ErrorActionPreference = "Continue"

$API_BASE_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Authentication Endpoints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Register endpoint
Write-Host "Test 1: POST /auth/register" -ForegroundColor Yellow
Write-Host "Creating new test user..." -ForegroundColor Gray

$registerBody = @{
    email = "testuser@example.com"
    password = "TestPass123!"
    name = "Test User"
}

try {
    $registerResponse = Invoke-RestMethod -Uri "${API_BASE_URL}/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($registerBody | ConvertTo-Json)
    
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host ($registerResponse | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 2: Login endpoint
Write-Host "Test 2: POST /auth/login" -ForegroundColor Yellow
Write-Host "Logging in with test credentials..." -ForegroundColor Gray

$loginBody = @{
    email = "testuser@example.com"
    password = "TestPass123!"
}

try {
    $loginResponse = Invoke-RestMethod -Uri "${API_BASE_URL}/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($loginBody | ConvertTo-Json)
    
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host ($loginResponse | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 3: Login with invalid credentials
Write-Host "Test 3: POST /auth/login (invalid credentials)" -ForegroundColor Yellow
Write-Host "Testing error handling..." -ForegroundColor Gray

$invalidLoginBody = @{
    email = "invalid@example.com"
    password = "WrongPassword"
}

try {
    $invalidLoginResponse = Invoke-RestMethod -Uri "${API_BASE_URL}/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($invalidLoginBody | ConvertTo-Json)
    
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host ($invalidLoginResponse | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Expected error received:" -ForegroundColor Green
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Gray
    }
}
Write-Host ""

# Test 4: Google OAuth endpoint
Write-Host "Test 4: POST /auth/google" -ForegroundColor Yellow
Write-Host "Testing Google OAuth (mock)..." -ForegroundColor Gray

$googleBody = @{
    googleToken = "mock-google-token-12345"
}

try {
    $googleResponse = Invoke-RestMethod -Uri "${API_BASE_URL}/auth/google" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($googleBody | ConvertTo-Json)
    
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host ($googleResponse | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: Refresh endpoint
Write-Host "Test 5: POST /auth/refresh" -ForegroundColor Yellow
Write-Host "Testing token refresh (using login handler)..." -ForegroundColor Gray

$refreshBody = @{
    email = "testuser@example.com"
    password = "TestPass123!"
}

try {
    $refreshResponse = Invoke-RestMethod -Uri "${API_BASE_URL}/auth/refresh" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($refreshBody | ConvertTo-Json)
    
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host ($refreshResponse | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
