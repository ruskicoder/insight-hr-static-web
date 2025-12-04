# Complete Canary Deployment Script
# Packages and deploys all 4 canaries to CloudWatch Synthetics

$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying CloudWatch Canaries" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get configuration
$awsSecret = Get-Content "../../aws-secret.md" -Raw
$cloudfrontUrl = if ($awsSecret -match 'CLOUDFRONT_URL=([^\s\n]+)') { $matches[1] } else { "https://d2z6tht6rq32uy.cloudfront.net" }
$apiGatewayUrl = if ($awsSecret -match 'API_GATEWAY_URL=([^\s\n]+)') { $matches[1] } else { "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" }

$bucketName = "insighthr-canary-artifacts-sg"
$roleName = "CloudWatchSyntheticsRole-InsightHR"
$roleArn = "arn:aws:iam::151507815244:role/$roleName"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  CloudFront: $cloudfrontUrl" -ForegroundColor Gray
Write-Host "  API Gateway: $apiGatewayUrl" -ForegroundColor Gray
Write-Host "  Role: $roleArn" -ForegroundColor Gray
Write-Host ""

# Define canaries
$canaries = @(
    @{
        Name = "insighthr-login-canary"
        Script = "login-canary.js"
        Schedule = "rate(5 minutes)"
    },
    @{
        Name = "insighthr-dashboard-canary"
        Script = "dashboard-canary.js"
        Schedule = "rate(10 minutes)"
    },
    @{
        Name = "insighthr-autoscoring-canary"
        Script = "autoscoring-canary.js"
        Schedule = "rate(30 minutes)"
    },
    @{
        Name = "insighthr-chatbot-canary"
        Script = "chatbot-canary.js"
        Schedule = "rate(15 minutes)"
    }
)

foreach ($canary in $canaries) {
    Write-Host "Deploying: $($canary.Name)" -ForegroundColor Cyan
    
    # Package script
    $zipFile = "$($canary.Name).zip"
    if (Test-Path $zipFile) {
        Remove-Item $zipFile
    }
    
    # Create nodejs folder structure for canary
    $tempDir = "temp-$($canary.Name)"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path "$tempDir/nodejs/node_modules" -Force | Out-Null
    
    # Copy script and rename to index.js
    Copy-Item $canary.Script "$tempDir/nodejs/node_modules/index.js"
    
    # Create zip
    Compress-Archive -Path "$tempDir/*" -DestinationPath $zipFile -Force
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "  Packaged: $zipFile" -ForegroundColor Gray
    
    # Upload to S3
    aws s3 cp $zipFile "s3://$bucketName/canaries/$zipFile" --region $region
    Write-Host "  Uploaded to S3" -ForegroundColor Gray
    
    # Check if canary exists
    $ErrorActionPreference = "Continue"
    $canaryExists = aws synthetics get-canary --name $canary.Name --region $region 2>&1
    $exists = $LASTEXITCODE -eq 0
    $ErrorActionPreference = "Stop"
    
    if ($exists) {
        Write-Host "  Canary exists - skipping" -ForegroundColor Yellow
    } else {
        Write-Host "  Creating canary..." -ForegroundColor Yellow
        
        # Create canary using AWS CLI
        aws synthetics create-canary `
            --name $canary.Name `
            --artifact-s3-location "s3://$bucketName/canary-artifacts/" `
            --execution-role-arn $roleArn `
            --schedule "Expression=$($canary.Schedule)" `
            --runtime-version "syn-nodejs-puppeteer-6.2" `
            --code "S3Bucket=$bucketName,S3Key=canaries/$zipFile,Handler=nodejs/node_modules/index.handler" `
            --region $region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Created successfully" -ForegroundColor Green
            
            # Start canary
            aws synthetics start-canary --name $canary.Name --region $region
            Write-Host "  Started" -ForegroundColor Green
        } else {
            Write-Host "  Failed to create" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "View canaries:" -ForegroundColor Yellow
Write-Host "https://console.aws.amazon.com/cloudwatch/home?region=$region" -ForegroundColor Cyan
