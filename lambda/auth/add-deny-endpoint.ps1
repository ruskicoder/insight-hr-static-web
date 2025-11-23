# Add deny endpoint to password reset API
# Run this script from the lambda/auth directory

$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-password-reset-handler"
$AUTHORIZER_ID = "ytil4t"

Write-Host "Adding deny endpoint to password reset API..." -ForegroundColor Cyan

# Get password-requests resource ID
$PASSWORD_REQUESTS_RESOURCE = (aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?pathPart=='password-requests'].id" --output text).Trim()

if (-not $PASSWORD_REQUESTS_RESOURCE -or $PASSWORD_REQUESTS_RESOURCE -eq "") {
    Write-Host "Error: password-requests resource not found!" -ForegroundColor Red
    exit 1
}

Write-Host "password-requests resource ID: $PASSWORD_REQUESTS_RESOURCE" -ForegroundColor Green

# Create requestId resource under password-requests
Write-Host "`nCreating requestId resource..." -ForegroundColor Cyan
$allResources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --output json | ConvertFrom-Json
$REQUEST_ID_RESOURCE = ($allResources.items | Where-Object { $_.pathPart -eq '{requestId}' -and $_.parentId -eq $PASSWORD_REQUESTS_RESOURCE }).id

if (-not $REQUEST_ID_RESOURCE) {
    $REQUEST_ID_RESOURCE = (aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $PASSWORD_REQUESTS_RESOURCE `
        --path-part "{requestId}" `
        --region $REGION `
        --query 'id' --output text).Trim()
    Write-Host "Created requestId resource: $REQUEST_ID_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "requestId resource already exists: $REQUEST_ID_RESOURCE" -ForegroundColor Yellow
}

# Create approve resource under requestId
Write-Host "`nCreating approve resource..." -ForegroundColor Cyan
$APPROVE_RESOURCE = ($allResources.items | Where-Object { $_.pathPart -eq 'approve' -and $_.parentId -eq $REQUEST_ID_RESOURCE }).id

if (-not $APPROVE_RESOURCE) {
    $APPROVE_RESOURCE = (aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $REQUEST_ID_RESOURCE `
        --path-part "approve" `
        --region $REGION `
        --query 'id' --output text).Trim()
    Write-Host "Created approve resource: $APPROVE_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "approve resource already exists: $APPROVE_RESOURCE" -ForegroundColor Yellow
}

# Create POST method for approve
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method POST `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $AUTHORIZER_ID `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION 2>$null

aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-approve-post-v2 `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/POST/users/password-requests/*/approve" `
    --region $REGION 2>$null

# Enable CORS for approve
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION 2>$null

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION 2>$null

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION 2>$null

Write-Host "approve endpoint created" -ForegroundColor Green

# Create deny resource under requestId
Write-Host "`nCreating deny resource..." -ForegroundColor Cyan
$DENY_RESOURCE = ($allResources.items | Where-Object { $_.pathPart -eq 'deny' -and $_.parentId -eq $REQUEST_ID_RESOURCE }).id

if (-not $DENY_RESOURCE) {
    $DENY_RESOURCE = (aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $REQUEST_ID_RESOURCE `
        --path-part "deny" `
        --region $REGION `
        --query 'id' --output text).Trim()
    Write-Host "Created deny resource: $DENY_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "deny resource already exists: $DENY_RESOURCE" -ForegroundColor Yellow
}

# Create POST method for deny
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method POST `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $AUTHORIZER_ID `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION 2>$null

aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-deny-post `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/POST/users/password-requests/*/deny" `
    --region $REGION 2>$null

# Enable CORS for deny
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION 2>$null

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION 2>$null

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION 2>$null

Write-Host "deny endpoint created" -ForegroundColor Green

# Deploy to dev stage
Write-Host "`nDeploying API to dev stage..." -ForegroundColor Cyan
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --region $REGION

Write-Host "`nDeny endpoint deployed successfully!" -ForegroundColor Green
Write-Host "`nNew endpoints:" -ForegroundColor Cyan
$approveUrl = "POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/users/password-requests/REQUESTID/approve"
$denyUrl = "POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/users/password-requests/REQUESTID/deny"
Write-Host "  $approveUrl (auth required)" -ForegroundColor White
Write-Host "  $denyUrl (auth required)" -ForegroundColor White
