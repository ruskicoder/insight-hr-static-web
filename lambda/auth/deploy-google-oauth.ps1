# Deploy Google OAuth Lambda Function with Dependencies
# This script packages the Lambda function with all required dependencies

$ErrorActionPreference = "Stop"

# AWS Configuration
$REGION = "ap-southeast-1"
$USER_POOL_ID = "ap-southeast-1_rzDtdAhvp"
$CLIENT_ID = "6suhk5huhe40o6iuqgsnmuucj5"
$USERS_TABLE = "insighthr-users-dev"
$LAMBDA_ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"
$FUNCTION_NAME = "insighthr-auth-google-handler"

# Google Client ID from OAuth credentials
$GOOGLE_CLIENT_ID = "1060366197564-54s6rdurv4s13v5sm40ravlg6s487v2t.apps.googleusercontent.com"

Write-Host "=== Google OAuth Lambda Deployment ===" -ForegroundColor Green
Write-Host "Region: $REGION" -ForegroundColor Cyan
Write-Host "Function: $FUNCTION_NAME" -ForegroundColor Cyan
Write-Host ""

# Google Client ID configured
Write-Host "Google Client ID: $GOOGLE_CLIENT_ID" -ForegroundColor Cyan

# Create temp directory for packaging
$tempDir = "temp_google_package"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "Installing Python dependencies..." -ForegroundColor Yellow

# Install dependencies to temp directory
pip install -r requirements.txt -t $tempDir --upgrade

# Copy Lambda handler
Copy-Item "auth_google_handler.py" "$tempDir\lambda_function.py"

Write-Host "Creating deployment package..." -ForegroundColor Yellow

# Create zip file
$zipFile = "$FUNCTION_NAME.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile
}

# Change to temp directory and create zip
Push-Location $tempDir
Compress-Archive -Path "*" -DestinationPath "..\$zipFile" -Force
Pop-Location

# Clean up temp directory
Remove-Item -Recurse -Force $tempDir

Write-Host "Package created: $zipFile" -ForegroundColor Green
Write-Host "Package size: $((Get-Item $zipFile).Length / 1MB) MB" -ForegroundColor Cyan
Write-Host ""

# Check if function exists
Write-Host "Checking if Lambda function exists..." -ForegroundColor Yellow
$functionExists = $false
try {
    aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $functionExists = $true
    }
} catch {
    $functionExists = $false
}

if ($functionExists) {
    Write-Host "Updating existing function..." -ForegroundColor Yellow
    
    # Update function code
    aws lambda update-function-code `
        --function-name $FUNCTION_NAME `
        --zip-file "fileb://$zipFile" `
        --region $REGION
        
    # Wait for update to complete
    Write-Host "Waiting for function update to complete..." -ForegroundColor Yellow
    aws lambda wait function-updated --function-name $FUNCTION_NAME --region $REGION
    
    # Update environment variables
    Write-Host "Updating environment variables..." -ForegroundColor Yellow
    aws lambda update-function-configuration `
        --function-name $FUNCTION_NAME `
        --environment "Variables={USER_POOL_ID=$USER_POOL_ID,CLIENT_ID=$CLIENT_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE,GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID}" `
        --region $REGION
        
    Write-Host "Function updated successfully!" -ForegroundColor Green
} else {
    Write-Host "Creating new function..." -ForegroundColor Yellow
    
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime python3.11 `
        --role $LAMBDA_ROLE_ARN `
        --handler lambda_function.lambda_handler `
        --zip-file "fileb://$zipFile" `
        --description "Handle Google OAuth authentication with token verification" `
        --timeout 30 `
        --memory-size 512 `
        --environment "Variables={USER_POOL_ID=$USER_POOL_ID,CLIENT_ID=$CLIENT_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE,GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID}" `
        --region $REGION
        
    Write-Host "Function created successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test the Lambda function with a real Google token"
Write-Host "2. Update your frontend .env file with VITE_GOOGLE_CLIENT_ID"
Write-Host "3. Configure authorized origins in Google Cloud Console:"
Write-Host "   - http://localhost:5173"
Write-Host "   - https://d2z6tht6rq32uy.cloudfront.net"
Write-Host ""

