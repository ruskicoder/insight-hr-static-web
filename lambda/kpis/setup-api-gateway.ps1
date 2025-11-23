# Setup API Gateway endpoints for KPI Management
$ErrorActionPreference = "Stop"

$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$AUTHORIZER_ID = "ytil4t"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-kpis-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "=== Setting up API Gateway for KPI Management ===" -ForegroundColor Cyan

# Get root resource ID
Write-Host "`nGetting root resource ID..." -ForegroundColor Yellow
$ROOT_RESOURCE_ID = (aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json).items | Where-Object { $_.path -eq "/" } | Select-Object -ExpandProperty id
Write-Host "Root Resource ID: $ROOT_RESOURCE_ID" -ForegroundColor Cyan

# Check if /kpis resource exists
Write-Host "`nChecking if /kpis resource exists..." -ForegroundColor Yellow
$KPIS_RESOURCE_ID = (aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json).items | Where-Object { $_.path -eq "/kpis" } | Select-Object -ExpandProperty id

if ([string]::IsNullOrWhiteSpace($KPIS_RESOURCE_ID)) {
    Write-Host "Creating /kpis resource..." -ForegroundColor Yellow
    $result = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part "kpis" --region $REGION | ConvertFrom-Json
    $KPIS_RESOURCE_ID = $result.id
    Write-Host "✓ /kpis resource created: $KPIS_RESOURCE_ID" -ForegroundColor Green
} else {
    Write-Host "✓ /kpis resource already exists: $KPIS_RESOURCE_ID" -ForegroundColor Green
}

# Check if /kpis/{kpiId} resource exists
Write-Host "`nChecking if /kpis/{kpiId} resource exists..." -ForegroundColor Yellow
$KPIS_ID_RESOURCE_ID = (aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json).items | Where-Object { $_.path -eq "/kpis/{kpiId}" } | Select-Object -ExpandProperty id

if ([string]::IsNullOrWhiteSpace($KPIS_ID_RESOURCE_ID)) {
    Write-Host "Creating /kpis/{kpiId} resource..." -ForegroundColor Yellow
    $result = aws apigateway create-resource --rest-api-id $API_ID --parent-id $KPIS_RESOURCE_ID --path-part "{kpiId}" --region $REGION | ConvertFrom-Json
    $KPIS_ID_RESOURCE_ID = $result.id
    Write-Host "✓ /kpis/{kpiId} resource created: $KPIS_ID_RESOURCE_ID" -ForegroundColor Green
} else {
    Write-Host "✓ /kpis/{kpiId} resource already exists: $KPIS_ID_RESOURCE_ID" -ForegroundColor Green
}

# Function to create method
function Setup-Method {
    param($ResourceId, $HttpMethod, $Path)
    
    Write-Host "`nSetting up $HttpMethod $Path..." -ForegroundColor Yellow
    
    # Create method
    $ErrorActionPreference = "SilentlyContinue"
    aws apigateway put-method --rest-api-id $API_ID --resource-id $ResourceId --http-method $HttpMethod --authorization-type "COGNITO_USER_POOLS" --authorizer-id $AUTHORIZER_ID --region $REGION 2>$null
    $ErrorActionPreference = "Stop"
    
    # Create integration
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $ResourceId --http-method $HttpMethod --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION | Out-Null
    
    # Add Lambda permission
    $statementId = "apigateway-kpis-${HttpMethod}-${ResourceId}"
    $ErrorActionPreference = "SilentlyContinue"
    aws lambda add-permission --function-name insighthr-kpis-handler --statement-id $statementId --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${HttpMethod}${Path}" --region $REGION 2>$null
    $ErrorActionPreference = "Stop"
    
    Write-Host "✓ Method $HttpMethod configured" -ForegroundColor Green
}

# Function to enable CORS
function Setup-CORS {
    param($ResourceId)
    
    Write-Host "Enabling CORS..." -ForegroundColor Yellow
    
    # Create OPTIONS method
    $ErrorActionPreference = "SilentlyContinue"
    aws apigateway put-method --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --authorization-type NONE --region $REGION 2>$null
    $ErrorActionPreference = "Stop"
    
    # Create mock integration
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" --region $REGION | Out-Null
    
    # Create method response
    $ErrorActionPreference = "SilentlyContinue"
    aws apigateway put-method-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region $REGION 2>$null
    $ErrorActionPreference = "Stop"
    
    # Create integration response
    $ErrorActionPreference = "SilentlyContinue"
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,Authorization'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $REGION 2>$null
    $ErrorActionPreference = "Stop"
    
    Write-Host "✓ CORS enabled" -ForegroundColor Green
}

# Setup /kpis endpoints
Setup-Method -ResourceId $KPIS_RESOURCE_ID -HttpMethod "GET" -Path "/kpis"
Setup-Method -ResourceId $KPIS_RESOURCE_ID -HttpMethod "POST" -Path "/kpis"
Setup-CORS -ResourceId $KPIS_RESOURCE_ID

# Setup /kpis/{kpiId} endpoints
Setup-Method -ResourceId $KPIS_ID_RESOURCE_ID -HttpMethod "GET" -Path "/kpis/{kpiId}"
Setup-Method -ResourceId $KPIS_ID_RESOURCE_ID -HttpMethod "PUT" -Path "/kpis/{kpiId}"
Setup-Method -ResourceId $KPIS_ID_RESOURCE_ID -HttpMethod "DELETE" -Path "/kpis/{kpiId}"
Setup-CORS -ResourceId $KPIS_ID_RESOURCE_ID

# Deploy to dev stage
Write-Host "`nDeploying to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION | Out-Null

Write-Host "`n=== API Gateway Setup Complete ===" -ForegroundColor Green
Write-Host "`nAPI Endpoints:" -ForegroundColor Cyan
Write-Host "GET    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis"
Write-Host "POST   https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis"
Write-Host "GET    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
Write-Host "PUT    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
Write-Host "DELETE https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
