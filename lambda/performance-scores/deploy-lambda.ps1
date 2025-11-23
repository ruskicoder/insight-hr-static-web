# Deploy Performance Scores Lambda Handler
# This script packages and deploys the performance-scores-handler Lambda function

$ErrorActionPreference = "Stop"

Write-Host "=== Deploying Performance Scores Lambda Handler ===" -ForegroundColor Cyan

# Configuration
$FUNCTION_NAME = "insighthr-performance-scores-handler"
$REGION = "ap-southeast-1"
$RUNTIME = "python3.11"
$HANDLER = "performance_scores_handler.lambda_handler"
$ROLE_NAME = "insighthr-lambda-execution-role-dev"
$ZIP_FILE = "performance_scores_handler.zip"

# Get IAM role ARN
Write-Host "`nGetting IAM role ARN..." -ForegroundColor Yellow
$ROLE_ARN = aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get IAM role ARN" -ForegroundColor Red
    exit 1
}

Write-Host "Role ARN: $ROLE_ARN" -ForegroundColor Green

# Package Lambda function
Write-Host "`nPackaging Lambda function..." -ForegroundColor Yellow

# Remove old zip if exists
if (Test-Path $ZIP_FILE) {
    Remove-Item $ZIP_FILE
}

# Create zip file with Lambda handler
Compress-Archive -Path performance_scores_handler.py -DestinationPath $ZIP_FILE

Write-Host "Lambda function packaged: $ZIP_FILE" -ForegroundColor Green

# Check if Lambda function exists
Write-Host "`nChecking if Lambda function exists..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$FUNCTION_EXISTS = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>&1
$FUNCTION_EXISTS_CODE = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($FUNCTION_EXISTS_CODE -eq 0) {
    # Update existing function
    Write-Host "Lambda function exists. Updating..." -ForegroundColor Yellow
    
    aws lambda update-function-code `
        --function-name $FUNCTION_NAME `
        --zip-file fileb://$ZIP_FILE `
        --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to update Lambda function code" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Lambda function code updated successfully" -ForegroundColor Green
    
    # Update environment variables
    Write-Host "`nUpdating environment variables..." -ForegroundColor Yellow
    
    aws lambda update-function-configuration `
        --function-name $FUNCTION_NAME `
        --environment "Variables={PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev,EMPLOYEES_TABLE=insighthr-employees-dev,USERS_TABLE=insighthr-users-dev}" `
        --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to update Lambda configuration" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Lambda configuration updated successfully" -ForegroundColor Green
} else {
    # Create new function
    Write-Host "Lambda function does not exist. Creating..." -ForegroundColor Yellow
    
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime $RUNTIME `
        --role $ROLE_ARN `
        --handler $HANDLER `
        --zip-file fileb://$ZIP_FILE `
        --timeout 30 `
        --memory-size 256 `
        --environment "Variables={PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev,EMPLOYEES_TABLE=insighthr-employees-dev,USERS_TABLE=insighthr-users-dev}" `
        --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to create Lambda function" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Lambda function created successfully" -ForegroundColor Green
}

# Get Lambda ARN
Write-Host "`nGetting Lambda ARN..." -ForegroundColor Yellow
$LAMBDA_ARN = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text

Write-Host "Lambda ARN: $LAMBDA_ARN" -ForegroundColor Green

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host "Function Name: $FUNCTION_NAME" -ForegroundColor Green
Write-Host "Lambda ARN: $LAMBDA_ARN" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run setup-api-gateway.ps1 to create API Gateway endpoints" -ForegroundColor White
Write-Host "2. Test endpoints with test-endpoints.ps1" -ForegroundColor White
