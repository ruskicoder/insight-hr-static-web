# Create Employees DynamoDB table in ap-southeast-1

$AWS_REGION = "ap-southeast-1"
$TABLE_NAME = "Employees"

Write-Host "Creating DynamoDB table: $TABLE_NAME in region $AWS_REGION"

aws dynamodb create-table `
    --table-name $TABLE_NAME `
    --attribute-definitions `
        AttributeName=employeeId,AttributeType=S `
        AttributeName=department,AttributeType=S `
    --key-schema `
        AttributeName=employeeId,KeyType=HASH `
    --global-secondary-indexes `
        "IndexName=department-index,KeySchema=[{AttributeName=department,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}" `
    --provisioned-throughput `
        ReadCapacityUnits=5,WriteCapacityUnits=5 `
    --region $AWS_REGION

Write-Host "`nWaiting for table to become active..."
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $AWS_REGION

Write-Host "`n✓ Table $TABLE_NAME created successfully"
