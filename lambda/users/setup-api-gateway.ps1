# Setup API Gateway Endpoints for User Management
# This script creates API Gateway resources and methods for user management endpoints

$ErrorActionPreference = "Stop"

# Configuration from aws-secret.md
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$AUTHORIZER_ID = "ytil4t"
$USERS_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-users-handler"
$USERS_BULK_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-users-bulk-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up API Gateway Endpoints" -ForegroundColor Cyan
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
        "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
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

# Create /users resource
Write-Host "Creating /users resource..." -ForegroundColor Yellow
$usersResourceId = Get-OrCreateResource -ParentId $ROOT_RESOURCE_ID -PathPart "users"

# Create /users/me resource
Write-Host "Creating /users/me resource..." -ForegroundColor Yellow
$usersMeResourceId = Get-OrCreateResource -ParentId $usersResourceId -PathPart "me"

# Create /users/{userId} resource
Write-Host "Creating /users/{userId} resource..." -ForegroundColor Yellow
$usersUserIdResourceId = Get-OrCreateResource -ParentId $usersResourceId -PathPart "{userId}"

# Create /users/{userId}/disable resource
Write-Host "Creating /users/{userId}/disable resource..." -ForegroundColor Yellow
$usersDisableResourceId = Get-OrCreateResource -ParentId $usersUserIdResourceId -PathPart "disable"

# Create /users/{userId}/enable resource
Write-Host "Creating /users/{userId}/enable resource..." -ForegroundColor Yellow
$usersEnableResourceId = Get-OrCreateResource -ParentId $usersUserIdResourceId -PathPart "enable"

# Create /users/bulk resource
Write-Host "Creating /users/bulk resource..." -ForegroundColor Yellow
$usersBulkResourceId = Get-OrCreateResource -ParentId $usersResourceId -PathPart "bulk"

Write-Host ""
Write-Host "Creating methods and integrations..." -ForegroundColor Yellow
Write-Host ""

# GET /users/me
Write-Host "Setting up GET /users/me" -ForegroundColor Cyan
Create-Method -ResourceId $usersMeResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $usersMeResourceId -HttpMethod "GET" -LambdaArn $USERS_HANDLER_ARN
Create-OptionsMethod -ResourceId $usersMeResourceId

# PUT /users/me
Write-Host "Setting up PUT /users/me" -ForegroundColor Cyan
Create-Method -ResourceId $usersMeResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $usersMeResourceId -HttpMethod "PUT" -LambdaArn $USERS_HANDLER_ARN

# Note: OPTIONS for /users/me already created above

# GET /users
Write-Host "Setting up GET /users" -ForegroundColor Cyan
Create-Method -ResourceId $usersResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $usersResourceId -HttpMethod "GET" -LambdaArn $USERS_HANDLER_ARN

# POST /users
Write-Host "Setting up POST /users" -ForegroundColor Cyan
Create-Method -ResourceId $usersResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $usersResourceId -HttpMethod "POST" -LambdaArn $USERS_HANDLER_ARN

# OPTIONS for /users (shared by GET and POST)
Create-OptionsMethod -ResourceId $usersResourceId

# PUT /users/{userId}
Write-Host "Setting up PUT /users/{userId}" -ForegroundColor Cyan
Create-Method -ResourceId $usersUserIdResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $usersUserIdResourceId -HttpMethod "PUT" -LambdaArn $USERS_HANDLER_ARN

# DELETE /users/{userId}
Write-Host "Setting up DELETE /users/{userId}" -ForegroundColor Cyan
Create-Method -ResourceId $usersUserIdResourceId -HttpMethod "DELETE" -RequireAuth $true
Create-Integration -ResourceId $usersUserIdResourceId -HttpMethod "DELETE" -LambdaArn $USERS_HANDLER_ARN

# OPTIONS for /users/{userId} (shared by PUT and DELETE)
Create-OptionsMethod -ResourceId $usersUserIdResourceId

# PUT /users/{userId}/disable
Write-Host "Setting up PUT /users/{userId}/disable" -ForegroundColor Cyan
Create-Method -ResourceId $usersDisableResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $usersDisableResourceId -HttpMethod "PUT" -LambdaArn $USERS_HANDLER_ARN
Create-OptionsMethod -ResourceId $usersDisableResourceId

# PUT /users/{userId}/enable
Write-Host "Setting up PUT /users/{userId}/enable" -ForegroundColor Cyan
Create-Method -ResourceId $usersEnableResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $usersEnableResourceId -HttpMethod "PUT" -LambdaArn $USERS_HANDLER_ARN
Create-OptionsMethod -ResourceId $usersEnableResourceId

# POST /users/bulk
Write-Host "Setting up POST /users/bulk" -ForegroundColor Cyan
Create-Method -ResourceId $usersBulkResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $usersBulkResourceId -HttpMethod "POST" -LambdaArn $USERS_BULK_HANDLER_ARN
Create-OptionsMethod -ResourceId $usersBulkResourceId

Write-Host ""
Write-Host "Adding Lambda permissions..." -ForegroundColor Yellow

# Add Lambda permissions for users-handler
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/users/me"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-get-users-me" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/users/me"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-put-users-me" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/users"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-get-users" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/users"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-post-users" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/users/*"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-put-users-id" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/DELETE/users/*"
Add-LambdaPermission -FunctionName "insighthr-users-handler" -StatementId "apigateway-delete-users-id" -SourceArn $sourceArnBase

# Add Lambda permission for users-bulk-handler
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/users/bulk"
Add-LambdaPermission -FunctionName "insighthr-users-bulk-handler" -StatementId "apigateway-post-users-bulk" -SourceArn $sourceArnBase

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --description "User management endpoints deployment" `
    --region $REGION | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoints Created:" -ForegroundColor Yellow
Write-Host "  GET    /users/me" -ForegroundColor White
Write-Host "  PUT    /users/me" -ForegroundColor White
Write-Host "  GET    /users" -ForegroundColor White
Write-Host "  POST   /users" -ForegroundColor White
Write-Host "  PUT    /users/{userId}" -ForegroundColor White
Write-Host "  DELETE /users/{userId}" -ForegroundColor White
Write-Host "  PUT    /users/{userId}/disable" -ForegroundColor White
Write-Host "  PUT    /users/{userId}/enable" -ForegroundColor White
Write-Host "  POST   /users/bulk" -ForegroundColor White
Write-Host ""
Write-Host "Base URL: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host ""
