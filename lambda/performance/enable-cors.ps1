# Enable CORS for Performance API Gateway endpoints
$apiId = "lqk4t6qzag"
$region = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enable CORS for Performance Endpoints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get resource IDs
Write-Host "Fetching API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $apiId --region $region | ConvertFrom-Json
$performanceResourceId = ($resources.items | Where-Object { $_.path -eq "/performance" }).id
$employeeIdResourceId = ($resources.items | Where-Object { $_.path -eq "/performance/{employeeId}" }).id
$exportResourceId = ($resources.items | Where-Object { $_.path -eq "/performance/export" }).id

Write-Host "Resource IDs:" -ForegroundColor Gray
Write-Host "  /performance: $performanceResourceId" -ForegroundColor Gray
Write-Host "  /performance/{employeeId}: $employeeIdResourceId" -ForegroundColor Gray
Write-Host "  /performance/export: $exportResourceId" -ForegroundColor Gray
Write-Host ""

# Configure CORS for /performance
if ($performanceResourceId) {
    Write-Host "Configuring CORS for /performance endpoint..." -ForegroundColor Yellow
    aws apigateway put-method --rest-api-id $apiId --resource-id $performanceResourceId --http-method OPTIONS --authorization-type NONE --region $region 2>$null | Out-Null
    aws apigateway put-integration --rest-api-id $apiId --resource-id $performanceResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`": \`"{\\\`"statusCode\\\`": 200}\`"}" --region $region | Out-Null
    aws apigateway put-method-response --rest-api-id $apiId --resource-id $performanceResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" --region $region | Out-Null
    aws apigateway put-integration-response --rest-api-id $apiId --resource-id $performanceResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $region | Out-Null
    Write-Host "  ✓ CORS configured for /performance" -ForegroundColor Green
}

# Configure CORS for /performance/{employeeId}
if ($employeeIdResourceId) {
    Write-Host "Configuring CORS for /performance/{employeeId} endpoint..." -ForegroundColor Yellow
    aws apigateway put-method --rest-api-id $apiId --resource-id $employeeIdResourceId --http-method OPTIONS --authorization-type NONE --region $region 2>$null | Out-Null
    aws apigateway put-integration --rest-api-id $apiId --resource-id $employeeIdResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`": \`"{\\\`"statusCode\\\`": 200}\`"}" --region $region | Out-Null
    aws apigateway put-method-response --rest-api-id $apiId --resource-id $employeeIdResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" --region $region | Out-Null
    aws apigateway put-integration-response --rest-api-id $apiId --resource-id $employeeIdResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $region | Out-Null
    Write-Host "  ✓ CORS configured for /performance/{employeeId}" -ForegroundColor Green
}

# Configure CORS for /performance/export
if ($exportResourceId) {
    Write-Host "Configuring CORS for /performance/export endpoint..." -ForegroundColor Yellow
    aws apigateway put-method --rest-api-id $apiId --resource-id $exportResourceId --http-method OPTIONS --authorization-type NONE --region $region 2>$null | Out-Null
    aws apigateway put-integration --rest-api-id $apiId --resource-id $exportResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`": \`"{\\\`"statusCode\\\`": 200}\`"}" --region $region | Out-Null
    aws apigateway put-method-response --rest-api-id $apiId --resource-id $exportResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" --region $region | Out-Null
    aws apigateway put-integration-response --rest-api-id $apiId --resource-id $exportResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $region | Out-Null
    Write-Host "  ✓ CORS configured for /performance/export" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name dev --description "Enable CORS for performance endpoints" --region $region | Out-Null
Write-Host "✓ API deployed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORS Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All performance endpoints now support CORS preflight requests" -ForegroundColor White
Write-Host "Access-Control-Allow-Origin: *" -ForegroundColor Gray
Write-Host "Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS" -ForegroundColor Gray
Write-Host "Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token" -ForegroundColor Gray
Write-Host ""
