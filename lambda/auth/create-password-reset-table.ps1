# Create PasswordResetRequests DynamoDB table
# Run this script from the lambda/auth directory

$TABLE_NAME = "PasswordResetRequests"
$REGION = "ap-southeast-1"

Write-Host "Creating PasswordResetRequests DynamoDB table..." -ForegroundColor Cyan

# Check if table already exists
$tableExists = aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION 2>$null

if ($tableExists) {
    Write-Host "Table $TABLE_NAME already exists!" -ForegroundColor Yellow
    exit 0
}

# Create table with GSIs
aws dynamodb create-table `
    --table-name $TABLE_NAME `
    --attribute-definitions `
        AttributeName=requestId,AttributeType=S `
        AttributeName=userId,AttributeType=S `
        AttributeName=status,AttributeType=S `
    --key-schema `
        AttributeName=requestId,KeyType=HASH `
    --global-secondary-indexes file://gsi-config.json `
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 `
    --region $REGION

if ($LASTEXITCODE -eq 0) {
    Write-Host "Table $TABLE_NAME created successfully!" -ForegroundColor Green
    Write-Host "Waiting for table to become active..." -ForegroundColor Cyan
    
    aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION
    
    Write-Host "Table is now active!" -ForegroundColor Green
} else {
    Write-Host "Failed to create table!" -ForegroundColor Red
    exit 1
}
