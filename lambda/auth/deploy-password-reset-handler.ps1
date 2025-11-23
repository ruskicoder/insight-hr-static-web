# Deploy password-reset-handler Lambda function
# Run this script from the lambda/auth directory

$FUNCTION_NAME = "insighthr-password-reset-handler"
$REGION = "ap-southeast-1"
$RUNTIME = "python3.11"
$HANDLER = "password_reset_handler.lambda_handler"
$ROLE_NAME = "insighthr-lambda-execution-role-dev"

Write-Host "Deploying password-reset-handler Lambda..." -ForegroundColor Cyan

# Get IAM role ARN
Write-Host "Getting IAM role ARN..." -ForegroundColor Cyan
$ROLE_ARN = aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text

if (-not $ROLE_ARN) {
    Write-Host "Error: IAM role $ROLE_NAME not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Using IAM role: $ROLE_ARN" -ForegroundColor Green

# Get environment variables from aws-secret.md
$USER_POOL_ID = (Select-String -Path "../../aws-secret.md" -Pattern "COGNITO_USER_POOL_ID=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
$USERS_TABLE = (Select-String -Path "../../aws-secret.md" -Pattern "DYNAMODB_USERS_TABLE=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })

if (-not $USERS_TABLE) {
    # Try alternative pattern
    $USERS_TABLE = "Users"
}

if (-not $USER_POOL_ID -or -not $USERS_TABLE) {
    Write-Host "Error: Could not find USER_POOL_ID or DYNAMODB_USERS_TABLE in aws-secret.md!" -ForegroundColor Red
    exit 1
}

Write-Host "USER_POOL_ID: $USER_POOL_ID" -ForegroundColor Green
Write-Host "USERS_TABLE: $USERS_TABLE" -ForegroundColor Green

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Cyan
if (Test-Path "password-reset-handler.zip") {
    Remove-Item "password-reset-handler.zip"
}

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Cyan
pip install PyJWT -t ./package 2>$null

# Create zip file
Compress-Archive -Path password_reset_handler.py -DestinationPath password-reset-handler.zip -Force
if (Test-Path "./package") {
    Compress-Archive -Path ./package/* -DestinationPath password-reset-handler.zip -Update
    Remove-Item -Recurse -Force ./package
}

Write-Host "Deployment package created!" -ForegroundColor Green

# Check if function exists
$functionExists = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>$null

if ($functionExists) {
    Write-Host "Function exists, updating code..." -ForegroundColor Yellow
    
    aws lambda update-function-code `
        --function-name $FUNCTION_NAME `
        --zip-file fileb://password-reset-handler.zip `
        --region $REGION
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Function code updated!" -ForegroundColor Green
        
        # Update environment variables
        Write-Host "Updating environment variables..." -ForegroundColor Cyan
        aws lambda update-function-configuration `
            --function-name $FUNCTION_NAME `
            --environment "Variables={USER_POOL_ID=$USER_POOL_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE,PASSWORD_RESET_REQUESTS_TABLE=PasswordResetRequests}" `
            --region $REGION
        
        Write-Host "Environment variables updated!" -ForegroundColor Green
    } else {
        Write-Host "Failed to update function code!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Creating new function..." -ForegroundColor Yellow
    
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime $RUNTIME `
        --role $ROLE_ARN `
        --handler $HANDLER `
        --zip-file fileb://password-reset-handler.zip `
        --timeout 30 `
        --memory-size 256 `
        --environment "Variables={USER_POOL_ID=$USER_POOL_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE,PASSWORD_RESET_REQUESTS_TABLE=PasswordResetRequests}" `
        --region $REGION
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Function created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create function!" -ForegroundColor Red
        exit 1
    }
}

# Get function ARN
$FUNCTION_ARN = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "Function ARN: $FUNCTION_ARN" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Create API Gateway endpoints for:" -ForegroundColor Yellow
Write-Host "   - POST /auth/request-reset (public)" -ForegroundColor Yellow
Write-Host "   - GET /users/password-requests (admin only)" -ForegroundColor Yellow
Write-Host "   - POST /users/{userId}/approve-reset (admin only)" -ForegroundColor Yellow
Write-Host "2. Update aws-secret.md with the function ARN" -ForegroundColor Yellow
