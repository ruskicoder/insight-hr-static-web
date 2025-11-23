# Setup API Gateway Endpoints for Employee Management
# This script creates API Gateway resources and methods for employee management endpoints

$ErrorActionPreference = "Stop"

# Configuration from aws-secret.md
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$AUTHORIZER_ID = "ytil4t"
$EMPLOYEES_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-employees-handler"
$EMPLOYEES_BULK_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-employees-bulk-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up API Gateway Endpoints for Employees" -ForegroundColor Cyan
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

# Create /employees resource
Write-Host "Creating /employees resource..." -ForegroundColor Yellow
$employeesResourceId = Get-OrCreateResource -ParentId $ROOT_RESOURCE_ID -PathPart "employees"

# Create /employees/{employeeId} resource
Write-Host "Creating /employees/{employeeId} resource..." -ForegroundColor Yellow
$employeesEmployeeIdResourceId = Get-OrCreateResource -ParentId $employeesResourceId -PathPart "{employeeId}"

# Create /employees/bulk resource
Write-Host "Creating /employees/bulk resource..." -ForegroundColor Yellow
$employeesBulkResourceId = Get-OrCreateResource -ParentId $employeesResourceId -PathPart "bulk"

Write-Host ""
Write-Host "Creating methods and integrations..." -ForegroundColor Yellow
Write-Host ""

# GET /employees
Write-Host "Setting up GET /employees" -ForegroundColor Cyan
Create-Method -ResourceId $employeesResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $employeesResourceId -HttpMethod "GET" -LambdaArn $EMPLOYEES_HANDLER_ARN

# POST /employees
Write-Host "Setting up POST /employees" -ForegroundColor Cyan
Create-Method -ResourceId $employeesResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $employeesResourceId -HttpMethod "POST" -LambdaArn $EMPLOYEES_HANDLER_ARN

# OPTIONS for /employees (shared by GET and POST)
Create-OptionsMethod -ResourceId $employeesResourceId

# GET /employees/{employeeId}
Write-Host "Setting up GET /employees/{employeeId}" -ForegroundColor Cyan
Create-Method -ResourceId $employeesEmployeeIdResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $employeesEmployeeIdResourceId -HttpMethod "GET" -LambdaArn $EMPLOYEES_HANDLER_ARN

# PUT /employees/{employeeId}
Write-Host "Setting up PUT /employees/{employeeId}" -ForegroundColor Cyan
Create-Method -ResourceId $employeesEmployeeIdResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $employeesEmployeeIdResourceId -HttpMethod "PUT" -LambdaArn $EMPLOYEES_HANDLER_ARN

# DELETE /employees/{employeeId}
Write-Host "Setting up DELETE /employees/{employeeId}" -ForegroundColor Cyan
Create-Method -ResourceId $employeesEmployeeIdResourceId -HttpMethod "DELETE" -RequireAuth $true
Create-Integration -ResourceId $employeesEmployeeIdResourceId -HttpMethod "DELETE" -LambdaArn $EMPLOYEES_HANDLER_ARN

# OPTIONS for /employees/{employeeId} (shared by GET, PUT, DELETE)
Create-OptionsMethod -ResourceId $employeesEmployeeIdResourceId

# POST /employees/bulk
Write-Host "Setting up POST /employees/bulk" -ForegroundColor Cyan
Create-Method -ResourceId $employeesBulkResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $employeesBulkResourceId -HttpMethod "POST" -LambdaArn $EMPLOYEES_BULK_HANDLER_ARN
Create-OptionsMethod -ResourceId $employeesBulkResourceId

Write-Host ""
Write-Host "Adding Lambda permissions..." -ForegroundColor Yellow

# Add Lambda permissions for employees-handler
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/employees"
Add-LambdaPermission -FunctionName "insighthr-employees-handler" -StatementId "apigateway-get-employees" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/employees"
Add-LambdaPermission -FunctionName "insighthr-employees-handler" -StatementId "apigateway-post-employees" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/employees/*"
Add-LambdaPermission -FunctionName "insighthr-employees-handler" -StatementId "apigateway-get-employees-id" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/employees/*"
Add-LambdaPermission -FunctionName "insighthr-employees-handler" -StatementId "apigateway-put-employees-id" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/DELETE/employees/*"
Add-LambdaPermission -FunctionName "insighthr-employees-handler" -StatementId "apigateway-delete-employees-id" -SourceArn $sourceArnBase

# Add Lambda permission for employees-bulk-handler
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/employees/bulk"
Add-LambdaPermission -FunctionName "insighthr-employees-bulk-handler" -StatementId "apigateway-post-employees-bulk" -SourceArn $sourceArnBase

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --description "Employee management endpoints deployment" `
    --region $REGION | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoints Created:" -ForegroundColor Yellow
Write-Host "  GET    /employees" -ForegroundColor White
Write-Host "  POST   /employees" -ForegroundColor White
Write-Host "  GET    /employees/{employeeId}" -ForegroundColor White
Write-Host "  PUT    /employees/{employeeId}" -ForegroundColor White
Write-Host "  DELETE /employees/{employeeId}" -ForegroundColor White
Write-Host "  POST   /employees/bulk" -ForegroundColor White
Write-Host ""
Write-Host "Base URL: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host ""
