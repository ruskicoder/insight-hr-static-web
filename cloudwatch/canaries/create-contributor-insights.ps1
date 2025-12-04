# Create CloudWatch Logs Insights Queries
Write-Host "CloudWatch Contributor Insights Setup" -ForegroundColor Cyan
Write-Host ""
Write-Host "Contributor Insights rules must be created manually in AWS Console." -ForegroundColor Yellow
Write-Host ""
Write-Host "Use these CloudWatch Logs Insights queries:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Error Analysis Query:" -ForegroundColor Yellow
Write-Host @'
fields @timestamp, @message, @logStream
| filter @message like /ERROR/ or @message like /Exception/
| stats count() by @logStream
| sort count desc
| limit 10
'@ -ForegroundColor Gray
Write-Host ""
Write-Host "View Logs Insights:" -ForegroundColor Cyan
Write-Host "https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#logsV2:logs-insights" -ForegroundColor Gray
