# Workaround script to create Synthetics role
# This uses AWS Console instructions since CLI is blocked by PowerUser policy

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudWatch Synthetics Role Creation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The PowerUser policy is blocking iam:CreateRole via CLI." -ForegroundColor Yellow
Write-Host "You need to create the role manually in AWS Console." -ForegroundColor Yellow
Write-Host ""
Write-Host "Follow these steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to IAM Console:" -ForegroundColor White
Write-Host "   https://console.aws.amazon.com/iam/home?region=ap-southeast-1#/roles" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Click 'Create role'" -ForegroundColor White
Write-Host ""
Write-Host "3. Select 'AWS service' -> 'Lambda' -> Next" -ForegroundColor White
Write-Host ""
Write-Host "4. Search and attach these policies:" -ForegroundColor White
Write-Host "   - CloudWatchSyntheticsFullAccess" -ForegroundColor Gray
Write-Host "   - AmazonS3FullAccess" -ForegroundColor Gray
Write-Host "   - CloudWatchLogsFullAccess" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Click Next" -ForegroundColor White
Write-Host ""
Write-Host "6. Role name: CloudWatchSyntheticsRole-InsightHR" -ForegroundColor White
Write-Host ""
Write-Host "7. Click 'Create role'" -ForegroundColor White
Write-Host ""
Write-Host "8. Find the role, click on it, go to 'Trust relationships' tab" -ForegroundColor White
Write-Host ""
Write-Host "9. Click 'Edit trust policy' and replace with:" -ForegroundColor White
Write-Host ""
Write-Host @'
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
'@ -ForegroundColor Gray
Write-Host ""
Write-Host "10. Click 'Update policy'" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "After creating the role, run:" -ForegroundColor Yellow
Write-Host "  .\deploy-canaries.ps1" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
