# Create /users/password-requests endpoint
# Run this script from the lambda/auth directory

$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-password-reset-handler"
$AUTHORIZER_ID = "ytil4t"
$USERS_RESOURCE_ID = "5eaoke"

Write-Host "Creating /users/password-requests endpoint..." -ForegroundColor Cyan

# Create password-requests resource
Write-Host "Creating password-requests resource under /users..." -ForegroundColor Yellow
$RESOURCE_ID = aws apigateway create-resource `
    --rest-api-id $API_ID `
    --parent-id $USERS_RESOURCE_ID `
    --path-part "password-requests" `
    --region $REGION `
    --query 'id' `
    --output text

Write-Host "Created resource ID: $RESOURCE_ID" -ForegroundColor Green

# Create GET method with Cognito authorizer
Write-Host "Creating GET method with Cognito authorizer..." -ForegroundColor Yellow
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method GET `
    --authorization-type COGNITO_USER_POOLS `
    --authorizer-id $AUTHORIZER_ID `
    --region $REGION

# Set up Lambda integration
Write-Host "Setting up Lambda integration..." -ForegroundColor Yellow
aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method GET `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
    --region $REGION

# Add Lambda permission
Write-Host "Adding Lambda permission..." -ForegroundColor Yellow
aws lambda add-permission `
    --function-name insighthr-password-reset-handler `
    --statement-id apigateway-password-requests-get-v2 `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:151507815244:${API_ID}/*/GET/users/password-requests" `
    --region $REGION

# Create OPTIONS method for CORS
Write-Host "Setting up CORS..." -ForegroundColor Yellow
aws apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method OPTIONS `
    --authorization-type NONE `
    --region $REGION

aws apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method OPTIONS `
    --type MOCK `
    --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" `
    --region $REGION

aws apigateway put-method-response `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":false,\`"method.response.header.Access-Control-Allow-Methods\`":false,\`"method.response.header.Access-Control-Allow-Origin\`":false}" `
    --region $REGION

aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $RESOURCE_ID `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION

# Deploy to dev stage
Write-Host "Deploying to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --region $REGION

Write-Host "`n✓ /users/password-requests endpoint created successfully!" -ForegroundColor Green
Write-Host "Endpoint: GET https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/users/password-requests" -ForegroundColor White
