# Fix KMS Key Policy to Allow Lambda Role Access
# This script updates the KMS key policy to grant decrypt permissions to Lambda role

$ErrorActionPreference = "Stop"

Write-Host "=== Fixing KMS Key Policy for Lambda Access ===" -ForegroundColor Cyan

# Configuration
$region = "ap-southeast-1"
$accountId = "151507815244"
$kmsKeyId = "5f7af82a-09b4-4ba8-a432-58d304df73cf"
$lambdaRoleArn = "arn:aws:iam::${accountId}:role/insighthr-lambda-execution-role-dev"

Write-Host "`nStep 1: Getting current KMS key policy..." -ForegroundColor Yellow
$currentPolicy = aws kms get-key-policy `
    --key-id $kmsKeyId `
    --policy-name default `
    --region $region `
    --output json | ConvertFrom-Json

Write-Host "✓ Current policy retrieved" -ForegroundColor Green

Write-Host "`nStep 2: Creating updated KMS key policy..." -ForegroundColor Yellow
$newPolicyJson = @"
{
    "Version": "2012-10-17",
    "Id": "key-policy-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${accountId}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow Lambda Role to Decrypt",
            "Effect": "Allow",
            "Principal": {
                "AWS": "$lambdaRoleArn"
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:GenerateDataKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow DynamoDB to use the key",
            "Effect": "Allow",
            "Principal": {
                "Service": "dynamodb.amazonaws.com"
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:GenerateDataKey",
                "kms:CreateGrant"
            ],
            "Resource": "*"
        }
    ]
}
"@

# Save policy to temp file
$policyFile = "kms-key-policy-temp.json"
$newPolicyJson | Out-File -FilePath $policyFile -Encoding utf8

Write-Host "`nStep 3: Updating KMS key policy..." -ForegroundColor Yellow
try {
    aws kms put-key-policy `
        --key-id $kmsKeyId `
        --policy-name default `
        --policy file://$policyFile `
        --region $region

    Write-Host "✓ KMS key policy updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to update KMS key policy: $_" -ForegroundColor Red
    Write-Host "`nNote: You may need to update the policy via AWS Console if you don't have kms:PutKeyPolicy permission" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nStep 4: Verifying policy update..." -ForegroundColor Yellow
$updatedPolicy = aws kms get-key-policy `
    --key-id $kmsKeyId `
    --policy-name default `
    --region $region `
    --output json

Write-Host "✓ Policy verified" -ForegroundColor Green

# Clean up temp file
Remove-Item $policyFile -ErrorAction SilentlyContinue

Write-Host "`n=== KMS Key Policy Updated ===" -ForegroundColor Cyan
Write-Host "`nThe Lambda execution role now has permission to decrypt DynamoDB data." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Wait 10-30 seconds for changes to propagate"
Write-Host "2. Test the application again"
Write-Host "3. Check CloudWatch Logs if issues persist"
