# Simple test for KPI endpoints
# You need to provide a valid JWT token

$API_URL = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

Write-Host "=== Testing KPI API Endpoints ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please login to https://d2z6tht6rq32uy.cloudfront.net and get your JWT token from browser DevTools" -ForegroundColor Yellow
Write-Host "Then paste it here:" -ForegroundColor Yellow
$token = Read-Host

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "No token provided, exiting..." -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Test 1: List all KPIs
Write-Host ""
Write-Host "1. Testing GET /kpis..." -ForegroundColor Yellow
try {
    $kpisResponse = Invoke-RestMethod -Uri "$API_URL/kpis" -Method GET -Headers $headers
    Write-Host "✓ GET /kpis successful" -ForegroundColor Green
    Write-Host "KPIs count: $($kpisResponse.kpis.Count)" -ForegroundColor Cyan
    if ($kpisResponse.kpis.Count -gt 0) {
        Write-Host "First KPI: $($kpisResponse.kpis[0].name)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ GET /kpis failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test 2: Create a new KPI
Write-Host ""
Write-Host "2. Testing POST /kpis..." -ForegroundColor Yellow
$newKpi = @{
    name = "Customer Satisfaction Score"
    description = "Average customer satisfaction rating"
    dataType = "number"
    category = "Customer Service"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$API_URL/kpis" -Method POST -Headers $headers -Body $newKpi
    $kpiId = $createResponse.kpi.kpiId
    Write-Host "✓ POST /kpis successful" -ForegroundColor Green
    Write-Host "Created KPI ID: $kpiId" -ForegroundColor Cyan
    Write-Host "KPI Name: $($createResponse.kpi.name)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ POST /kpis failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test 3: Get single KPI
Write-Host ""
Write-Host "3. Testing GET /kpis/{kpiId}..." -ForegroundColor Yellow
try {
    $kpiResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method GET -Headers $headers
    Write-Host "✓ GET /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "KPI: $($kpiResponse.kpi.name) - $($kpiResponse.kpi.description)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ GET /kpis/{kpiId} failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Test 4: Update KPI
Write-Host ""
Write-Host "4. Testing PUT /kpis/{kpiId}..." -ForegroundColor Yellow
$updateKpi = @{
    description = "Updated: Average customer satisfaction rating (1-10 scale)"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method PUT -Headers $headers -Body $updateKpi
    Write-Host "✓ PUT /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "Updated description: $($updateResponse.kpi.description)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ PUT /kpis/{kpiId} failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Test 5: Delete KPI (soft delete)
Write-Host ""
Write-Host "5. Testing DELETE /kpis/{kpiId}..." -ForegroundColor Yellow
try {
    $deleteResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method DELETE -Headers $headers
    Write-Host "✓ DELETE /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "Message: $($deleteResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ DELETE /kpis/{kpiId} failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Test 6: Verify soft delete
Write-Host ""
Write-Host "6. Verifying soft delete..." -ForegroundColor Yellow
try {
    $kpiResponse = Invoke-RestMethod -Uri "$API_URL/kpis/$kpiId" -Method GET -Headers $headers
    Write-Host "✓ GET /kpis/{kpiId} successful" -ForegroundColor Green
    Write-Host "KPI isActive: $($kpiResponse.kpi.isActive)" -ForegroundColor Cyan
    if ($kpiResponse.kpi.isActive -eq $false) {
        Write-Host "✓ Soft delete verified - KPI is disabled" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Verification failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Tests Complete ===" -ForegroundColor Green
