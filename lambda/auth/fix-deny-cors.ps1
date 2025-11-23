# Fix CORS for deny endpoint
$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$DENY_RESOURCE_ID = "hdn171"

Write-Host "Fixing CORS for deny endpoint..." -ForegroundColor Cyan

# Add integration response for OPTIONS
aws apigateway put-integration-response `
    --rest-api-id $API_ID `
    --resource-id $DENY_RESOURCE_ID `
    --http-method OPTIONS `
    --status-code 200 `
    --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" `
    --region $REGION

Write-Host "Integration response added" -ForegroundColor Green

# Deploy API
Write-Host "Deploying API..." -ForegroundColor Cyan
aws apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name dev `
    --region $REGION

Write-Host "CORS fixed and deployed!" -ForegroundColor Green
