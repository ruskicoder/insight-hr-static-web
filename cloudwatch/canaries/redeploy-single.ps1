# Redeploy a single canary
param(
    [Parameter(Mandatory=$true)]
    [string]$CanaryName,
    
    [Parameter(Mandatory=$true)]
    [string]$ScriptFile
)

$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"
$bucketName = "insighthr-canary-artifacts-sg"
$roleArn = "arn:aws:iam::151507815244:role/CloudWatchSyntheticsRole-InsightHR"

Write-Host "Redeploying: $CanaryName" -ForegroundColor Cyan
Write-Host "Script: $ScriptFile" -ForegroundColor Gray

# Configuration
$cloudfrontUrl = "https://d2z6tht6rq32uy.cloudfront.net"
$apiGatewayUrl = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

# Create package
$tempDir = "temp-pkg"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path "$tempDir/nodejs/node_modules" -Force | Out-Null
Copy-Item $ScriptFile "$tempDir/nodejs/node_modules/canaryScript.js"

$zipFile = "$CanaryName.zip"
Push-Location $tempDir
Compress-Archive -Path "nodejs" -DestinationPath "../$zipFile" -Force
Pop-Location
Remove-Item $tempDir -Recurse -Force

Write-Host "Package created" -ForegroundColor Green

# Upload
aws s3 cp $zipFile "s3://$bucketName/canaries/$zipFile" --region $region
Write-Host "Uploaded to S3" -ForegroundColor Green

# Create run config
$runConfigJson = @"
{
  "TimeoutInSeconds": 300,
  "MemoryInMB": 960,
  "EnvironmentVariables": {
    "CLOUDFRONT_URL": "$cloudfrontUrl",
    "API_GATEWAY_URL": "$apiGatewayUrl",
    "TEST_USER_EMAIL": "admin@insighthr.com",
    "TEST_USER_PASSWORD": "InsightHR2024!"
  }
}
"@
$runConfigFile = "run-config-$CanaryName.json"
$runConfigJson | Out-File -FilePath $runConfigFile -Encoding ASCII -NoNewline

# Update canary
aws synthetics update-canary `
    --name $CanaryName `
    --code "S3Bucket=$bucketName,S3Key=canaries/$zipFile,Handler=canaryScript.handler" `
    --execution-role-arn $roleArn `
    --runtime-version "syn-nodejs-puppeteer-9.1" `
    --schedule "Expression=rate(5 minutes)" `
    --run-config "file://$runConfigFile" `
    --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Redeployed successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to redeploy" -ForegroundColor Red
}

Remove-Item $zipFile -ErrorAction SilentlyContinue
Remove-Item $runConfigFile -ErrorAction SilentlyContinue
