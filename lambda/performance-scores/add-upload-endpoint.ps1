# Add upload endpoint to Performance Scores API

$ErrorActionPreference = "Stop"

Write-Host "=== Adding Upload Endpoint ===" -ForegroundColor Cyan

# Configuration
$API_NAME = "Insighthr_api"
$REGION = "ap-southeast-1"
$FUNCTION_NAME = "insighthr-performance-scores-handler"
$AUTHORIZER_NAME = "insighthr-cognito-authorizer"

# Get API Gateway ID
Write-Host "`nGetting API Gateway ID..." -ForegroundColor Yellow
$API_ID = aws apigateway get-rest-apis --region $REGION --query "items[?name=='$API_NAME'].id" --output text

if ([string]::IsNullOrEmpty($API_ID)) {
    Write-Host "Error: API Gateway '$API_NAME' not found" -ForegroundColor Red
    exit 1
}

Write-Host "API Gateway ID: $API_ID" -ForegroundColor Green

# Get Lambda ARN
Write-Host "`nGetting Lambda ARN..." -ForegroundColor Yellow
$LAMBDA_ARN = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text

Write-Host "Lambda ARN: $LAMBDA_ARN" -ForegroundColor Green

# Get Cognito Authorizer ID
Write-Host "`nGetting Cognito Authorizer ID..." -ForegroundColor Yellow
$AUTHORIZER_ID = aws apigateway get-authorizers --rest-api-id $API_ID --region $REGION --query "items[?name=='$AUTHORIZER_NAME'].id" --output text

if ([string]::IsNullOrEmpty($AUTHORIZER_ID)) {
    Write-Host "Warning: Cognito authorizer not found. Endpoint will be created without authorization." -ForegroundColor Yellow
} else {
    Write-Host "Authorizer ID: $AUTHORIZER_ID" -ForegroundColor Green
}

# Get /performance-scores resource ID
Write-Host "`nGetting /performance-scores resource ID..." -ForegroundColor Yellow
$PERF_SCORES_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores'].id" --output text

if ([string]::IsNullOrEmpty($PERF_SCORES_RESOURCE)) {
    Write-Host "Error: /performance-scores resource not found" -ForegroundColor Red
    exit 1
}

Write-Host "/performance-scores resource ID: $PERF_SCORES_RESOURCE" -ForegroundColor Green

# Create /performance-scores/upload resource
Write-Host "`nCreating /performance-scores/upload resource..." -ForegroundColor Yellow
$UPLOAD_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/upload'].id" --output text

if ([string]::IsNullOrEmpty($UPLOAD_RESOURCE)) {
    $UPLOAD_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $PERF_SCORES_RESOURCE `
        --path-part "upload" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/upload resource: $UPLOAD_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/upload resource already exists: $UPLOAD_RESOURCE" -ForegroundColor Green
}

# Create POST method
Write-Host "`nCreating POST method for /performance-scores/upload..." -ForegroundColor Yellow

$ErrorActionPreference = "Continue"

# Create method
if ($AUTHORIZER_ID) {
    aws apigateway put-method `
        --rest-api-id $API_ID `
        --resource-id $UPLOAD_RESOURCE `
        --http-method POST `
        --authorization-type COGNITO_USER_POOLS `
        --authorizer-id $AUTHORIZER_ID `
        --region $REGION 2>$null
} else {
    aws apigateway put-method `
        --rest-api-id $API_ID `
        --resource-id $UPLOAD_RESOURCE `
        --http-method POST `
        --authorization-type NONE `
        --region $REGION 2>$null
}

# Create integration
$URI = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $UPLOAD_RESOURCE `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri $URI `
    --region $REGION 2>$null

Write-Host "POST method created" -ForegroundColor Green

# Create OPTIONS method for CORS
Write-Host "`nCreating OPTIONS method for CORS..." -ForegroundColor Yellow

# Create OPTIONS method
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $UPLOAD_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

# Create MOCK integration
$requestTemplates = '{"application/json":"{\"statusCode\": 200}"}'
aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $UPLOAD_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates $requestTemplates `
    --region $REGION 2>$null

# Create method response
aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $UPLOAD_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" `
    --region $REGION 2>$null

# Create integration response
aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $UPLOAD_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\"method.response.header.Access-Control-Allow-Headers\":\"'Content-Type,Authorization'\",\"method.response.header.Access-Control-Allow-Methods\":\"'GET,POST,PUT,DELETE,OPTIONS'\",\"method.response.header.Access-Control-Allow-Origin\":\"'*'\"}" `
    --region $REGION 2>$null

$ErrorActionPreference = "Stop"

Write-Host "OPTIONS method created" -ForegroundColor Green

# Deploy API
Write-Host "`nDeploying API to 'dev' stage..." -ForegroundColor Yellow

aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --region $REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to deploy API" -ForegroundColor Red
    exit 1
}

Write-Host "API deployed successfully" -ForegroundColor Green

# Display API endpoint
$API_ENDPOINT = "https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev"

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "API Endpoint: $API_ENDPOINT" -ForegroundColor Green
Write-Host "`nNew endpoint:" -ForegroundColor Yellow
Write-Host "  POST   $API_ENDPOINT/performance-scores/upload" -ForegroundColor White
