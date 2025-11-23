# Deploy KPI Management Lambda Function
$ErrorActionPreference = "Stop"

$FUNCTION_NAME = "insighthr-kpis-handler"
$REGION = "ap-southeast-1"
$ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"

Write-Host "=== Deploying KPI Management Lambda ===" -ForegroundColor Cyan

# Package Lambda function
Write-Host "Packaging Lambda function..." -ForegroundColor Yellow
if (Test-Path "kpis_handler.zip") {
    Remove-Item "kpis_handler.zip"
}
Compress-Archive -Path "kpis_handler.py" -DestinationPath "kpis_handler.zip" -Force
Write-Host "Lambda function packaged" -ForegroundColor Green

# Check if Lambda function exists
Write-Host "Checking if Lambda function exists..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
$checkResult = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>&1
$ErrorActionPreference = "Stop"
$functionExists = $LASTEXITCODE -eq 0

if ($functionExists) {
    Write-Host "Lambda function exists, updating..." -ForegroundColor Yellow
    # Update existing function
    Write-Host "Updating existing Lambda function..." -ForegroundColor Yellow
    aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file fileb://kpis_handler.zip --region $REGION
    
    Write-Host "Updating environment variables..." -ForegroundColor Yellow
    aws lambda update-function-configuration --function-name $FUNCTION_NAME --environment file://env-vars.json --region $REGION
    
    Write-Host "Lambda function updated" -ForegroundColor Green
} else {
    # Create new function
    Write-Host "Creating new Lambda function..." -ForegroundColor Yellow
    aws lambda create-function --function-name $FUNCTION_NAME --runtime python3.11 --role $ROLE_ARN --handler kpis_handler.lambda_handler --zip-file fileb://kpis_handler.zip --timeout 30 --memory-size 256 --environment file://env-vars.json --region $REGION
    
    Write-Host "Lambda function created" -ForegroundColor Green
}

# Get Lambda ARN
Write-Host "Getting Lambda ARN..." -ForegroundColor Yellow
$lambdaArn = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text
Write-Host "Lambda ARN: $lambdaArn" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== KPI Lambda Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps: Run setup-api-gateway.ps1 to create API Gateway endpoints" -ForegroundColor Yellow
