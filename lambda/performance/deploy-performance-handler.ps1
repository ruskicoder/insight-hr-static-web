# Deploy Performance Handler Lambda
$ErrorActionPreference = "Stop"

Write-Host "=== Deploying Performance Handler Lambda ===" -ForegroundColor Cyan

# Configuration
$REGION = "ap-southeast-1"
$FUNCTION_NAME = "insighthr-performance-handler"
$HANDLER = "performance_handler.lambda_handler"
$RUNTIME = "python3.11"
$ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"

# Step 1: Package Lambda function
Write-Host "`nPackaging Lambda function..." -ForegroundColor Yellow
if (Test-Path "performance_handler.zip") {
    Remove-Item "performance_handler.zip" -Force
}
Compress-Archive -Path "performance_handler.py" -DestinationPath "performance_handler.zip" -Force
Write-Host "Packaged successfully" -ForegroundColor Green

# Step 2: Check if function exists
Write-Host "`nChecking if Lambda exists..." -ForegroundColor Yellow
$checkResult = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>&1
$functionExists = $LASTEXITCODE -eq 0

if ($functionExists) {
    Write-Host "Function exists - updating..." -ForegroundColor Green
    aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file fileb://performance_handler.zip --region $REGION
    Start-Sleep -Seconds 2
    aws lambda update-function-configuration --function-name $FUNCTION_NAME --environment "Variables={PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev,EMPLOYEES_TABLE=insighthr-employees-dev,AUTO_SCORING_LAMBDA_ARN=,AWS_REGION=ap-southeast-1}" --region $REGION
}
else {
    Write-Host "Function does not exist - creating..." -ForegroundColor Green
    aws lambda create-function --function-name $FUNCTION_NAME --runtime $RUNTIME --role $ROLE_ARN --handler $HANDLER --zip-file fileb://performance_handler.zip --timeout 30 --memory-size 256 --environment "Variables={PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev,EMPLOYEES_TABLE=insighthr-employees-dev,AUTO_SCORING_LAMBDA_ARN=,AWS_REGION=ap-southeast-1}" --region $REGION
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Lambda deployed successfully" -ForegroundColor Green
}
else {
    Write-Host "Deployment failed" -ForegroundColor Red
    exit 1
}

# Get Lambda ARN
$lambdaArn = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query "Configuration.FunctionArn" --output text
Write-Host "`nLambda ARN: $lambdaArn" -ForegroundColor Cyan

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Cyan
