# Update API Gateway CORS to allow CloudFront domain
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update CORS for CloudFront" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$region = "ap-southeast-1"
$apiId = "lqk4t6qzag"
$cloudfrontDomain = "d2z6tht6rq32uy.cloudfront.net"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  API Gateway ID: $apiId"
Write-Host "  CloudFront Domain: $cloudfrontDomain"
Write-Host ""

Write-Host "Fetching API Gateway resources..." -ForegroundColor Yellow
$resources = aws apigateway get-resources --rest-api-id $apiId --region $region --output json | ConvertFrom-Json

$loginResource = $resources.items | Where-Object { $_.path -eq "/auth/login" }
$registerResource = $resources.items | Where-Object { $_.path -eq "/auth/register" }
$googleResource = $resources.items | Where-Object { $_.path -eq "/auth/google" }

Write-Host "Updating CORS for /auth/login..." -ForegroundColor Yellow
if ($loginResource) {
    $patchOps = "op=replace,path=/responseParameters/method.response.header.Access-Control-Allow-Origin,value='*'"
    aws apigateway update-integration-response --rest-api-id $apiId --resource-id $loginResource.id --http-method OPTIONS --status-code 200 --patch-operations $patchOps --region $region --output json | Out-Null
    Write-Host "  Updated /auth/login (Allow-Origin: *)" -ForegroundColor Green
}

Write-Host "Updating CORS for /auth/register..." -ForegroundColor Yellow
if ($registerResource) {
    $patchOps = "op=replace,path=/responseParameters/method.response.header.Access-Control-Allow-Origin,value='*'"
    aws apigateway update-integration-response --rest-api-id $apiId --resource-id $registerResource.id --http-method OPTIONS --status-code 200 --patch-operations $patchOps --region $region --output json | Out-Null
    Write-Host "  Updated /auth/register (Allow-Origin: *)" -ForegroundColor Green
}

Write-Host "Updating CORS for /auth/google..." -ForegroundColor Yellow
if ($googleResource) {
    $patchOps = "op=replace,path=/responseParameters/method.response.header.Access-Control-Allow-Origin,value='*'"
    aws apigateway update-integration-response --rest-api-id $apiId --resource-id $googleResource.id --http-method OPTIONS --status-code 200 --patch-operations $patchOps --region $region --output json | Out-Null
    Write-Host "  Updated /auth/google (Allow-Origin: *)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deploying changes to dev stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name dev --region $region --output json | Out-Null
Write-Host "Deployment complete" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "CORS Update Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "CloudFront domain is now allowed: https://$cloudfrontDomain" -ForegroundColor Cyan
