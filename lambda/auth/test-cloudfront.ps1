# Test CloudFront Distribution
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing CloudFront Distribution" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cloudfrontUrl = "https://d2z6tht6rq32uy.cloudfront.net"
$distributionId = "E3MHW5VALWTOCI"

Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor Cyan
Write-Host ""

# Check distribution status
Write-Host "Checking distribution status..." -ForegroundColor Yellow
$status = aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status' --output text
Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq "Deployed") { "Green" } else { "Yellow" })
Write-Host ""

if ($status -ne "Deployed") {
    Write-Host "Warning: Distribution is not fully deployed yet." -ForegroundColor Yellow
    Write-Host "Please wait a few more minutes and try again." -ForegroundColor Yellow
    exit 0
}

# Test HTTPS access
Write-Host "Testing HTTPS access to CloudFront..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $cloudfrontUrl -Method GET -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "  Success - HTTPS access working (Status: 200)" -ForegroundColor Green
        Write-Host "  Content-Type: $($response.Headers['Content-Type'])" -ForegroundColor Gray
        Write-Host "  Content-Length: $($response.Content.Length) bytes" -ForegroundColor Gray
    } else {
        Write-Host "  Unexpected status code: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error accessing CloudFront: $_" -ForegroundColor Red
}
Write-Host ""

# Test SPA routing
Write-Host "Testing SPA routing for React app..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$cloudfrontUrl/dashboard" -Method GET -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "  Success - SPA routing works (Status: 200)" -ForegroundColor Green
    } else {
        Write-Host "  Unexpected status code: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error testing SPA routing: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "CloudFront Testing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at:" -ForegroundColor Yellow
Write-Host "  HTTPS (CloudFront): $cloudfrontUrl" -ForegroundColor Cyan
Write-Host "  HTTP (S3 Direct):   http://insighthr-web-app-sg.s3-website-ap-southeast-1.amazonaws.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "Both URLs work and point to the same content." -ForegroundColor Gray
Write-Host "CloudFront provides HTTPS and global CDN caching." -ForegroundColor Gray
Write-Host ""
