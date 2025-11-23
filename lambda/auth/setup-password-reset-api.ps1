# Setup API Gateway endpoints for password reset handler
# Run this script from the lambda/auth directory

$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-password-reset-handler"
$AUTHORIZER_ID = "ytil4t"

Write-Host "Setting up password reset API endpoints..." -ForegroundColor Cyan

# Get root resource ID
$ROOT_RESOURCE_ID = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/'].id" --output text

# Get auth resource ID
$AUTH_RESOURCE_ID = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/auth'].id" --output text

# Get users resource ID
$USERS_RESOURCE_ID = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/users'].id" --output text

Write-Host "Root Resource ID: $ROOT_RESOURCE_ID" -ForegroundColor Green
Write-Host "Auth Resource ID: $AUTH_RESOURCE_ID" -ForegroundColor Green
Write-Host "Users Resource ID: $USERS_RESOURCE_ID" -ForegroundColor Green

# 1. Create /auth/request-reset resource
Write-Host "`nCreating /auth/request-reset endpoint..." -ForegroundColor Cyan
$REQUEST_RESET_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?pathPart=='request-reset'].id" --output text

if (-not $REQUEST_RESET_RESOURCE) {
    $REQUEST_RESET_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $AUTH_RESOURCE_ID `
        --path-part "request-reset" `
        --region $REGION `
        --query 'id' --output text
    Write-Host "Created request-reset resource: $REQUEST_RESET_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "request-reset resource already exists: $REQUEST_RESET_RESOURCE" -ForegroundColor Yellow
}

# Create POST method for /auth/request-reset (public, no auth)
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method POST `
    --authorization-type NONE `
    --region $REGION 2>$null

# Set up integration
aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION 2>$null

# Add Lambda permission
aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-request-reset-post `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/POST/auth/request-reset" `
    --region $REGION 2>$null

# Enable CORS
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION 2>$null

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION 2>$null

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $REQUEST_RESET_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION 2>$null

Write-Host "✓ /auth/request-reset endpoint created" -ForegroundColor Green

# 2. Create /users/password-requests resource
Write-Host "`nCreating /users/password-requests endpoint..." -ForegroundColor Cyan
$PASSWORD_REQUESTS_RESOURCE = (aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?pathPart=='password-requests'].id" --output text).Trim()

if (-not $PASSWORD_REQUESTS_RESOURCE -or $PASSWORD_REQUESTS_RESOURCE -eq "") {
    $PASSWORD_REQUESTS_RESOURCE = (aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $USERS_RESOURCE_ID `
        --path-part "password-requests" `
        --region $REGION `
        --query 'id' --output text).Trim()
    Write-Host "Created password-requests resource: $PASSWORD_REQUESTS_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "password-requests resource already exists: $PASSWORD_REQUESTS_RESOURCE" -ForegroundColor Yellow
}

# Create GET method for /users/password-requests (requires auth)
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method GET `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $AUTHORIZER_ID `
    --region $REGION 2>$null

# Set up integration
aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method GET `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION 2>$null

# Add Lambda permission
aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-password-requests-get `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/GET/users/password-requests" `
    --region $REGION 2>$null

# Enable CORS
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION 2>$null

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION 2>$null

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $PASSWORD_REQUESTS_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION 2>$null

Write-Host "✓ /users/password-requests endpoint created" -ForegroundColor Green

# 3. Create /users/{userId}/approve-reset resource
Write-Host "`nCreating /users/{userId}/approve-reset endpoint..." -ForegroundColor Cyan

# First, get or create {userId} resource
$USER_ID_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?pathPart=='{userId}'].id" --output text

if (-not $USER_ID_RESOURCE) {
    $USER_ID_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $USERS_RESOURCE_ID `
        --path-part "{userId}" `
        --region $REGION `
        --query 'id' --output text
    Write-Host "Created {userId} resource: $USER_ID_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "{userId} resource already exists: $USER_ID_RESOURCE" -ForegroundColor Yellow
}

# Create approve-reset resource
$APPROVE_RESET_RESOURCE = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?pathPart=='approve-reset'].id" --output text

if (-not $APPROVE_RESET_RESOURCE) {
    $APPROVE_RESET_RESOURCE = aws apigateway create-resource `
        --rest-api-id $API_ID `
        --parent-id $USER_ID_RESOURCE `
        --path-part "approve-reset" `
        --region $REGION `
        --query 'id' --output text
    Write-Host "Created approve-reset resource: $APPROVE_RESET_RESOURCE" -ForegroundColor Green
} else {
    Write-Host "approve-reset resource already exists: $APPROVE_RESET_RESOURCE" -ForegroundColor Yellow
}

# Create POST method for /users/{userId}/approve-reset (requires auth)
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method POST `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $AUTHORIZER_ID `
    --region $REGION 2>$null

# Set up integration
aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION 2>$null

# Add Lambda permission
aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-approve-reset-post `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/POST/users/*/approve-reset" `
    --region $REGION 2>$null

# Enable CORS
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION 2>$null

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION 2>$null

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION 2>$null

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $APPROVE_RESET_RESOURCE `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION 2>$null

Write-Host "✓ /users/{userId}/approve-reset endpoint created" -ForegroundColor Green

# Deploy to dev stage
Write-Host "`nDeploying API to dev stage..." -ForegroundColor Cyan
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --region $REGION

Write-Host "`n✓ All password reset endpoints deployed successfully!" -ForegroundColor Green
Write-Host "`nEndpoints:" -ForegroundColor Cyan
Write-Host "  POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/auth/request-reset (public)" -ForegroundColor White
Write-Host "  GET  https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/users/password-requests (auth required)" -ForegroundColor White
Write-Host "  POST https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/users/{userId}/approve-reset (auth required)" -ForegroundColor White
