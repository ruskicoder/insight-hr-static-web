# Setup API Gateway Endpoints for Attendance Management
# This script creates API Gateway resources and methods for attendance management endpoints

$ErrorActionPreference = "Stop"

# Configuration from aws-secret.md
$REGION = "ap-southeast-1"
$API_ID = "lqk4t6qzag"
$ROOT_RESOURCE_ID = "0enqabvot5"
$AUTHORIZER_ID = "ytil4t"
$ATTENDANCE_HANDLER_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-attendance-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up API Gateway Endpoints for Attendance" -ForegroundColor Cyan
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

# Create /attendance resource
Write-Host "Creating /attendance resource..." -ForegroundColor Yellow
$attendanceResourceId = Get-OrCreateResource -ParentId $ROOT_RESOURCE_ID -PathPart "attendance"

# Create /attendance/check-in resource
Write-Host "Creating /attendance/check-in resource..." -ForegroundColor Yellow
$checkInResourceId = Get-OrCreateResource -ParentId $attendanceResourceId -PathPart "check-in"

# Create /attendance/check-out resource
Write-Host "Creating /attendance/check-out resource..." -ForegroundColor Yellow
$checkOutResourceId = Get-OrCreateResource -ParentId $attendanceResourceId -PathPart "check-out"

# Create /attendance/bulk resource
Write-Host "Creating /attendance/bulk resource..." -ForegroundColor Yellow
$bulkResourceId = Get-OrCreateResource -ParentId $attendanceResourceId -PathPart "bulk"

# Create /attendance/{employeeId} resource
Write-Host "Creating /attendance/{employeeId} resource..." -ForegroundColor Yellow
$employeeIdResourceId = Get-OrCreateResource -ParentId $attendanceResourceId -PathPart "{employeeId}"

# Create /attendance/{employeeId}/status resource
Write-Host "Creating /attendance/{employeeId}/status resource..." -ForegroundColor Yellow
$statusResourceId = Get-OrCreateResource -ParentId $employeeIdResourceId -PathPart "status"

# Create /attendance/{employeeId}/{date} resource
Write-Host "Creating /attendance/{employeeId}/{date} resource..." -ForegroundColor Yellow
$employeeIdDateResourceId = Get-OrCreateResource -ParentId $employeeIdResourceId -PathPart "{date}"

Write-Host ""
Write-Host "Creating methods and integrations..." -ForegroundColor Yellow
Write-Host ""

# GET /attendance (protected)
Write-Host "Setting up GET /attendance" -ForegroundColor Cyan
Create-Method -ResourceId $attendanceResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $attendanceResourceId -HttpMethod "GET" -LambdaArn $ATTENDANCE_HANDLER_ARN

# POST /attendance (protected - manual create)
Write-Host "Setting up POST /attendance" -ForegroundColor Cyan
Create-Method -ResourceId $attendanceResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $attendanceResourceId -HttpMethod "POST" -LambdaArn $ATTENDANCE_HANDLER_ARN

# OPTIONS for /attendance
Create-OptionsMethod -ResourceId $attendanceResourceId

# POST /attendance/check-in (public - no auth)
Write-Host "Setting up POST /attendance/check-in (PUBLIC)" -ForegroundColor Cyan
Create-Method -ResourceId $checkInResourceId -HttpMethod "POST" -RequireAuth $false
Create-Integration -ResourceId $checkInResourceId -HttpMethod "POST" -LambdaArn $ATTENDANCE_HANDLER_ARN
Create-OptionsMethod -ResourceId $checkInResourceId

# POST /attendance/check-out (public - no auth)
Write-Host "Setting up POST /attendance/check-out (PUBLIC)" -ForegroundColor Cyan
Create-Method -ResourceId $checkOutResourceId -HttpMethod "POST" -RequireAuth $false
Create-Integration -ResourceId $checkOutResourceId -HttpMethod "POST" -LambdaArn $ATTENDANCE_HANDLER_ARN
Create-OptionsMethod -ResourceId $checkOutResourceId

# POST /attendance/bulk (protected)
Write-Host "Setting up POST /attendance/bulk" -ForegroundColor Cyan
Create-Method -ResourceId $bulkResourceId -HttpMethod "POST" -RequireAuth $true
Create-Integration -ResourceId $bulkResourceId -HttpMethod "POST" -LambdaArn $ATTENDANCE_HANDLER_ARN
Create-OptionsMethod -ResourceId $bulkResourceId

# GET /attendance/{employeeId}/status (public - no auth)
Write-Host "Setting up GET /attendance/{employeeId}/status (PUBLIC)" -ForegroundColor Cyan
Create-Method -ResourceId $statusResourceId -HttpMethod "GET" -RequireAuth $false
Create-Integration -ResourceId $statusResourceId -HttpMethod "GET" -LambdaArn $ATTENDANCE_HANDLER_ARN
Create-OptionsMethod -ResourceId $statusResourceId

# GET /attendance/{employeeId}/{date} (protected)
Write-Host "Setting up GET /attendance/{employeeId}/{date}" -ForegroundColor Cyan
Create-Method -ResourceId $employeeIdDateResourceId -HttpMethod "GET" -RequireAuth $true
Create-Integration -ResourceId $employeeIdDateResourceId -HttpMethod "GET" -LambdaArn $ATTENDANCE_HANDLER_ARN

# PUT /attendance/{employeeId}/{date} (protected)
Write-Host "Setting up PUT /attendance/{employeeId}/{date}" -ForegroundColor Cyan
Create-Method -ResourceId $employeeIdDateResourceId -HttpMethod "PUT" -RequireAuth $true
Create-Integration -ResourceId $employeeIdDateResourceId -HttpMethod "PUT" -LambdaArn $ATTENDANCE_HANDLER_ARN

# DELETE /attendance/{employeeId}/{date} (protected)
Write-Host "Setting up DELETE /attendance/{employeeId}/{date}" -ForegroundColor Cyan
Create-Method -ResourceId $employeeIdDateResourceId -HttpMethod "DELETE" -RequireAuth $true
Create-Integration -ResourceId $employeeIdDateResourceId -HttpMethod "DELETE" -LambdaArn $ATTENDANCE_HANDLER_ARN

# OPTIONS for /attendance/{employeeId}/{date}
Create-OptionsMethod -ResourceId $employeeIdDateResourceId

Write-Host ""
Write-Host "Adding Lambda permissions..." -ForegroundColor Yellow

# Add Lambda permissions
$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/attendance"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-get-attendance" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/attendance"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-post-attendance" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/attendance/check-in"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-post-checkin" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/attendance/check-out"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-post-checkout" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/attendance/bulk"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-post-attendance-bulk" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/attendance/*"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-get-attendance-id" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/attendance/*"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-put-attendance-id" -SourceArn $sourceArnBase

$sourceArnBase = "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/DELETE/attendance/*"
Add-LambdaPermission -FunctionName "insighthr-attendance-handler" -StatementId "apigateway-delete-attendance-id" -SourceArn $sourceArnBase

Write-Host ""
Write-Host "Deploying API to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --description "Attendance management endpoints deployment" `
    --region $REGION | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Gateway Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoints Created:" -ForegroundColor Yellow
Write-Host "  GET    /attendance (protected)" -ForegroundColor White
Write-Host "  POST   /attendance (protected)" -ForegroundColor White
Write-Host "  POST   /attendance/check-in (PUBLIC)" -ForegroundColor Green
Write-Host "  POST   /attendance/check-out (PUBLIC)" -ForegroundColor Green
Write-Host "  GET    /attendance/{employeeId}/status (PUBLIC)" -ForegroundColor Green
Write-Host "  GET    /attendance/{employeeId}/{date} (protected)" -ForegroundColor White
Write-Host "  PUT    /attendance/{employeeId}/{date} (protected)" -ForegroundColor White
Write-Host "  DELETE /attendance/{employeeId}/{date} (protected)" -ForegroundColor White
Write-Host "  POST   /attendance/bulk (protected)" -ForegroundColor White
Write-Host ""
Write-Host "Base URL: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host ""

