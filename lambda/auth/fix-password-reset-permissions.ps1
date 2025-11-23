# Fix IAM permissions for password reset handler
# Run this script from the lambda/auth directory

$ROLE_NAME = "insighthr-lambda-execution-role-dev"
$REGION = "ap-southeast-1"
$ACCOUNT_ID = "151507815244"

Write-Host "Adding DynamoDB permissions for PasswordResetRequests table..." -ForegroundColor Cyan

# Create policy document
$policyDocument = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/PasswordResetRequests",
                "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/PasswordResetRequests/index/*"
            ]
        }
    ]
}
"@

# Save policy to temp file
$policyDocument | Out-File -FilePath "password-reset-policy.json" -Encoding utf8

Write-Host "Policy document created" -ForegroundColor Green

# Put inline policy
Write-Host "Attaching policy to role..." -ForegroundColor Cyan
aws iam put-role-policy `
    --role-name $ROLE_NAME `
    --policy-name "PasswordResetDynamoDBAccess" `
    --policy-document file://password-reset-policy.json

if ($LASTEXITCODE -eq 0) {
    Write-Host "Policy attached successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to attach policy" -ForegroundColor Red
    exit 1
}

# Clean up temp file
Remove-Item "password-reset-policy.json"

Write-Host "`nPermissions updated successfully!" -ForegroundColor Green
Write-Host "The Lambda function can now access the PasswordResetRequests table" -ForegroundColor Cyan
