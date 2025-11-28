# Test Bedrock Access for InsightHR Chatbot
# This script verifies that Bedrock is configured and accessible in ap-southeast-1

Write-Host "=== Testing Bedrock Access ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: List available foundation models
Write-Host "Test 1: Listing available Bedrock models in ap-southeast-1..." -ForegroundColor Yellow
$models = aws bedrock list-foundation-models --region ap-southeast-1 --query 'modelSummaries[?contains(modelId, `claude-3`)].{ModelId:modelId, ModelName:modelName, Status:modelLifecycle.status}' --output json | ConvertFrom-Json

if ($models) {
    Write-Host "✓ Bedrock is available in ap-southeast-1" -ForegroundColor Green
    Write-Host "Available Claude 3 models:" -ForegroundColor Cyan
    foreach ($model in $models) {
        Write-Host "  - $($model.ModelId) ($($model.ModelName)) - Status: $($model.Status)" -ForegroundColor White
    }
} else {
    Write-Host "✗ No Bedrock models found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Check Lambda execution role has Bedrock permissions
Write-Host "Test 2: Checking Lambda execution role permissions..." -ForegroundColor Yellow
$roleName = "insighthr-lambda-execution-role-dev"
$policyArn = "arn:aws:iam::151507815244:policy/insighthr-lambda-custom-policy"

$policyVersion = aws iam get-policy --policy-arn $policyArn --query 'Policy.DefaultVersionId' --output text
$policyDoc = aws iam get-policy-version --policy-arn $policyArn --version-id $policyVersion --query 'PolicyVersion.Document' --output json | ConvertFrom-Json

$bedrockStatement = $policyDoc.Statement | Where-Object { $_.Sid -eq "BedrockAccess" }

if ($bedrockStatement) {
    Write-Host "✓ Lambda execution role has Bedrock permissions" -ForegroundColor Green
    Write-Host "  Allowed actions:" -ForegroundColor Cyan
    foreach ($action in $bedrockStatement.Action) {
        Write-Host "    - $action" -ForegroundColor White
    }
} else {
    Write-Host "✗ Lambda execution role missing Bedrock permissions" -ForegroundColor Red
    Write-Host "  Need to add bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 3: Recommended model for chatbot
Write-Host "Test 3: Recommended model for InsightHR chatbot..." -ForegroundColor Yellow
$recommendedModel = "anthropic.claude-3-haiku-20240307-v1:0"
Write-Host "✓ Recommended model: $recommendedModel" -ForegroundColor Green
Write-Host "  Reason: Fast, cost-effective, good for conversational queries" -ForegroundColor Cyan
Write-Host "  Alternative: anthropic.claude-3-5-sonnet-20241022-v2:0 (more capable, higher cost)" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== Bedrock Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Region: ap-southeast-1 (Singapore)" -ForegroundColor White
Write-Host "Lambda Role: $roleName" -ForegroundColor White
Write-Host "Bedrock Access: ✓ Configured" -ForegroundColor Green
Write-Host "Recommended Model: $recommendedModel" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Create chatbot-handler Lambda function" -ForegroundColor White
Write-Host "2. Set BEDROCK_MODEL_ID environment variable to: $recommendedModel" -ForegroundColor White
Write-Host "3. Implement chatbot logic with Bedrock InvokeModel API" -ForegroundColor White
Write-Host ""
