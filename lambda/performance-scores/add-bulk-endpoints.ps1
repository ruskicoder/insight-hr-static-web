# Add bulk operations endpoints to Performance Scores API
# This script adds /performance-scores/bulk and /performance-scores/template/{year}/{quarter} endpoints

$ErrorActionPreference = "Stop"

Write-Host "=== Adding Bulk Operations Endpoints ===" -ForegroundColor Cyan

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
    Write-Host "Warning: Cognito authorizer not found. Endpoints will be created without authorization." -ForegroundColor Yellow
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

# Create /performance-scores/bulk resource
Write-Host "`nCreating /performance-scores/bulk resource..." -ForegroundColor Yellow
$BULK_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/bulk'].id" --output text

if ([string]::IsNullOrEmpty($BULK_RESOURCE)) {
    $BULK_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $PERF_SCORES_RESOURCE `
        --path-part "bulk" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/bulk resource: $BULK_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/bulk resource already exists: $BULK_RESOURCE" -ForegroundColor Green
}

# Create /performance-scores/template resource
Write-Host "`nCreating /performance-scores/template resource..." -ForegroundColor Yellow
$TEMPLATE_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/template'].id" --output text

if ([string]::IsNullOrEmpty($TEMPLATE_RESOURCE)) {
    $TEMPLATE_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $PERF_SCORES_RESOURCE `
        --path-part "template" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/template resource: $TEMPLATE_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/template resource already exists: $TEMPLATE_RESOURCE" -ForegroundColor Green
}

# Create /performance-scores/template/{year} resource
Write-Host "`nCreating /performance-scores/template/{year} resource..." -ForegroundColor Yellow
$YEAR_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/template/{year}'].id" --output text

if ([string]::IsNullOrEmpty($YEAR_RESOURCE)) {
    $YEAR_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $TEMPLATE_RESOURCE `
        --path-part "{year}" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/template/{year} resource: $YEAR_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/template/{year} resource already exists: $YEAR_RESOURCE" -ForegroundColor Green
}

# Create /performance-scores/template/{year}/{quarter} resource
Write-Host "`nCreating /performance-scores/template/{year}/{quarter} resource..." -ForegroundColor Yellow
$QUARTER_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/template/{year}/{quarter}'].id" --output text

if ([string]::IsNullOrEmpty($QUARTER_RESOURCE)) {
    $QUARTER_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $YEAR_RESOURCE `
        --path-part "{quarter}" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/template/{year}/{quarter} resource: $QUARTER_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/template/{year}/{quarter} resource already exists: $QUARTER_RESOURCE" -ForegroundColor Green
}

# Function to create method with Lambda integration
function Create-Method {
    param (
        [string]$ResourceId,
        [string]$HttpMethod,
        [string]$Path
    )
    
    Write-Host "`nCreating $HttpMethod method for $Path..." -ForegroundColor Yellow
    
    $ErrorActionPreference = "Continue"
    
    # Create method
    if ($AUTHORIZER_ID) {
        aws apigateway put-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method $HttpMethod `
            --authorization-type COGNITO_USER_POOLS `
            --authorizer-id $AUTHORIZER_ID `
            --region $REGION 2>$null
    } else {
        aws apigateway put-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method $HttpMethod `
            --authorization-type NONE `
            --region $REGION 2>$null
    }
    
    # Create integration
    $URI = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"
    
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method $HttpMethod `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri $URI `
        --region $REGION 2>$null
    
    $ErrorActionPreference = "Stop"
    
    Write-Host "$HttpMethod method created for $Path" -ForegroundColor Green
}

# Function to create OPTIONS method for CORS
function Create-Options-Method {
    param (
        [string]$ResourceId,
        [string]$Path
    )
    
    Write-Host "`nCreating OPTIONS method for $Path (CORS)..." -ForegroundColor Yellow
    
    $ErrorActionPreference = "Continue"
    
    # Create OPTIONS method
    aws apigateway put-method `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --authorization-type NONE `
        --region $REGION 2>$null
    
    # Create MOCK integration
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --type MOCK `
        --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`": 200}\`"}" `
        --region $REGION 2>$null
    
    # Create method response
    aws apigateway put-method-response `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" `
        --region $REGION 2>$null
    
    # Create integration response
    aws apigateway put-integration-response `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters "{\"method.response.header.Access-Control-Allow-Headers\":\"'Content-Type,Authorization'\",\"method.response.header.Access-Control-Allow-Methods\":\"'GET,POST,PUT,DELETE,OPTIONS'\",\"method.response.header.Access-Control-Allow-Origin\":\"'*'\"}" `
        --region $REGION 2>$null
    
    $ErrorActionPreference = "Stop"
    
    Write-Host "OPTIONS method created for $Path" -ForegroundColor Green
}

# Create methods for /performance-scores/bulk
Create-Method -ResourceId $BULK_RESOURCE -HttpMethod "POST" -Path "/performance-scores/bulk"
Create-Options-Method -ResourceId $BULK_RESOURCE -Path "/performance-scores/bulk"

# Create methods for /performance-scores/template/{year}/{quarter}
Create-Method -ResourceId $QUARTER_RESOURCE -HttpMethod "GET" -Path "/performance-scores/template/{year}/{quarter}"
Create-Options-Method -ResourceId $QUARTER_RESOURCE -Path "/performance-scores/template/{year}/{quarter}"

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
Write-Host "`nNew endpoints:" -ForegroundColor Yellow
Write-Host "  POST   $API_ENDPOINT/performance-scores/bulk" -ForegroundColor White
Write-Host "  GET    $API_ENDPOINT/performance-scores/template/{year}/{quarter}" -ForegroundColor White

