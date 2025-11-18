# Update API Gateway Integrations for Authentication Lambda Functions
$ErrorActionPreference = "Continue"

# Configuration
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ACCOUNT_ID = "151507815244"

# Lambda function ARNs
$LOGIN_LAMBDA_ARN = "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:insighthr-auth-login-handler"
$REGISTER_LAMBDA_ARN = "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:insighthr-auth-register-handler"
$GOOGLE_LAMBDA_ARN = "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:insighthr-auth-google-handler"

# Resource IDs
$AUTH_RESOURCE_ID = "e0ifw2"
$LOGIN_RESOURCE_ID = "9pugx2"
$REGISTER_RESOURCE_ID = "2jng12"
$GOOGLE_RESOURCE_ID = "5zzo23"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Updating API Gateway Integrations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to update integration
function Update-Integration {
    param(
        [string]$ResourceId,
        [string]$LambdaArn,
        [string]$EndpointName
    )
    
    Write-Host "Updating $EndpointName integration..." -ForegroundColor Yellow
    
    $uri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LambdaArn}/invocations"
    
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method POST `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri $uri `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Updated $EndpointName integration" -ForegroundColor Green
    } else {
        Write-Host "  Failed to update $EndpointName integration" -ForegroundColor Red
        return $false
    }
    
    # Add Lambda permission
    $statementId = "apigateway-${EndpointName}-invoke"
    aws lambda add-permission `
        --function-name $LambdaArn `
        --statement-id $statementId `
        --action lambda:InvokeFunction `
        --principal apigateway.amazonaws.com `
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Added Lambda permission for $EndpointName" -ForegroundColor Green
    } else {
        Write-Host "  (Permission already exists)" -ForegroundColor Gray
    }
    
    return $true
}

# Update existing integrations
Write-Host "Step 1: Updating existing endpoint integrations" -ForegroundColor Cyan
Write-Host ""

$loginSuccess = Update-Integration -ResourceId $LOGIN_RESOURCE_ID -LambdaArn $LOGIN_LAMBDA_ARN -EndpointName "login"
$registerSuccess = Update-Integration -ResourceId $REGISTER_RESOURCE_ID -LambdaArn $REGISTER_LAMBDA_ARN -EndpointName "register"
$googleSuccess = Update-Integration -ResourceId $GOOGLE_RESOURCE_ID -LambdaArn $GOOGLE_LAMBDA_ARN -EndpointName "google"

Write-Host ""

# Create /auth/refresh endpoint
Write-Host "Step 2: Creating /auth/refresh endpoint" -ForegroundColor Cyan
Write-Host ""

$refreshSuccess = $true

# Check if refresh resource exists
$existingResources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
$refreshResource = $existingResources.items | Where-Object { $_.path -eq "/auth/refresh" }

if ($refreshResource) {
    $REFRESH_RESOURCE_ID = $refreshResource.id
    Write-Host "  /auth/refresh resource already exists (ID: $REFRESH_RESOURCE_ID)" -ForegroundColor Green
} else {
    Write-Host "Creating /auth/refresh resource..." -ForegroundColor Yellow
    $refreshResourceResult = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $AUTH_RESOURCE_ID `
        --path-part "refresh" `
        --region $REGION | ConvertFrom-Json
    
    $REFRESH_RESOURCE_ID = $refreshResourceResult.id
    Write-Host "  Created /auth/refresh resource (ID: $REFRESH_RESOURCE_ID)" -ForegroundColor Green
}

# Create POST method
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $REFRESH_RESOURCE_ID `
    --http-method POST `
    --authorization-type NONE `
    --region $REGION 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Created POST method for /auth/refresh" -ForegroundColor Green
} else {
    Write-Host "  (POST method already exists)" -ForegroundColor Gray
}

# Create method response
aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $REFRESH_RESOURCE_ID `
    --http-method POST `
    --status-code 200 `
    --response-models "application/json=Empty" `
    --region $REGION 2>&1 | Out-Null

# Create integration
$refreshIntegrationSuccess = Update-Integration -ResourceId $REFRESH_RESOURCE_ID -LambdaArn $LOGIN_LAMBDA_ARN -EndpointName "refresh"

# Create integration response
aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $REFRESH_RESOURCE_ID `
    --http-method POST `
    --status-code 200 `
    --region $REGION 2>&1 | Out-Null

Write-Host ""

# Deploy API
Write-Host "Step 3: Deploying API to dev stage" -ForegroundColor Cyan
Write-Host ""

aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --description "Updated authentication endpoints" `
    --region $REGION 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Deployed API to dev stage" -ForegroundColor Green
} else {
    Write-Host "  Failed to deploy API" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($loginSuccess -and $registerSuccess -and $googleSuccess -and $refreshIntegrationSuccess) {
    Write-Host "All endpoints updated successfully!" -ForegroundColor Green
} else {
    Write-Host "Some endpoints failed to update" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/auth/login" -ForegroundColor White
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/auth/register" -ForegroundColor White
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/auth/google" -ForegroundColor White
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/auth/refresh" -ForegroundColor White
Write-Host ""
