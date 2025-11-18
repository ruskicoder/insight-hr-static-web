# Deploy Authentication Lambda Functions
$ErrorActionPreference = "Stop"

$REGION = "ap-southeast-1"
$ACCOUNT_ID = "151507815244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Authentication Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to lambda/auth directory
Set-Location -Path "lambda/auth"

# Function to package and deploy Lambda
function Deploy-Lambda {
    param(
        [string]$FunctionName,
        [string]$Handler,
        [string]$PythonFile
    )
    
    Write-Host "Deploying $FunctionName..." -ForegroundColor Yellow
    
    # Create deployment package
    $zipFile = "${FunctionName}.zip"
    
    # Remove old zip if exists
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }
    
    # Create zip with just the Python file
    Compress-Archive -Path $PythonFile -DestinationPath $zipFile -Force
    
    Write-Host "  Created deployment package: $zipFile" -ForegroundColor Gray
    
    # Update Lambda function code
    aws lambda update-function-code `
        --function-name $FunctionName `
        --zip-file "fileb://$zipFile" `
        --region $REGION | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Deployed $FunctionName successfully" -ForegroundColor Green
        
        # Wait for update to complete
        Start-Sleep -Seconds 2
        
        return $true
    } else {
        Write-Host "  Failed to deploy $FunctionName" -ForegroundColor Red
        return $false
    }
}

# Deploy all three Lambda functions
$loginSuccess = Deploy-Lambda -FunctionName "insighthr-auth-login-handler" -Handler "auth_login_handler.lambda_handler" -PythonFile "auth_login_handler.py"
$registerSuccess = Deploy-Lambda -FunctionName "insighthr-auth-register-handler" -Handler "auth_register_handler.lambda_handler" -PythonFile "auth_register_handler.py"
$googleSuccess = Deploy-Lambda -FunctionName "insighthr-auth-google-handler" -Handler "auth_google_handler.lambda_handler" -PythonFile "auth_google_handler.py"

# Return to root directory
Set-Location -Path "../.."

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($loginSuccess -and $registerSuccess -and $googleSuccess) {
    Write-Host "All Lambda functions deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "Some Lambda functions failed to deploy:" -ForegroundColor Yellow
    if (-not $loginSuccess) { Write-Host "  - auth-login-handler failed" -ForegroundColor Red }
    if (-not $registerSuccess) { Write-Host "  - auth-register-handler failed" -ForegroundColor Red }
    if (-not $googleSuccess) { Write-Host "  - auth-google-handler failed" -ForegroundColor Red }
}

Write-Host ""
Write-Host "Lambda Functions:" -ForegroundColor Cyan
Write-Host "  insighthr-auth-login-handler" -ForegroundColor White
Write-Host "  insighthr-auth-register-handler" -ForegroundColor White
Write-Host "  insighthr-auth-google-handler" -ForegroundColor White
Write-Host ""
