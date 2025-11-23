# Fix CORS for Performance API Gateway endpoints
$ErrorActionPreference = "Stop"

Write-Host "=== Fixing CORS for Performance Endpoints ===" -ForegroundColor Cyan

# Configuration
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"

# Get all resources
Write-Host "`nFetching API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json

# Find performance resources
$performanceResource = $resources.items | Where-Object { $_.path -eq "/performance" }
$employeeIdResource = $resources.items | Where-Object { $_.path -eq "/performance/{employeeId}" }
$exportResource = $resources.items | Where-Object { $_.path -eq "/performance/export" }

Write-Host "Found resources:" -ForegroundColor Green
Write-Host "  /performance: $($performanceResource.id)" -ForegroundColor Cyan
Write-Host "  /performance/{employeeId}: $($employeeIdResource.id)" -ForegroundColor Cyan
Write-Host "  /performance/export: $($exportResource.id)" -ForegroundColor Cyan

# Function to add CORS to a resource
function Add-CorsToResource {
    param(
        [string]$ResourceId,
        [string]$ResourcePath,
        [string]$AllowedMethods
    )
    
    Write-Host "`nConfiguring CORS for $ResourcePath..." -ForegroundColor Yellow
    
    # Create OPTIONS method
    Write-Host "  Creating OPTIONS method..." -ForegroundColor White
    aws apigateway put-method --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --authorization-type NONE --region $REGION 2>&1 | Out-Null
    
    # Create MOCK integration
    Write-Host "  Creating MOCK integration..." -ForegroundColor White
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --type MOCK --request-templates "{`"application/json`":`"{\\`"statusCode\\`": 200}`"}" --region $REGION 2>&1 | Out-Null
    
    # Create method response
    Write-Host "  Creating method response..." -ForegroundColor White
    aws apigateway put-method-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "{`"method.response.header.Access-Control-Allow-Headers`":false,`"method.response.header.Access-Control-Allow-Methods`":false,`"method.response.header.Access-Control-Allow-Origin`":false}" --region $REGION 2>&1 | Out-Null
    
    # Create integration response
    Write-Host "  Creating integration response..." -ForegroundColor White
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "{`"method.response.header.Access-Control-Allow-Headers`":`"'Content-Type,Authorization'`",`"method.response.header.Access-Control-Allow-Methods`":`"'$AllowedMethods'`",`"method.response.header.Access-Control-Allow-Origin`":`"'*'`"}" --region $REGION 2>&1 | Out-Null
    
    Write-Host "  ✓ CORS configured for $ResourcePath" -ForegroundColor Green
}

# Add CORS to all performance endpoints
if ($performanceResource) {
    Add-CorsToResource -ResourceId $performanceResource.id -ResourcePath "/performance" -AllowedMethods "GET,POST,OPTIONS"
}

if ($employeeIdResource) {
    Add-CorsToResource -ResourceId $employeeIdResource.id -ResourcePath "/performance/{employeeId}" -AllowedMethods "GET,OPTIONS"
}

if ($exportResource) {
    Add-CorsToResource -ResourceId $exportResource.id -ResourcePath "/performance/export" -AllowedMethods "POST,OPTIONS"
}

# Deploy to dev stage
Write-Host "`nDeploying to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Deployed to dev stage" -ForegroundColor Green
}

Write-Host "`n=== CORS Configuration Complete ===" -ForegroundColor Cyan
Write-Host "All performance endpoints now have CORS enabled" -ForegroundColor Green
