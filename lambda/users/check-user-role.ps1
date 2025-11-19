# Script to check a user's role in DynamoDB
# Usage: .\check-user-role.ps1 -Email "your-email@example.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$Email
)

$region = "ap-southeast-1"
$tableName = "insighthr-users-dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking User Role" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Query user by email using GSI
Write-Host "Looking up user with email: $Email" -ForegroundColor Yellow
$queryResult = aws dynamodb query `
    --table-name $tableName `
    --index-name email-index `
    --key-condition-expression "email = :email" `
    --expression-attribute-values "{\":email\":{\"S\":\"$Email\"}}" `
    --region $region | ConvertFrom-Json

if ($queryResult.Count -eq 0) {
    Write-Host "ERROR: User not found with email: $Email" -ForegroundColor Red
    Write-Host "The user may not have logged in yet." -ForegroundColor Yellow
    exit 1
}

$user = $queryResult.Items[0]

Write-Host "User Details:" -ForegroundColor Green
Write-Host "  User ID: $($user.userId.S)"
Write-Host "  Email: $($user.email.S)"
Write-Host "  Name: $($user.name.S)"
Write-Host "  Role: $($user.role.S)" -ForegroundColor Cyan
Write-Host "  Active: $($user.isActive.BOOL)"
Write-Host "  Created: $($user.createdAt.S)"
Write-Host "  Updated: $($user.updatedAt.S)"

if ($user.department) {
    Write-Host "  Department: $($user.department.S)"
}
if ($user.employeeId) {
    Write-Host "  Employee ID: $($user.employeeId.S)"
}

Write-Host ""
