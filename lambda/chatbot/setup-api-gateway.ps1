# Setup API Gateway Endpoints for Chatbot
# This script creates API Gateway resources and methods for the chatbot handler

$ErrorActionPreference = "Stop"

# Configuration from aws-secret.md
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$AUTHORIZER_ID = "ytil4t"
$CHATBOT_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-chatbot-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up API Gateway Endpoints for Chatbot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to create resource if it doesn't exist
function Get-OrCreateResource {
    param(
        [string]$ParentId,
        [string]$PathPart
    )
    
    Write-Host "Checking resource: /$PathPart" -ForegroundColor Gray
    
    # Get existing resources
    $resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
    $existing = $resources.items | Where-Object { $_.pathPart -eq $PathPart -and $_.parentId -eq $ParentId }
    
    if ($existing) {
        Write-Host "  Resource exists: $($existing.id)" -ForegroundColor Green
        return $existing.id
    }
    
    # Create new resource
    Write-Host "  Creating resource..." -ForegroundColor Yellow
    $result = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $ParentId `
        --path-part $PathPart `
        --region $REGION | ConvertFrom-Json
    
    Write-Host "  Created: $($result.id)" -ForegroundColor Green
    return $result.id
}

# Function to create method
function Create-Method {
    param(
        [string]$ResourceId,
        [string]$HttpMethod,
        [bool]$RequireAuth = $true
    )
    
    Write-Host "  Creating method: $HttpMethod" -ForegroundColor Gray
    
    # Delete if exists
    try {
        aws apigateway delete-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method $HttpMethod `
            --region $REGION 2>$null | Out-Null
    } catch {}
    
    # Create method
    if ($RequireAuth) {
        aws apigateway put-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method $HttpMethod `
            --authorization-type COGNITO_USER_POOLS `
            --authorizer-id $AUTHORIZER_ID `
            --region $REGION | Out-Null
    } else {
        aws apigateway put-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method $HttpMethod `
            --authorization-type NONE `
            --region $REGION | Out-Null
    }
}

# Function to create integration
function Create-Integration {
    param(
        [string]$ResourceId,
        [string]$HttpMethod,
        [string]$LambdaArn
    )
    
    Write-Host "  Creating integration for $HttpMethod" -ForegroundColor Gray
    
    $uri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LambdaArn}/invocations"
    
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method $HttpMethod `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri $uri `
        --region $REGION | Out-Null
}

# Function to add Lambda permission
function Add-LambdaPermission {
    param(
        [string]$FunctionName,
        [string]$StatementId,
        [string]$SourceArn
    )
    
    Write-Host "  Adding Lambda permission: $StatementId" -ForegroundColor Gray
    
    # Remove if exists
    try {
        aws lambda remove-permission `
            --function-name $FunctionName `
            --statement-id $StatementId `
            --region $REGION 2>$null | Out-Null
    } catch {}
    
    # Add permission
    aws lambda add-permission `
        --function-name $FunctionName `
        --statement-id $StatementId `
        --action lambda:InvokeFunction `
        --principal apigateway.amazonaws.com `
        --source-arn $SourceArn `
        --region $REGION | Out-Null
}

# Function to create OPTIONS method for CORS
function Create-OptionsMethod {
    param(
        [string]$ResourceId
    )
    
    Write-Host "  Creating OPTIONS method for CORS" -ForegroundColor Gray
    
    # Delete if exists
    try {
        aws apigateway delete-method `
            --rest-api-id $API_ID `
            --resource-id $ResourceId `
            --http-method OPTIONS `
            --region $REGION 2>$null | Out-Null
    } catch {}
    
    # Create OPTIONS method
    aws apigateway put-method `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --authorization-type NONE `
        --region $REGION | Out-Null
    
    # Create mock integration using temp file
    $requestTemplateJson = @{
        "application/json" = '{"statusCode": 200}'
    } | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText("$PWD\temp-request.json", $requestTemplateJson)
    
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --type MOCK `
        --request-templates file://temp-request.json `
        --region $REGION | Out-Null
    
    Remove-Item "temp-request.json" -ErrorAction SilentlyContinue
    
    # Create method response using temp file
    $methodResponseJson = @{
        "method.response.header.Access-Control-Allow-Headers" = $false
        "method.response.header.Access-Control-Allow-Methods" = $false
        "method.response.header.Access-Control-Allow-Origin" = $false
    } | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText("$PWD\temp-method-response.json", $methodResponseJson)
    
    aws apigateway put-method-response `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters file://temp-method-response.json `
        --region $REGION | Out-Null
    
    Remove-Item "temp-method-response.json" -ErrorAction SilentlyContinue
    
    # Create integration response using temp file
    $integrationResponseJson = @{
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    } | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText("$PWD\temp-integration-response.json", $integrationResponseJson)
    
    aws apigateway put-integration-response `
        --rest-api-id $API_ID `
        --resource-id $ResourceId `
        --http-method OPTIONS `
        --status-code 200 `
        --response-parameters file://temp-integration-response.json `
        --region $REGION | Out-Null
    
    Remove-Item "temp-integration-response.json" -ErrorAction SilentlyContinue
}

# Create /chatbot resource
Write-Host "Creating /chatbot resource..." -ForegroundColor Yellow
$chatbotResourceId = Get-OrCreateResource -ParentId $ROOT_RESOURCE_ID -PathPart "chatbot"

# Create /chatbot/message resource
Write-Host "Creating /chatbot/message resource..." -ForegroundColor Yellow
$chatbotMessageResourceId = Get-OrCreateResource -ParentId $chatbotResourceId -PathPart "message"

Write-Host ""
Write-Host "Creating methods and integrations..." -ForegroundColor Yellow
Write-Host ""

# POST /chatbot/message
Write-Host "Setting up POST /chatbot/message" -ForegroundColor Cyan
Create-Method -ResourceId $chatbotMessageResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $chatbotMessageResourceId -HttpMethod "POST" -LambdaArn $CHATBOT_HANDLER_ARN

# OPTIONS for /chatbot/message
Create-OptionsMethod -ResourceId $chatbotMessageResourceId

Write-Host ""
Write-Host "Adding Lambda permissions..." -ForegroundColor Yellow

# Add Lambda permission for chatbot-handler
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/chatbot/message"
Add-LambdaPermission -FunctionName "insighthr-chatbot-handler" -StatementId "apigateway-post-chatbot-message" -SourceArn $sourceArnBase

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --description "Chatbot endpoints deployment" `
    --region $REGION | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint Created:" -ForegroundColor Yellow
Write-Host "  POST /chatbot/message" -ForegroundColor White
Write-Host ""
Write-Host "Base URL: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host "Full Endpoint: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/chatbot/message" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test the endpoint with test-chatbot-endpoint.ps1" -ForegroundColor White
Write-Host "  2. Update frontend chatbotService.ts with the endpoint URL" -ForegroundColor White
Write-Host ""
