# Test KPI API Gateway endpoints
$API_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

Write-Host "=== Testing KPI API Endpoints ===" -ForegroundColor Cyan

# Step 1: Login to get token
Write-Host ""
Write-Host "1. Logging in to get auth token..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@insighthr.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$API_URL/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.tokens.idToken

if ($token) {
    Write-Host "Login successful, token obtained" -ForegroundColor Green
} else {
    Write-Host "Login failed" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Step 2: List all KPIs
Write-Host ""
Write-Host "2. Testing GET /kpis (list all KPIs)..." -ForegroundColor Yellow
try {
    $kpisResponse = Invoke-RestMethod -Uri "$API_URL/kpis" -Method GET -Headers $headers
    Write-Host "GET /kpis successful" -ForegroundColor Green
    Write-Host "KPIs count: $($kpisResponse.kpis.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "GET /kpis failed: $_" -ForegroundColor Red
}

# Step 3: Create a new KPI
Write-Host ""
Write-Host "3. Testing POST /kpis (create new KPI)..." -ForegroundColor Yellow
$newKpi = @{
    name = "Sales Target Achievement"
    description = "Percentage of sales target achieved"
    dataType = "percentage"
    category = "Sales"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$API_URL/kpis" -Method POST -Headers $headers -Body $newKpi
    $kpiId = $createResponse.kpi.kpiId
    Write-Host "POST /kpis successful" -ForegroundColor Green
    Write-Host "Created KPI ID: $kpiId" -ForegroundColor Cyan
} catch {
    Write-Host "POST /kpis failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Get single KPI
Write-Host ""
Write-Host "4. Testing GET /kpis/{kpiId} (get single KPI)..." -ForegroundColor Yellow
try {
    $kpiResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method GET -Headers $headers
    Write-Host "GET /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "KPI Name: $($kpiResponse.kpi.name)" -ForegroundColor Cyan
} catch {
    Write-Host "GET /kpis/{kpiId} failed: $_" -ForegroundColor Red
}

# Step 5: Update KPI
Write-Host ""
Write-Host "5. Testing PUT /kpis/{kpiId} (update KPI)..." -ForegroundColor Yellow
$updateKpi = @{
    description = "Updated: Percentage of monthly sales target achieved"
    category = "Sales Performance"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method PUT -Headers $headers -Body $updateKpi
    Write-Host "PUT /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "Updated description: $($updateResponse.kpi.description)" -ForegroundColor Cyan
} catch {
    Write-Host "PUT /kpis/{kpiId} failed: $_" -ForegroundColor Red
}

# Step 6: Soft delete KPI
Write-Host ""
Write-Host "6. Testing DELETE /kpis/{kpiId} (soft delete KPI)..." -ForegroundColor Yellow
try {
    $deleteResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method DELETE -Headers $headers
    Write-Host "DELETE /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "Message: $($deleteResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "DELETE /kpis/{kpiId} failed: $_" -ForegroundColor Red
}

# Step 7: Verify KPI is disabled
Write-Host ""
Write-Host "7. Verifying KPI is disabled..." -ForegroundColor Yellow
try {
    $kpiResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method GET -Headers $headers
    Write-Host "GET /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "KPI isActive: $($kpiResponse.kpi.isActive)" -ForegroundColor Cyan
    if ($kpiResponse.kpi.isActive -eq $false) {
        Write-Host "KPI successfully disabled (soft delete)" -ForegroundColor Green
    }
} catch {
    Write-Host "GET /kpis/{kpiId} failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Tests Complete ===" -ForegroundColor Green
