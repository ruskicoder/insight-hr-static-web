# Check user role in DynamoDB Users table
# This script helps debug 403 errors by verifying user roles

param(
    [Parameter(Mandatory=$false)]
    [string]$Email = ""
)

$TABLE_NAME = "insighthr-users-dev"
$REGION = "ap-southeast-1"

Write-Host "Checking User Roles in DynamoDB" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

if ($Email -eq "") {
    Write-Host "Listing all users with their roles:" -ForegroundColor Yellow
    Write-Host ""
    
    # Scan all users
    $result = aws dynamodb scan `
        --table-name $TABLE_NAME `
        --projection-expression "userId,email,#n,#r" `
        --expression-attribute-names '{\"#n\":\"name\",\"#r\":\"role\"}' `
        --region $REGION | ConvertFrom-Json
    
    if ($result.Items.Count -eq 0) {
        Write-Host "No users found in the table" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found $($result.Items.Count) users:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($item in $result.Items) {
        $userId = $item.userId.S
        $userEmail = $item.email.S
        $userName = $item.name.S
        $userRole = $item.role.S
        
        $roleColor = switch ($userRole) {
            "Admin" { "Red" }
            "Manager" { "Yellow" }
            "Employee" { "Green" }
            default { "White" }
        }
        
        Write-Host "  Email: $userEmail" -ForegroundColor White
        Write-Host "  Name: $userName" -ForegroundColor White
        Write-Host "  Role: $userRole" -ForegroundColor $roleColor
        Write-Host "  User ID: $userId" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Count by role
    $adminCount = ($result.Items | Where-Object { $_.role.S -eq "Admin" }).Count
    $managerCount = ($result.Items | Where-Object { $_.role.S -eq "Manager" }).Count
    $employeeCount = ($result.Items | Where-Object { $_.role.S -eq "Employee" }).Count
    
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Admins: $adminCount" -ForegroundColor Red
    Write-Host "  Managers: $managerCount" -ForegroundColor Yellow
    Write-Host "  Employees: $employeeCount" -ForegroundColor Green
    
} else {
    Write-Host "Looking up user: $Email" -ForegroundColor Yellow
    Write-Host ""
    
    # Query by email using GSI
    $result = aws dynamodb query `
        --table-name $TABLE_NAME `
        --index-name email-index `
        --key-condition-expression "email = :email" `
        --expression-attribute-values "{\":email\":{\"S\":\"$Email\"}}" `
        --region $REGION | ConvertFrom-Json
    
    if ($result.Items.Count -eq 0) {
        Write-Host "User not found with email: $Email" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. User hasn't registered yet" -ForegroundColor White
        Write-Host "  2. Email address is incorrect" -ForegroundColor White
        Write-Host "  3. User was created in Cognito but not in Users table" -ForegroundColor White
        exit 1
    }
    
    $item = $result.Items[0]
    $userId = $item.userId.S
    $userEmail = $item.email.S
    $userName = $item.name.S
    $userRole = $item.role.S
    $employeeId = if ($item.employeeId) { $item.employeeId.S } else { "N/A" }
    $department = if ($item.department) { $item.department.S } else { "N/A" }
    
    $roleColor = switch ($userRole) {
        "Admin" { "Red" }
        "Manager" { "Yellow" }
        "Employee" { "Green" }
        default { "White" }
    }
    
    Write-Host "User found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Email: $userEmail" -ForegroundColor White
    Write-Host "  Name: $userName" -ForegroundColor White
    Write-Host "  Role: $userRole" -ForegroundColor $roleColor
    Write-Host "  User ID: $userId" -ForegroundColor Gray
    Write-Host "  Employee ID: $employeeId" -ForegroundColor Gray
    Write-Host "  Department: $department" -ForegroundColor Gray
    Write-Host ""
    
    if ($userRole -eq "Admin") {
        Write-Host "[OK] This user has Admin privileges" -ForegroundColor Green
        Write-Host "  Can create and update performance scores for all departments" -ForegroundColor Green
    } elseif ($userRole -eq "Manager") {
        Write-Host "[MANAGER] This user has Manager privileges" -ForegroundColor Yellow
        Write-Host "  Can create and update performance scores for their department only" -ForegroundColor Yellow
    } else {
        Write-Host "[EMPLOYEE] This user has Employee privileges" -ForegroundColor Red
        Write-Host "  Cannot create or update performance scores" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "To update a user role to Admin:" -ForegroundColor Cyan
Write-Host "  See DEBUG-PERFORMANCE-SCORE-403.md for instructions" -ForegroundColor White
