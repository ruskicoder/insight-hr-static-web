# Test Performance Scores API Endpoints
# This script tests all performance score CRUD endpoints

$ErrorActionPreference = "Stop"

Write-Host "=== Testing Performance Scores API Endpoints ===" -ForegroundColor Cyan

# Configuration
$API_NAME = "Insighthr_api"
$REGION = "ap-southeast-1"

# Get API Gateway ID
Write-Host "`nGetting API Gateway ID..." -ForegroundColor Yellow
$API_ID = aws apigateway get-rest-apis --region $REGION --query "items[?name=='$API_NAME'].id" --output text

if ([string]::IsNullOrEmpty($API_ID)) {
    Write-Host "Error: API Gateway '$API_NAME' not found" -ForegroundColor Red
    exit 1
}

$API_ENDPOINT = "https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev"
Write-Host "API Endpoint: $API_ENDPOINT" -ForegroundColor Green

# Get ID token (you need to replace this with a real token)
Write-Host "`nNote: You need a valid ID token to test these endpoints" -ForegroundColor Yellow
Write-Host "Get your token from: insighthr-web/public/check-token.html" -ForegroundColor Yellow
Write-Host "Or login and check localStorage.getItem('idToken')" -ForegroundColor Yellow

$ID_TOKEN = Read-Host "`nEnter your ID token (or press Enter to skip authenticated tests)"

if ([string]::IsNullOrEmpty($ID_TOKEN)) {
    Write-Host "Skipping authenticated tests" -ForegroundColor Yellow
} else {
    $HEADERS = @{
        "Authorization" = "Bearer $ID_TOKEN"
        "Content-Type" = "application/json"
    }
    
    # Test 1: GET /performance-scores (list all scores)
    Write-Host "`n=== Test 1: GET /performance-scores ===" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores" -Method Get -Headers $HEADERS
        Write-Host "Success! Found $($response.count) scores" -ForegroundColor Green
        if ($response.scores.Count -gt 0) {
            Write-Host "Sample score:" -ForegroundColor Yellow
            $response.scores[0] | ConvertTo-Json -Depth 3
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: GET /performance-scores with filters
    Write-Host "`n=== Test 2: GET /performance-scores?department=DEV&period=2025-1 ===" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores?department=DEV&period=2025-1" -Method Get -Headers $HEADERS
        Write-Host "Success! Found $($response.count) scores for DEV department in 2025-1" -ForegroundColor Green
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: GET /performance-scores/{employeeId}/{period}
    Write-Host "`n=== Test 3: GET /performance-scores/DEV-01001/2025-1 ===" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores/DEV-01001/2025-1" -Method Get -Headers $HEADERS
        Write-Host "Success! Retrieved score:" -ForegroundColor Green
        $response.score | ConvertTo-Json -Depth 3
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 4: POST /performance-scores (create new score)
    Write-Host "`n=== Test 4: POST /performance-scores (create) ===" -ForegroundColor Cyan
    $newScore = @{
        employeeId = "DEV-01001"
        period = "2025-4"
        KPI = 85.5
        completed_task = 90.0
        feedback_360 = 88.5
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores" -Method Post -Headers $HEADERS -Body $newScore
        Write-Host "Success! Created score:" -ForegroundColor Green
        $response.score | ConvertTo-Json -Depth 3
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: This might fail if you're not an Admin or if the score already exists" -ForegroundColor Yellow
    }
    
    # Test 5: PUT /performance-scores/{employeeId}/{period} (update)
    Write-Host "`n=== Test 5: PUT /performance-scores/DEV-01001/2025-4 (update) ===" -ForegroundColor Cyan
    $updateScore = @{
        KPI = 90.0
        completed_task = 92.0
        feedback_360 = 91.0
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores/DEV-01001/2025-4" -Method Put -Headers $HEADERS -Body $updateScore
        Write-Host "Success! Updated score:" -ForegroundColor Green
        $response.score | ConvertTo-Json -Depth 3
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: This might fail if you're not an Admin or if the score doesn't exist" -ForegroundColor Yellow
    }
    
    # Test 6: DELETE /performance-scores/{employeeId}/{period}
    Write-Host "`n=== Test 6: DELETE /performance-scores/DEV-01001/2025-4 ===" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "$API_ENDPOINT/performance-scores/DEV-01001/2025-4" -Method Delete -Headers $HEADERS
        Write-Host "Success! Deleted score" -ForegroundColor Green
        $response | ConvertTo-Json
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: This might fail if you're not an Admin or if the score doesn't exist" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- GET /performance-scores: List all scores with filters" -ForegroundColor White
Write-Host "- GET /performance-scores/{employeeId}/{period}: Get single score" -ForegroundColor White
Write-Host "- POST /performance-scores: Create new score (Admin only)" -ForegroundColor White
Write-Host "- PUT /performance-scores/{employeeId}/{period}: Update score (Admin only)" -ForegroundColor White
Write-Host "- DELETE /performance-scores/{employeeId}/{period}: Delete score (Admin only)" -ForegroundColor White
