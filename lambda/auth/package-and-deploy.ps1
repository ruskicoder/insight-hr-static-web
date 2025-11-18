# Package and Deploy Authentication Lambda Functions
# This script creates deployment packages and deploys Lambda functions to AWS

$ErrorActionPreference = "Stop"

# AWS Configuration
$REGION = "ap-southeast-1"
$USER_POOL_ID = "ap-southeast-1_rzDtdAhvp"
$CLIENT_ID = "6suhk5huhe40o6iuqgsnmuucj5"
$USERS_TABLE = "insighthr-users-dev"
$LAMBDA_ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"

Write-Host "=== Authentication Lambda Deployment ===" -ForegroundColor Green
Write-Host "Region: $REGION" -ForegroundColor Cyan
Write-Host ""

# Function to package and deploy Lambda
function Deploy-AuthLambda {
    param(
        [string]$FunctionName,
        [string]$HandlerFile,
        [string]$Description
    )
    
    Write-Host "Processing $FunctionName..." -ForegroundColor Cyan
    
    # Create temp directory
    $tempDir = "temp_package"
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Copy handler file as lambda_function.py
    Copy-Item "$HandlerFile.py" "$tempDir\lambda_function.py"
    
    # Create zip file
    $zipFile = "$FunctionName.zip"
    if (Test-Path $zipFile) {
        Remove-Item $zipFile
    }
    
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFile -Force
    Remove-Item -Recurse -Force $tempDir
    
    Write-Host "  Package created: $zipFile" -ForegroundColor Yellow
    
    # Check if function exists
    $functionExists = $false
    try {
        aws lambda get-function --function-name $FunctionName --region $REGION 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $functionExists = $true
        }
    } catch {
        $functionExists = $false
    }
    
    if ($functionExists) {
        Write-Host "  Updating existing function..." -ForegroundColor Yellow
        
        aws lambda update-function-code `
            --function-name $FunctionName `
            --zip-file "fileb://$zipFile" `
            --region $REGION | Out-Null
            
        aws lambda update-function-configuration `
            --function-name $FunctionName `
            --environment "Variables={USER_POOL_ID=$USER_POOL_ID,CLIENT_ID=$CLIENT_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE}" `
            --region $REGION | Out-Null
            
        Write-Host "  Function updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "  Creating new function..." -ForegroundColor Yellow
        
        aws lambda create-function `
            --function-name $FunctionName `
            --runtime python3.11 `
            --role $LAMBDA_ROLE_ARN `
            --handler lambda_function.lambda_handler `
            --zip-file "fileb://$zipFile" `
            --description $Description `
            --timeout 30 `
            --memory-size 256 `
            --environment "Variables={USER_POOL_ID=$USER_POOL_ID,CLIENT_ID=$CLIENT_ID,DYNAMODB_USERS_TABLE=$USERS_TABLE}" `
            --region $REGION | Out-Null
            
        Write-Host "  Function created successfully!" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Deploy all Lambda functions
Deploy-AuthLambda -FunctionName "insighthr-auth-login-handler" -HandlerFile "auth_login_handler" -Description "Handle user login with Cognito"
Deploy-AuthLambda -FunctionName "insighthr-auth-register-handler" -HandlerFile "auth_register_handler" -Description "Handle user registration with Cognito and DynamoDB"
Deploy-AuthLambda -FunctionName "insighthr-auth-google-handler" -HandlerFile "auth_google_handler" -Description "Handle Google OAuth authentication"

Write-Host "=== All Lambda functions deployed successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run setup-api-gateway.ps1 to create API Gateway endpoints"
Write-Host "2. Test the endpoints with Postman or curl"
Write-Host ""
