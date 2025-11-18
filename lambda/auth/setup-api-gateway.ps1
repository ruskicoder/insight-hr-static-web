# Setup API Gateway endpoints for authentication Lambda functions
$ErrorActionPreference = "Stop"

$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$ACCOUNT_ID = "151507815244"

Write-Host "=== API Gateway Setup for Authentication ===" -ForegroundColor Green
Write-Host "API ID: $API_ID" -ForegroundColor Cyan
Write-Host "Region: $REGION" -ForegroundColor Cyan
Write-Host ""

# Create /auth resource if it doesn't exist
Write-Host "Checking /auth resource..." -ForegroundColor Cyan
$authResourceResult = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/auth'].id" --output text

if ([string]::IsNullOrWhiteSpace($authResourceResult)) {
    Write-Host "  Creating /auth resource..." -ForegroundColor Yellow
    $authResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part auth --region $REGION | ConvertFrom-Json
    $AUTH_RESOURCE_ID = $authResource.id
    Write-Host "  Created with ID: $AUTH_RESOURCE_ID" -ForegroundColor Green
} else {
    Write-Host "  /auth resource exists with ID: $authResourceResult" -ForegroundColor Green
    $AUTH_RESOURCE_ID = $authResourceResult
}

Write-Host ""

# Function to create endpoint
function Setup-AuthEndpoint {
    param(
        [string]$PathPart,
        [string]$LambdaFunctionName
    )
    
    Write-Host "Setting up /auth/$PathPart..." -ForegroundColor Cyan
    
    # Check if resource exists
    $resourceResult = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/auth/$PathPart'].id" --output text
    
    if ([string]::IsNullOrWhiteSpace($resourceResult)) {
        Write-Host "  Creating resource..." -ForegroundColor Yellow
        $resource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $AUTH_RESOURCE_ID --path-part $PathPart --region $REGION | ConvertFrom-Json
        $RESOURCE_ID = $resource.id
    } else {
        Write-Host "  Resource exists" -ForegroundColor Yellow
        $RESOURCE_ID = $resourceResult
    }
    
    # Create POST method
    Write-Host "  Creating POST method..." -ForegroundColor Yellow
    try {
        aws apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --authorization-type NONE --region $REGION 2>&1 | Out-Null
    } catch {
        # Method already exists
    }
    
    # Enable CORS for POST
    Write-Host "  Enabling CORS..." -ForegroundColor Yellow
    try {
        aws apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --authorization-type NONE --region $REGION 2>&1 | Out-Null
        
        aws apigateway put-integration --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --type MOCK --request-templates '{"application/json":"{\"statusCode\":200}"}' --region $REGION 2>&1 | Out-Null
        
        aws apigateway put-method-response --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region $REGION 2>&1 | Out-Null
        
        aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' --region $REGION 2>&1 | Out-Null
    } catch {
        # CORS already configured
    }
    
    # Set up Lambda integration
    Write-Host "  Setting up Lambda integration..." -ForegroundColor Yellow
    $lambdaUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LambdaFunctionName}/invocations"
    
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region $REGION 2>&1 | Out-Null
    
    # Grant API Gateway permission to invoke Lambda
    Write-Host "  Granting Lambda invoke permission..." -ForegroundColor Yellow
    $sourceArn = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/auth/${PathPart}"
    
    try {
        aws lambda add-permission --function-name $LambdaFunctionName --statement-id "apigateway-${PathPart}-invoke" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn $sourceArn --region $REGION 2>&1 | Out-Null
    } catch {
        # Permission already exists
    }
    
    Write-Host "  Endpoint configured successfully!" -ForegroundColor Green
    Write-Host ""
}

# Create endpoints
Setup-AuthEndpoint -PathPart "login" -LambdaFunctionName "insighthr-auth-login-handler"
Setup-AuthEndpoint -PathPart "register" -LambdaFunctionName "insighthr-auth-register-handler"
Setup-AuthEndpoint -PathPart "google" -LambdaFunctionName "insighthr-auth-google-handler"

# Deploy API
Write-Host "Deploying API to dev stage..." -ForegroundColor Cyan
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION | Out-Null
Write-Host "  Deployment complete!" -ForegroundColor Green
Write-Host ""

Write-Host "=== API Gateway setup complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  POST https://$API_ID.execute-api.$REGION.amazonaws.com/dev/auth/login"
Write-Host "  POST https://$API_ID.execute-api.$REGION.amazonaws.com/dev/auth/register"
Write-Host "  POST https://$API_ID.execute-api.$REGION.amazonaws.com/dev/auth/google"
Write-Host ""
