# Create Admin User in Cognito
# This script creates a backdoor admin account for testing

$USER_POOL_ID = "ap-southeast-1_rzDtdAhvp"
$REGION = "ap-southeast-1"
$ADMIN_EMAIL = "admin@insighthr.com"
$ADMIN_PASSWORD = "Admin1234!"
$ADMIN_NAME = "Admin User"

Write-Host "========================================"
Write-Host "Creating Admin User in Cognito"
Write-Host "========================================"
Write-Host ""

# Create user
Write-Host "Creating user: $ADMIN_EMAIL"
try {
    aws cognito-idp admin-create-user `
        --user-pool-id $USER_POOL_ID `
        --username $ADMIN_EMAIL `
        --user-attributes Name=email,Value=$ADMIN_EMAIL Name=name,Value="$ADMIN_NAME" Name=email_verified,Value=true `
        --temporary-password $ADMIN_PASSWORD `
        --message-action SUPPRESS `
        --region $REGION
    
    Write-Host "User created successfully"
} catch {
    Write-Host "Error creating user: $_"
    exit 1
}

Write-Host ""

# Set permanent password
Write-Host "Setting permanent password..."
try {
    aws cognito-idp admin-set-user-password `
        --user-pool-id $USER_POOL_ID `
        --username $ADMIN_EMAIL `
        --password $ADMIN_PASSWORD `
        --permanent `
        --region $REGION
    
    Write-Host "Password set successfully"
} catch {
    Write-Host "Error setting password: $_"
    exit 1
}

Write-Host ""

# Add user to DynamoDB
Write-Host "Adding user to DynamoDB..."

# Get user sub from Cognito
$cognitoUser = aws cognito-idp admin-get-user `
    --user-pool-id $USER_POOL_ID `
    --username $ADMIN_EMAIL `
    --region $REGION | ConvertFrom-Json

$userSub = $cognitoUser.Username

$dynamoItem = @{
    userId = @{ S = $userSub }
    email = @{ S = $ADMIN_EMAIL }
    name = @{ S = $ADMIN_NAME }
    role = @{ S = "Admin" }
    employeeId = @{ S = "EMP001" }
    department = @{ S = "IT" }
    isActive = @{ BOOL = $true }
    createdAt = @{ S = (Get-Date -Format "o") }
    updatedAt = @{ S = (Get-Date -Format "o") }
} | ConvertTo-Json -Compress

try {
    aws dynamodb put-item `
        --table-name insighthr-users-dev `
        --item $dynamoItem `
        --region $REGION
    
    Write-Host "User added to DynamoDB"
} catch {
    Write-Host "Error adding user to DynamoDB: $_"
}

Write-Host ""
Write-Host "========================================"
Write-Host "Admin User Created Successfully!"
Write-Host "========================================"
Write-Host ""
Write-Host "Credentials:"
Write-Host "  Email: $ADMIN_EMAIL"
Write-Host "  Password: $ADMIN_PASSWORD"
Write-Host "  Role: Admin"
Write-Host ""
