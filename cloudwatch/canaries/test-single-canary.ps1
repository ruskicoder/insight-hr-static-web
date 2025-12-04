# Test deploying a single canary with correct structure
$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "Testing canary deployment" -ForegroundColor Cyan

$bucketName = "insighthr-canary-artifacts-sg"
$roleArn = "arn:aws:iam::151507815244:role/CloudWatchSyntheticsRole-InsightHR"
$canaryName = "insighthr-login-canary"

# Create temp directory
$tempDir = "temp-pkg"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path "$tempDir/nodejs/node_modules" -Force | Out-Null

# Copy script
Copy-Item "login-canary.js" "$tempDir/nodejs/node_modules/canaryScript.js"

# Create zip
Push-Location $tempDir
Compress-Archive -Path "nodejs" -DestinationPath "../test-canary.zip" -Force
Pop-Location
Remove-Item $tempDir -Recurse -Force

Write-Host "Package created" -ForegroundColor Green

# Upload
aws s3 cp "test-canary.zip" "s3://$bucketName/canaries/test-canary.zip" --region $region

# Create canary
aws synthetics create-canary --name $canaryName --code "S3Bucket=$bucketName,S3Key=canaries/test-canary.zip,Handler=canaryScript.handler" --execution-role-arn $roleArn --runtime-version "syn-nodejs-puppeteer-9.1" --schedule "Expression=rate(5 minutes)" --artifact-s3-location "s3://$bucketName/canary-artifacts/" --success-retention-period 31 --failure-retention-period 31 --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success!" -ForegroundColor Green
    aws synthetics start-canary --name $canaryName --region $region
} else {
    Write-Host "Failed" -ForegroundColor Red
}

# Cleanup
Remove-Item "test-canary.zip" -ErrorAction SilentlyContinue
