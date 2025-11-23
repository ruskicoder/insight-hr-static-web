$API_ID = "lqk4t6qzag"
$REGION = "ap-southeast-1"

$resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json

foreach ($resource in $resources.items) {
    if ($resource.resourceMethods) {
        foreach ($method in $resource.resourceMethods.PSObject.Properties.Name) {
            try {
                $integration = aws apigateway get-integration --rest-api-id $API_ID --resource-id $resource.id --http-method $method --region $REGION 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "MISSING INTEGRATION: $($resource.path) $method" -ForegroundColor Red
                }
            } catch {
                Write-Host "ERROR checking $($resource.path) $method : $_" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`nCheck complete!" -ForegroundColor Green
