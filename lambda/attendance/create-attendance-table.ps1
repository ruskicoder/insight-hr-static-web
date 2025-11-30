# Create insighthr-attendance-history-dev table with proper schema
# PK: employeeId, SK: date
# GSI-1: date-index for daily queries
# GSI-2: department-date-index for manager queries

$tableName = "insighthr-attendance-history-dev"
$region = "ap-southeast-1"

Write-Host "Creating DynamoDB table: $tableName in region: $region" -ForegroundColor Cyan

# Create table with GSIs
aws dynamodb create-table `
    --table-name $tableName `
    --attribute-definitions `
        AttributeName=employeeId,AttributeType=S `
        AttributeName=date,AttributeType=S `
        AttributeName=department,AttributeType=S `
    --key-schema `
        AttributeName=employeeId,KeyType=HASH `
        AttributeName=date,KeyType=RANGE `
    --billing-mode PAY_PER_REQUEST `
    --global-secondary-indexes file://lambda/attendance/gsi-config.json `
    --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Table created successfully!" -ForegroundColor Green
    Write-Host "Waiting for table to become ACTIVE..." -ForegroundColor Yellow
    
    aws dynamodb wait table-exists --table-name $tableName --region $region
    
    Write-Host "✓ Table is now ACTIVE" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create table" -ForegroundColor Red
}
