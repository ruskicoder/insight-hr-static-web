# Create CloudWatch Alarms for Canaries
$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "Creating CloudWatch Alarms..." -ForegroundColor Cyan

# Get SNS topic
$topicArn = "arn:aws:sns:ap-southeast-1:151507815244:insighthr-canary-alerts"

# Create alarms for each canary
$canaries = @("insighthr-login-canary", "insighthr-dashboard-canary", "insighthr-autoscoring-canary", "insighthr-chatbot-canary")

foreach ($canaryName in $canaries) {
    $alarmName = "$canaryName-alarm"
    Write-Host "Creating alarm: $alarmName" -ForegroundColor Yellow
    
    aws cloudwatch put-metric-alarm `
        --alarm-name $alarmName `
        --alarm-description "Alert when $canaryName fails" `
        --metric-name SuccessPercent `
        --namespace CloudWatchSynthetics `
        --statistic Average `
        --period 300 `
        --evaluation-periods 2 `
        --threshold 100 `
        --comparison-operator LessThanThreshold `
        --dimensions "Name=CanaryName,Value=$canaryName" `
        --alarm-actions $topicArn `
        --treat-missing-data notBreaching `
        --region $region
    
    Write-Host "  Created" -ForegroundColor Green
}

Write-Host ""
Write-Host "All alarms created!" -ForegroundColor Green
Write-Host "Subscribe to alerts:" -ForegroundColor Yellow
Write-Host "aws sns subscribe --topic-arn $topicArn --protocol email --notification-endpoint your-email@example.com --region $region" -ForegroundColor Gray
