# Create CloudWatch Dashboard
$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "Creating CloudWatch Dashboard..." -ForegroundColor Cyan

$dashboardName = "InsightHR-Monitoring"

# Simple dashboard with canary metrics
$dashboardBody = '{"widgets":[{"type":"metric","properties":{"metrics":[["CloudWatchSynthetics","SuccessPercent"]],"view":"timeSeries","region":"ap-southeast-1","title":"Canary Success Rate"}}]}'

aws cloudwatch put-dashboard `
    --dashboard-name $dashboardName `
    --dashboard-body $dashboardBody `
    --region $region

Write-Host "Dashboard created: $dashboardName" -ForegroundColor Green
Write-Host "View at: https://console.aws.amazon.com/cloudwatch/home?region=$region" -ForegroundColor Cyan
