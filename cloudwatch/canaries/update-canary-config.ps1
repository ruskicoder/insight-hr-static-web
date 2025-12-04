# Update canary with environment variables
param(
    [Parameter(Mandatory=$true)]
    [string]$CanaryName
)

$ErrorActionPreference = "Stop"
$region = "ap-southeast-1"

Write-Host "Updating canary: $CanaryName" -ForegroundColor Cyan

# Configuration from aws-secret.md
$cloudfrontUrl = "https://d2z6tht6rq32uy.cloudfront.net"
$apiGatewayUrl = "https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev"

# Create run config with environment variables
$runConfigJson = @"
{
  "TimeoutInSeconds": 300,
  "MemoryInMB": 960,
  "EnvironmentVariables": {
    "CLOUDFRONT_URL": "$cloudfrontUrl",
    "API_GATEWAY_URL": "$apiGatewayUrl",
    "TEST_USER_EMAIL": "admin@insighthr.com",
    "TEST_USER_PASSWORD": "InsightHR2024!"
  }
}
"@

$runConfigFile = "run-config-$CanaryName.json"
$runConfigJson | Out-File -FilePath $runConfigFile -Encoding ASCII -NoNewline

# Update canary
aws synthetics update-canary --name $CanaryName --run-config "file://$runConfigFile" --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Updated: $CanaryName" -ForegroundColor Green
} else {
    Write-Host "Failed: $CanaryName" -ForegroundColor Red
}

Remove-Item $runConfigFile -ErrorAction SilentlyContinue
