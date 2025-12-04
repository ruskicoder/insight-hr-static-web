# Deploy CloudWatch Synthetics Infrastructure for InsightHR
# This script creates S3 bucket, IAM role, and SNS topic

$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "InsightHR CloudWatch Infrastructure Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI
Write-Host "Checking AWS CLI configuration..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --region $region | ConvertFrom-Json
    Write-Host "AWS CLI configured - Account: $($identity.Account)" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI not configured" -ForegroundColor Red
    exit 1
}

# Get config from aws-secret.md
Write-Host ""
Write-Host "Reading configuration..." -ForegroundColor Yellow

if (-not (Test-Path "../../aws-secret.md")) {
    Write-Host "aws-secret.md not found" -ForegroundColor Red
    exit 1
}

$awsSecret = Get-Content "../../aws-secret.md" -Raw
$cloudfrontUrl = if ($awsSecret -match 'CLOUDFRONT_URL=([^\s\n]+)') { $matches[1] } else { "https://d2z6tht6rq32uy.cloudfront.net" }
$apiGatewayUrl = if ($awsSecret -match 'API_GATEWAY_URL=([^\s\n]+)') { $matches[1] } else { "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev" }

Write-Host "Configuration loaded" -ForegroundColor Green
Write-Host "  CloudFront: $cloudfrontUrl" -ForegroundColor Gray
Write-Host "  API Gateway: $apiGatewayUrl" -ForegroundColor Gray

# Step 1: S3 Bucket
Write-Host ""
Write-Host "Step 1: S3 bucket for canary artifacts..." -ForegroundColor Yellow
$bucketName = "insighthr-canary-artifacts-sg"

$bucketExists = aws s3 ls s3://$bucketName --region $region 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating bucket: $bucketName" -ForegroundColor Cyan
    aws s3 mb s3://$bucketName --region $region
    Write-Host "Bucket created" -ForegroundColor Green
} else {
    Write-Host "Bucket already exists" -ForegroundColor Green
}

# Step 2: IAM Role
Write-Host ""
Write-Host "Step 2: IAM role for Synthetics..." -ForegroundColor Yellow
$roleName = "CloudWatchSyntheticsRole-InsightHR"

$ErrorActionPreference = "Continue"
$roleExists = aws iam get-role --role-name $roleName 2>&1
$roleNotFound = $LASTEXITCODE -ne 0
$ErrorActionPreference = "Stop"

if ($roleNotFound) {
    Write-Host "Creating IAM role: $roleName" -ForegroundColor Cyan
    
    # Trust policy
    @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "synthetics.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
'@ | Out-File -FilePath "trust-policy.json" -Encoding utf8
    
    aws iam create-role --role-name $roleName --assume-role-policy-document file://trust-policy.json
    
    # Attach policies
    aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
    aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    
    Write-Host "IAM role created" -ForegroundColor Green
    Write-Host "Waiting for role to propagate..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
} else {
    Write-Host "IAM role already exists" -ForegroundColor Green
}

$roleArn = (aws iam get-role --role-name $roleName | ConvertFrom-Json).Role.Arn
Write-Host "  Role ARN: $roleArn" -ForegroundColor Gray

# Step 3: SNS Topic
Write-Host ""
Write-Host "Step 3: SNS topic for alerts..." -ForegroundColor Yellow
$snsTopicName = "insighthr-canary-alerts"

$topics = aws sns list-topics --region $region | ConvertFrom-Json
$topicExists = $topics.Topics | Where-Object { $_.TopicArn -like "*$snsTopicName*" }

if (-not $topicExists) {
    Write-Host "Creating SNS topic: $snsTopicName" -ForegroundColor Cyan
    $topicArn = (aws sns create-topic --name $snsTopicName --region $region | ConvertFrom-Json).TopicArn
    Write-Host "SNS topic created: $topicArn" -ForegroundColor Green
} else {
    $topicArn = $topicExists.TopicArn
    Write-Host "SNS topic already exists: $topicArn" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Infrastructure Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created resources:" -ForegroundColor Yellow
Write-Host "  S3 Bucket: $bucketName" -ForegroundColor White
Write-Host "  IAM Role: $roleName" -ForegroundColor White
Write-Host "  SNS Topic: $snsTopicName" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy canaries in AWS Console (see README.md)" -ForegroundColor White
Write-Host "2. Run .\create-alarms.ps1" -ForegroundColor White
Write-Host "3. Run .\create-dashboard.ps1" -ForegroundColor White
Write-Host "4. Run .\create-contributor-insights.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Or follow QUICK_START.md for detailed instructions" -ForegroundColor Cyan
