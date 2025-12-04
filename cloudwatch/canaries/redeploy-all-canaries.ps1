# Redeploy all canaries with updated code and config
$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"
$bucketName = "insighthr-canary-artifacts-sg"
$roleArn = "arn:aws:iam::151507815244:role/CloudWatchSyntheticsRole-InsightHR"

# Configuration
$cloudfrontUrl = "https://d2z6tht6rq32uy.cloudfront.net"
$apiGatewayUrl = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

$canaries = @(
    @{ Name = "insighthr-login-canary"; Script = "login-canary.js"; Schedule = "rate(5 minutes)" },
    @{ Name = "insighthr-dashboard-canary"; Script = "dashboard-canary.js"; Schedule = "rate(10 minutes)" },
    @{ Name = "insighthr-autoscoring-canary"; Script = "autoscoring-canary.js"; Schedule = "rate(30 minutes)" },
    @{ Name = "insighthr-chatbot-canary"; Script = "chatbot-canary.js"; Schedule = "rate(15 minutes)" }
)

foreach ($canary in $canaries) {
    Write-Host "Redeploying: $($canary.Name)" -ForegroundColor Cyan
    
    # Create package
    $tempDir = "temp-pkg"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path "$tempDir/nodejs/node_modules" -Force | Out-Null
    Copy-Item $canary.Script "$tempDir/nodejs/node_modules/canaryScript.js"
    
    $zipFile = "$($canary.Name).zip"
    Push-Location $tempDir
    Compress-Archive -Path "nodejs" -DestinationPath "../$zipFile" -Force
    Pop-Location
    Remove-Item $tempDir -Recurse -Force
    
    # Upload
    aws s3 cp $zipFile "s3://$bucketName/canaries/$zipFile" --region $region
    
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
    $runConfigFile = "run-config-$($canary.Name).json"
    $runConfigJson | Out-File -FilePath $runConfigFile -Encoding ASCII -NoNewline
    
    # Update canary
    aws synthetics update-canary `
        --name $canary.Name `
        --code "S3Bucket=$bucketName,S3Key=canaries/$zipFile,Handler=canaryScript.handler" `
        --execution-role-arn $roleArn `
        --runtime-version "syn-nodejs-puppeteer-9.1" `
        --schedule "Expression=$($canary.Schedule)" `
        --run-config "file://$runConfigFile" `
        --region $region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Redeployed: $($canary.Name)" -ForegroundColor Green
    } else {
        Write-Host "Failed: $($canary.Name)" -ForegroundColor Red
    }
    
    Remove-Item $zipFile -ErrorAction SilentlyContinue
    Remove-Item $runConfigFile -ErrorAction SilentlyContinue
    Write-Host ""
}

Write-Host "All canaries redeployed!" -ForegroundColor Green
Write-Host "Waiting for next run cycle..." -ForegroundColor Yellow
