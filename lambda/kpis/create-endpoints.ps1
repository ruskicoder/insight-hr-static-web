# Simple script to create KPI API Gateway endpoints
$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"
$AUTHORIZER_ID = "ytil4t"
$LAMBDA_ARN = "arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-kpis-handler"
$ACCOUNT_ID = "151507815244"

Write-Host "Creating KPI API Gateway endpoints..." -ForegroundColor Cyan

# Get resource IDs
$resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json
$kpisResource = $resources.items | Where-Object { $_.path -eq "/kpis" }
$kpisIdResource = $resources.items | Where-Object { $_.path -eq "/kpis/{kpiId}" }

$KPIS_RESOURCE_ID = $kpisResource.id
$KPIS_ID_RESOURCE_ID = $kpisIdResource.id

Write-Host "KPIs Resource ID: $KPIS_RESOURCE_ID"
Write-Host "KPIs ID Resource ID: $KPIS_ID_RESOURCE_ID"

# Create GET /kpis
Write-Host "`nCreating GET /kpis..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method GET --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION
aws lambda add-permission --function-name insighthr-kpis-handler --statement-id "apigateway-kpis-GET" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/kpis" --region $REGION

# Create POST /kpis
Write-Host "`nCreating POST /kpis..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method POST --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION
aws lambda add-permission --function-name insighthr-kpis-handler --statement-id "apigateway-kpis-POST" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/kpis" --region $REGION

# Create OPTIONS /kpis (CORS)
Write-Host "`nCreating OPTIONS /kpis (CORS)..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method OPTIONS --authorization-type NONE --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" --region $REGION
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region $REGION
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $KPIS_RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,Authorization'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $REGION

# Create GET /kpis/{kpiId}
Write-Host "`nCreating GET /kpis/{kpiId}..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method GET --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION
aws lambda add-permission --function-name insighthr-kpis-handler --statement-id "apigateway-kpis-GET-id" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/kpis/*" --region $REGION

# Create PUT /kpis/{kpiId}
Write-Host "`nCreating PUT /kpis/{kpiId}..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method PUT --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method PUT --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION
aws lambda add-permission --function-name insighthr-kpis-handler --statement-id "apigateway-kpis-PUT" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/kpis/*" --region $REGION

# Create DELETE /kpis/{kpiId}
Write-Host "`nCreating DELETE /kpis/{kpiId}..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method DELETE --authorization-type COGNITO_USER_POOLS --authorizer-id $AUTHORIZER_ID --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method DELETE --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION
aws lambda add-permission --function-name insighthr-kpis-handler --statement-id "apigateway-kpis-DELETE" --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/DELETE/kpis/*" --region $REGION

# Create OPTIONS /kpis/{kpiId} (CORS)
Write-Host "`nCreating OPTIONS /kpis/{kpiId} (CORS)..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method OPTIONS --authorization-type NONE --region $REGION
aws apigateway put-integration --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method OPTIONS --type MOCK --request-templates "{\`"application/json\`":\`"{\\\`"statusCode\\\`":200}\`"}" --region $REGION
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region $REGION
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $KPIS_ID_RESOURCE_ID --http-method OPTIONS --status-code 200 --response-parameters "{\`"method.response.header.Access-Control-Allow-Headers\`":\`"'Content-Type,Authorization'\`",\`"method.response.header.Access-Control-Allow-Methods\`":\`"'GET,POST,PUT,DELETE,OPTIONS'\`",\`"method.response.header.Access-Control-Allow-Origin\`":\`"'*'\`"}" --region $REGION

# Deploy to dev stage
Write-Host "`nDeploying to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION

Write-Host "`n=== API Gateway Setup Complete ===" -ForegroundColor Green
Write-Host "`nAPI Endpoints:" -ForegroundColor Cyan
Write-Host "GET    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis"
Write-Host "POST   https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis"
Write-Host "GET    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
Write-Host "PUT    https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
Write-Host "DELETE https://${API_ID}.execute-api.${REGION}.amazonaws.com/dev/kpis/{kpiId}"
