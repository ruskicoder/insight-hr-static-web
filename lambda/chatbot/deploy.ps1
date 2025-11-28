# Deploy Chatbot Handler Lambda Function
# This script packages and deploys the chatbot-handler Lambda function to AWS

$ErrorActionPreference = "Stop"

# Configuration
$REGION = "ap-southeast-1"
$FUNCTION_NAME = "insighthr-chatbot-handler"
$LAMBDA_ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"
$BEDROCK_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"
$BEDROCK_REGION = "ap-southeast-1"
$EMPLOYEES_TABLE = "insighthr-employees-dev"
$PERFORMANCE_SCORES_TABLE = "insighthr-performance-scores-dev"
$USERS_TABLE = "insighthr-users-dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Chatbot Handler Lambda" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Processing $FUNCTION_NAME..." -ForegroundColor Yellow

# Create deployment package directory
$packageDir = "package_$FUNCTION_NAME"
if (Test-Path $packageDir) {
    Remove-Item -Recurse -Force $packageDir
}
New-Item -ItemType Directory -Path $packageDir | Out-Null

# Copy handler file
Copy-Item "chatbot_handler.py" $packageDir/

# Create ZIP file
$zipFile = "$FUNCTION_NAME.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile
}

Write-Host "  Creating deployment package..." -ForegroundColor Gray
Push-Location $packageDir
Compress-Archive -Path * -DestinationPath "../$zipFile"
Pop-Location

# Check if Lambda function exists
Write-Host "  Checking if Lambda function exists..." -ForegroundColor Gray
$functionExists = $false
try {
    aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>$null | Out-Null
    $functionExists = $true
} catch {
    $functionExists = $false
}

if ($functionExists) {
    # Update existing function
    Write-Host "  Updating existing Lambda function..." -ForegroundColor Green
    aws lambda update-function-code `
        --function-name $FUNCTION_NAME `
        --zip-file "fileb://$zipFile" `
        --region $REGION | Out-Null
    
    # Update environment variables
    aws lambda update-function-configuration `
        --function-name $FUNCTION_NAME `
        --timeout 60 `
        --memory-size 512 `
        --environment "Variables={BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID,BEDROCK_REGION=$BEDROCK_REGION,EMPLOYEES_TABLE=$EMPLOYEES_TABLE,PERFORMANCE_SCORES_TABLE=$PERFORMANCE_SCORES_TABLE,USERS_TABLE=$USERS_TABLE}" `
        --region $REGION | Out-Null
} else {
    # Create new function
    Write-Host "  Creating new Lambda function..." -ForegroundColor Green
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime python3.11 `
        --role $LAMBDA_ROLE_ARN `
        --handler "chatbot_handler.lambda_handler" `
        --zip-file "fileb://$zipFile" `
        --timeout 60 `
        --memory-size 512 `
        --description "Handle chatbot queries with AWS Bedrock integration" `
        --environment "Variables={BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID,BEDROCK_REGION=$BEDROCK_REGION,EMPLOYEES_TABLE=$EMPLOYEES_TABLE,PERFORMANCE_SCORES_TABLE=$PERFORMANCE_SCORES_TABLE,USERS_TABLE=$USERS_TABLE}" `
        --region $REGION | Out-Null
}

# Clean up
Remove-Item -Recurse -Force $packageDir

Write-Host "  Success: $FUNCTION_NAME deployed" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lambda Function Deployed:" -ForegroundColor Yellow
Write-Host "  - $FUNCTION_NAME" -ForegroundColor White
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Bedrock Model: $BEDROCK_MODEL_ID" -ForegroundColor White
Write-Host "  Timeout: 60 seconds" -ForegroundColor White
Write-Host "  Memory: 512 MB" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run setup-api-gateway.ps1 to create API endpoints" -ForegroundColor White
Write-Host "  2. Test the chatbot with test-chatbot-endpoint.ps1" -ForegroundColor White
Write-Host ""
