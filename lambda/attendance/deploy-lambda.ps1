# Deploy attendance-handler Lambda function

$functionName = "insighthr-attendance-handler"
$region = "ap-southeast-1"
$roleArn = "arn:aws:iam::151507815244:role/insighthr-lambda-execution-role-dev"

Write-Host "Deploying $functionName Lambda function..." -ForegroundColor Cyan

# Check if function exists
$functionExists = aws lambda get-function --function-name $functionName --region $region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Function exists. Updating code..." -ForegroundColor Yellow
    
    # Update function code
    aws lambda update-function-code `
        --function-name $functionName `
        --zip-file fileb://lambda/attendance/attendance_handler.zip `
        --region $region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Function code updated successfully!" -ForegroundColor Green
        
        # Update environment variables
        Write-Host "Updating environment variables..." -ForegroundColor Yellow
        $envVars = 'Variables={ATTENDANCE_TABLE=insighthr-attendance-history-dev,EMPLOYEES_TABLE=insighthr-employees-dev,USERS_TABLE=insighthr-users-dev}'
        aws lambda update-function-configuration `
            --function-name $functionName `
            --environment $envVars `
            --region $region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Environment variables updated!" -ForegroundColor Green
        }
    } else {
        Write-Host "Failed to update function code" -ForegroundColor Red
    }
} else {
    Write-Host "Function does not exist. Creating new function..." -ForegroundColor Yellow
    
    # Create function
    $envVars = 'Variables={ATTENDANCE_TABLE=insighthr-attendance-history-dev,EMPLOYEES_TABLE=insighthr-employees-dev,USERS_TABLE=insighthr-users-dev}'
    aws lambda create-function `
        --function-name $functionName `
        --runtime python3.11 `
        --role $roleArn `
        --handler attendance_handler.lambda_handler `
        --zip-file fileb://lambda/attendance/attendance_handler.zip `
        --timeout 30 `
        --memory-size 256 `
        --environment $envVars `
        --region $region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Function created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create function" -ForegroundColor Red
    }
}

Write-Host "Deployment complete!" -ForegroundColor Cyan
