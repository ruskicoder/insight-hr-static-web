# Deploy Employee Management Lambda Functions
# This script packages and deploys the employee management Lambda functions to AWS

$ErrorActionPreference = "Stop"

# Configuration
$REGION = "ap-southeast-1"
$EMPLOYEES_TABLE = "insighthr-employees-dev"
$USERS_TABLE = "insighthr-users-dev"
$LAMBDA_ROLE_ARN = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Employee Management Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to package and deploy a Lambda function
function Deploy-Lambda {
    param(
        [string]$FunctionName,
        [string]$Handler,
        [string]$Description
    )
    
    Write-Host "Processing $FunctionName..." -ForegroundColor Yellow
    
    # Create deployment package directory
    $packageDir = "package_$FunctionName"
    if (Test-Path $packageDir) {
        Remove-Item -Recurse -Force $packageDir
    }
    New-Item -ItemType Directory -Path $packageDir | Out-Null
    
    # Copy handler file
    $handlerFile = "$Handler.py"
    Copy-Item $handlerFile $packageDir/
    
    # Create ZIP file
    $zipFile = "$FunctionName.zip"
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
        aws lambda get-function --function-name $FunctionName --region $REGION 2>$null | Out-Null
        $functionExists = $true
    } catch {
        $functionExists = $false
    }
    
    if ($functionExists) {
        # Update existing function
        Write-Host "  Updating existing Lambda function..." -ForegroundColor Green
        aws lambda update-function-code `
            --function-name $FunctionName `
            --zip-file "fileb://$zipFile" `
            --region $REGION | Out-Null
        
        # Update environment variables
        aws lambda update-function-configuration `
            --function-name $FunctionName `
            --environment "Variables={EMPLOYEES_TABLE=$EMPLOYEES_TABLE,USERS_TABLE=$USERS_TABLE}" `
            --region $REGION | Out-Null
    } else {
        # Create new function
        Write-Host "  Creating new Lambda function..." -ForegroundColor Green
        aws lambda create-function `
            --function-name $FunctionName `
            --runtime python3.11 `
            --role $LAMBDA_ROLE_ARN `
            --handler "$Handler.lambda_handler" `
            --zip-file "fileb://$zipFile" `
            --timeout 30 `
            --memory-size 256 `
            --description "$Description" `
            --environment "Variables={EMPLOYEES_TABLE=$EMPLOYEES_TABLE,USERS_TABLE=$USERS_TABLE}" `
            --region $REGION | Out-Null
    }
    
    # Clean up
    Remove-Item -Recurse -Force $packageDir
    
    Write-Host "  Success: $FunctionName deployed" -ForegroundColor Green
    Write-Host ""
}

# Deploy employees-handler Lambda
Deploy-Lambda -FunctionName "insighthr-employees-handler" -Handler "employees_handler" -Description "Handle employee management operations"

# Deploy employees-bulk-handler Lambda
Deploy-Lambda -FunctionName "insighthr-employees-bulk-handler" -Handler "employees_bulk_handler" -Description "Handle bulk employee import"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lambda Functions Deployed:" -ForegroundColor Yellow
Write-Host "  - insighthr-employees-handler" -ForegroundColor White
Write-Host "  - insighthr-employees-bulk-handler" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Create API Gateway endpoints" -ForegroundColor White
Write-Host "  2. Test the endpoints" -ForegroundColor White
Write-Host ""
