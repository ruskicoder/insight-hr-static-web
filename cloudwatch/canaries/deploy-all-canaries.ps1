# Deploy all 4 canaries
$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"
$bucketName = "insighthr-canary-artifacts-sg"
$roleArn = "arn:aws:iam::151507815244:role/CloudWatchSyntheticsRole-InsightHR"

$canaries = @(
    @{ Name = "insighthr-dashboard-canary"; Script = "dashboard-canary.js"; Schedule = "rate(10 minutes)" },
    @{ Name = "insighthr-autoscoring-canary"; Script = "autoscoring-canary.js"; Schedule = "rate(30 minutes)" },
    @{ Name = "insighthr-chatbot-canary"; Script = "chatbot-canary.js"; Schedule = "rate(15 minutes)" }
)

foreach ($canary in $canaries) {
    Write-Host "Deploying: $($canary.Name)" -ForegroundColor Cyan
    
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
    
    # Create canary
    aws synthetics create-canary `
        --name $canary.Name `
        --code "S3Bucket=$bucketName,S3Key=canaries/$zipFile,Handler=canaryScript.handler" `
        --execution-role-arn $roleArn `
        --runtime-version "syn-nodejs-puppeteer-9.1" `
        --schedule "Expression=$($canary.Schedule)" `
        --artifact-s3-location "s3://$bucketName/canary-artifacts/" `
        --success-retention-period 31 `
        --failure-retention-period 31 `
        --region $region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Created: $($canary.Name)" -ForegroundColor Green
    } else {
        Write-Host "Failed: $($canary.Name)" -ForegroundColor Red
    }
    
    Remove-Item $zipFile -ErrorAction SilentlyContinue
    Write-Host ""
}

Write-Host "Waiting for canaries to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Start all canaries
foreach ($canary in $canaries) {
    Write-Host "Starting: $($canary.Name)" -ForegroundColor Cyan
    aws synthetics start-canary --name $canary.Name --region $region
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Started: $($canary.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "All canaries deployed!" -ForegroundColor Green
