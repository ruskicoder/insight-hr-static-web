# Enable CORS for API Gateway endpoints
# This script adds OPTIONS methods to API Gateway endpoints for CORS preflight support
# Run this script after creating new API Gateway endpoints that need CORS

$apiId = "lqk4t6qzag"
$region = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enable CORS for API Gateway Endpoints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get resource IDs
Write-Host "Fetching API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $apiId --region $region | ConvertFrom-Json
$loginResourceId = ($resources.items | Where-Object { $_.path -eq "/auth/login" }).id
$registerResourceId = ($resources.items | Where-Object { $_.path -eq "/auth/register" }).id
$googleResourceId = ($resources.items | Where-Object { $_.path -eq "/auth/google" }).id

Write-Host "Resource IDs:" -ForegroundColor Gray
Write-Host "  Login: $loginResourceId" -ForegroundColor Gray
Write-Host "  Register: $registerResourceId" -ForegroundColor Gray
Write-Host "  Google: $googleResourceId" -ForegroundColor Gray
Write-Host ""

# Function to add OPTIONS method with CORS headers
function Add-CorsOptions {
    param([string]$ResourceId, [string]$ResourceName)
    
    Write-Host "Configuring CORS for $ResourceName endpoint..." -ForegroundColor Yellow
    
    # Create OPTIONS method
    aws apigateway put-method --rest-api-id $apiId --resource-id $ResourceId --http-method OPTIONS --authorization-type NONE --region $region 2>$null | Out-Null
    
    # Create mock integration (returns 200 immediately)
    aws apigateway put-integration --rest-api-id $apiId --resource-id $ResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`": \`"{\\\`"statusCode\\\`": 200}\`"}" --region $region | Out-Null
    
    # Create method response with CORS header parameters
    aws apigateway put-method-response --rest-api-id $apiId --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" --region $region | Out-Null
    
    # Create integration response with actual CORS header values
    aws apigateway put-integration-response --rest-api-id $apiId --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $region | Out-Null
    
    Write-Host "  ✓ CORS configured for $ResourceName" -ForegroundColor Green
}

# Add CORS to all auth endpoints
Add-CorsOptions -ResourceId $loginResourceId -ResourceName "Login"
Add-CorsOptions -ResourceId $registerResourceId -ResourceName "Register"
Add-CorsOptions -ResourceId $googleResourceId -ResourceName "Google"

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name dev --description "Enable CORS for auth endpoints" --region $region | Out-Null
Write-Host "✓ API deployed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORS Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All auth endpoints now support CORS preflight requests" -ForegroundColor White
Write-Host "Access-Control-Allow-Origin: *" -ForegroundColor Gray
Write-Host "Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS" -ForegroundColor Gray
Write-Host "Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token" -ForegroundColor Gray
Write-Host ""
