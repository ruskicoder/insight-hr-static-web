# Setup API Gateway endpoints for Performance Scores Lambda
# This script creates API Gateway resources and methods for performance score CRUD operations

$ErrorActionPreference = "Stop"

Write-Host "=== Setting up API Gateway for Performance Scores ===" -ForegroundColor Cyan

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

# Get root resource ID
Write-Host "`nGetting root resource ID..." -ForegroundColor Yellow
$ROOT_ID = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/'].id" --output text

Write-Host "Root Resource ID: $ROOT_ID" -ForegroundColor Green

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

# Create /performance-scores resource
Write-Host "`nCreating /performance-scores resource..." -ForegroundColor Yellow
$PERF_SCORES_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores'].id" --output text

if ([string]::IsNullOrEmpty($PERF_SCORES_RESOURCE)) {
    $PERF_SCORES_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $ROOT_ID `
        --path-part "performance-scores" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores resource: $PERF_SCORES_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores resource already exists: $PERF_SCORES_RESOURCE" -ForegroundColor Green
}

# Create /{employeeId} resource under /performance-scores
Write-Host "`nCreating /performance-scores/{employeeId} resource..." -ForegroundColor Yellow
$EMPLOYEE_ID_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/{employeeId}'].id" --output text

if ([string]::IsNullOrEmpty($EMPLOYEE_ID_RESOURCE)) {
    $EMPLOYEE_ID_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $PERF_SCORES_RESOURCE `
        --path-part "{employeeId}" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/{employeeId} resource: $EMPLOYEE_ID_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/{employeeId} resource already exists: $EMPLOYEE_ID_RESOURCE" -ForegroundColor Green
}

# Create /{period} resource under /performance-scores/{employeeId}
Write-Host "`nCreating /performance-scores/{employeeId}/{period} resource..." -ForegroundColor Yellow
$PERIOD_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/performance-scores/{employeeId}/{period}'].id" --output text

if ([string]::IsNullOrEmpty($PERIOD_RESOURCE)) {
    $PERIOD_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $EMPLOYEE_ID_RESOURCE `
        --path-part "{period}" `
        --region $REGION `
        --query 'id' --output text
    
    Write-Host "Created /performance-scores/{employeeId}/{period} resource: $PERIOD_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "/performance-scores/{employeeId}/{period} resource already exists: $PERIOD_RESOURCE" -ForegroundColor Green
}

# Function to create method with Lambda integration
function Create-Method {
    param (
        [string]$ResourceId,
        [string]$HttpMethod,
        [string]$Path
    )
    
    Write-Host "`nCreating $HttpMethod method for $Path..." -ForegroundColor Yellow
    
    # Create method
    $ErrorActionPreference = "Continue"
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
        --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' `
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

# Create methods for /performance-scores
Create-Method -ResourceId $PERF_SCORES_RESOURCE -HttpMethod "GET" -Path "/performance-scores"
Create-Method -ResourceId $PERF_SCORES_RESOURCE -HttpMethod "POST" -Path "/performance-scores"
Create-Options-Method -ResourceId $PERF_SCORES_RESOURCE -Path "/performance-scores"

# Create methods for /performance-scores/{employeeId}/{period}
Create-Method -ResourceId $PERIOD_RESOURCE -HttpMethod "GET" -Path "/performance-scores/{employeeId}/{period}"
Create-Method -ResourceId $PERIOD_RESOURCE -HttpMethod "PUT" -Path "/performance-scores/{employeeId}/{period}"
Create-Method -ResourceId $PERIOD_RESOURCE -HttpMethod "DELETE" -Path "/performance-scores/{employeeId}/{period}"
Create-Options-Method -ResourceId $PERIOD_RESOURCE -Path "/performance-scores/{employeeId}/{period}"

# Grant API Gateway permission to invoke Lambda
Write-Host "`nGranting API Gateway permission to invoke Lambda..." -ForegroundColor Yellow

$ACCOUNT_ID = aws sts get-caller-identity --query 'Account' --output text
$SOURCE_ARN = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*"

aws lambda add-permission `
    --function-name $FUNCTION_NAME `
    --statement-id "apigateway-invoke-performance-scores" `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn $SOURCE_ARN `
    --region $REGION 2>$null

Write-Host "Permission granted" -ForegroundColor Green

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
Write-Host "`nAvailable endpoints:" -ForegroundColor Yellow
Write-Host "  GET    $API_ENDPOINT/performance-scores" -ForegroundColor White
Write-Host "  POST   $API_ENDPOINT/performance-scores" -ForegroundColor White
Write-Host "  GET    $API_ENDPOINT/performance-scores/{employeeId}/{period}" -ForegroundColor White
Write-Host "  PUT    $API_ENDPOINT/performance-scores/{employeeId}/{period}" -ForegroundColor White
Write-Host "  DELETE $API_ENDPOINT/performance-scores/{employeeId}/{period}" -ForegroundColor White
Write-Host "`nNext step: Test endpoints with test-endpoints.ps1" -ForegroundColor Yellow
