# Fix KMS Permissions for Lambda Execution Role
# This script adds KMS decrypt permissions to the Lambda execution role

$ErrorActionPreference = "Stop"

Write-Host "=== Fixing KMS Permissions for Lambda Execution Role ===" -ForegroundColor Cyan

# Configuration
$region = "ap-southeast-1"
$roleName = "insighthr-lambda-execution-role-dev"
$kmsKeyId = "5f7af82a-09b4-4ba8-a432-58d304df73cf"

Write-Host "`nStep 1: Getting KMS key ARN..." -ForegroundColor Yellow
$kmsKeyArn = "arn:aws:kms:${region}:151507815244:key/${kmsKeyId}"
Write-Host "KMS Key ARN: $kmsKeyArn" -ForegroundColor Green

Write-Host "`nStep 2: Creating KMS policy document..." -ForegroundColor Yellow
$kmsPolicyJson = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:GenerateDataKey"
            ],
            "Resource": "$kmsKeyArn"
        }
    ]
}
"@

# Save policy to temp file
$policyFile = "kms-policy-temp.json"
$kmsPolicyJson | Out-File -FilePath $policyFile -Encoding utf8

Write-Host "`nStep 3: Attaching KMS policy to Lambda execution role..." -ForegroundColor Yellow
try {
    aws iam put-role-policy `
        --role-name $roleName `
        --policy-name "KMSDecryptPolicy" `
        --policy-document file://$policyFile `
        --region $region

    Write-Host "✓ KMS policy attached successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to attach KMS policy: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nStep 4: Verifying policy attachment..." -ForegroundColor Yellow
$policies = aws iam list-role-policies --role-name $roleName --region $region | ConvertFrom-Json
if ($policies.PolicyNames -contains "KMSDecryptPolicy") {
    Write-Host "✓ KMSDecryptPolicy is attached to role" -ForegroundColor Green
} else {
    Write-Host "✗ Policy not found in role" -ForegroundColor Red
}

# Clean up temp file
Remove-Item $policyFile -ErrorAction SilentlyContinue

Write-Host "`n=== KMS Permissions Fixed ===" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Wait 10-30 seconds for IAM changes to propagate"
Write-Host "2. Test the application again"
Write-Host "3. If still failing, check CloudWatch Logs for other errors"

Write-Host "`nTo test immediately, run:" -ForegroundColor Cyan
Write-Host "aws dynamodb scan --table-name insighthr-performance-scores-dev --limit 1 --region ap-southeast-1" -ForegroundColor White
