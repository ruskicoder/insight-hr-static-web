# Setup API Gateway endpoints for Performance Handler
$ErrorActionPreference = "Stop"

Write-Host "=== Setting up API Gateway for Performance Handler ===" -ForegroundColor Cyan

# Configuration
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$AUTHORIZER_ID = "ytil4t"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-performance-handler"
$ACCOUNT_ID = "151507815244"

# Step 1: Create /performance resource
Write-Host "`nStep 1: Creating /performance resource..." -ForegroundColor Yellow
$performanceResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part "performance" --region $REGION 2>&1

if ($LASTEXITCODE -eq 0) {
    $performanceResourceId = ($performanceResource | ConvertFrom-Json).id
    Write-Host "Performance resource created: $performanceResourceId" -ForegroundColor Green
}
else {
    # Resource might already exist
    Write-Host "Resource might already exist, fetching..." -ForegroundColor Yellow
    $resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
    $performanceResourceId = ($resources.items | Where-Object { $_.path -eq "/performance" }).id
    
    if ($performanceResourceId) {
        Write-Host "Found existing resource: $performanceResourceId" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to create or find resource" -ForegroundColor Red
        exit 1
    }
}

# Step 2: Create GET method on /performance
Write-Host "`nStep 2: Creating GET method on /performance..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $performanceResourceId --http-method GET --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION

if ($LASTEXITCODE -eq 0) {
    Write-Host "GET method created" -ForegroundColor Green
}

# Step 3: Set up Lambda integration for GET /performance
Write-Host "`nStep 3: Setting up Lambda integration for GET..." -ForegroundColor Yellow
$uri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $performanceResourceId --http-method GET --type AWS_PROXY --integration-http-method POST --uri $uri --region $REGION

if ($LASTEXITCODE -eq 0) {
    Write-Host "Lambda integration configured" -ForegroundColor Green
}

# Step 4: Grant API Gateway permission to invoke Lambda
Write-Host "`nStep 4: Granting API Gateway permission..." -ForegroundColor Yellow
$sourceArn = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/performance"
aws lambda add-permission --function-name insighthr-performance-handler --statement-id apigateway-performance-get --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn $sourceArn --region $REGION 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Permission granted" -ForegroundColor Green
}
else {
    Write-Host "Permission might already exist" -ForegroundColor Yellow
}

# Step 5: Create OPTIONS method for CORS
Write-Host "`nStep 5: Creating OPTIONS method for CORS..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $performanceResourceId --http-method OPTIONS --authorization-type NONE --region $REGION

aws apigateway put-integration --rest-api-id $API_ID --resource-id $performanceResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`": 200}\`"}" --region $REGION

aws apigateway put-method-response --rest-api-id $API_ID --resource-id $performanceResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" --region $REGION

aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $performanceResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,Authorization'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $REGION

Write-Host "CORS configured" -ForegroundColor Green

# Step 6: Create /{employeeId} resource under /performance
Write-Host "`nStep 6: Creating /performance/{employeeId} resource..." -ForegroundColor Yellow
$employeeIdResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $performanceResourceId --path-part "{employeeId}" --region $REGION 2>&1

if ($LASTEXITCODE -eq 0) {
    $employeeIdResourceId = ($employeeIdResource | ConvertFrom-Json).id
    Write-Host "EmployeeId resource created: $employeeIdResourceId" -ForegroundColor Green
}
else {
    Write-Host "Resource might already exist, fetching..." -ForegroundColor Yellow
    $resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
    $employeeIdResourceId = ($resources.items | Where-Object { $_.path -eq "/performance/{employeeId}" }).id
    
    if ($employeeIdResourceId) {
        Write-Host "Found existing resource: $employeeIdResourceId" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to create or find resource" -ForegroundColor Red
        exit 1
    }
}

# Step 7: Create GET method on /performance/{employeeId}
Write-Host "`nStep 7: Creating GET method on /performance/{employeeId}..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $employeeIdResourceId --http-method GET --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION

aws apigateway put-integration --rest-api-id $API_ID --resource-id $employeeIdResourceId --http-method GET --type AWS_PROXY --integration-http-method POST --uri $uri --region $REGION

Write-Host "GET method configured" -ForegroundColor Green

# Step 8: Create /export resource under /performance
Write-Host "`nStep 8: Creating /performance/export resource..." -ForegroundColor Yellow
$exportResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $performanceResourceId --path-part "export" --region $REGION 2>&1

if ($LASTEXITCODE -eq 0) {
    $exportResourceId = ($exportResource | ConvertFrom-Json).id
    Write-Host "Export resource created: $exportResourceId" -ForegroundColor Green
}
else {
    Write-Host "Resource might already exist, fetching..." -ForegroundColor Yellow
    $resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
    $exportResourceId = ($resources.items | Where-Object { $_.path -eq "/performance/export" }).id
    
    if ($exportResourceId) {
        Write-Host "Found existing resource: $exportResourceId" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to create or find resource" -ForegroundColor Red
        exit 1
    }
}

# Step 9: Create POST method on /performance/export
Write-Host "`nStep 9: Creating POST method on /performance/export..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $exportResourceId --http-method POST --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION

aws apigateway put-integration --rest-api-id $API_ID --resource-id $exportResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $uri --region $REGION

Write-Host "POST method configured" -ForegroundColor Green

# Step 10: Deploy to dev stage
Write-Host "`nStep 10: Deploying to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployed to dev stage" -ForegroundColor Green
}

Write-Host "`n=== API Gateway Setup Complete ===" -ForegroundColor Cyan
Write-Host "Endpoints created:" -ForegroundColor White
Write-Host "  GET  https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/performance" -ForegroundColor Cyan
Write-Host "  GET  https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/performance/{employeeId}" -ForegroundColor Cyan
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/performance/export" -ForegroundColor Cyan
