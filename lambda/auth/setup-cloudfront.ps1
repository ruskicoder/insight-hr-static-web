# Setup CloudFront Distribution for InsightHR Web App
# This script creates a CloudFront distribution for the S3 website bucket
# to provide HTTPS access and cleaner URLs

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudFront Distribution Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$region = "ap-southeast-1"
$s3WebsiteEndpoint = "insighthr-web-app-sg.s3-website-ap-southeast-1.amazonaws.com"
$s3BucketName = "insighthr-web-app-sg"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Region: $region"
Write-Host "  S3 Website Endpoint: $s3WebsiteEndpoint"
Write-Host ""

# Check if CloudFront distribution already exists
Write-Host "Checking for existing CloudFront distributions..." -ForegroundColor Yellow
$existingDistributions = aws cloudfront list-distributions --region $region --query "DistributionList.Items[?Origins.Items[?DomainName=='$s3WebsiteEndpoint']].{Id:Id,DomainName:DomainName,Status:Status}" --output json | ConvertFrom-Json

if ($existingDistributions -and $existingDistributions.Count -gt 0) {
    Write-Host "Found existing CloudFront distribution:" -ForegroundColor Green
    $distributionId = $existingDistributions[0].Id
    $distributionDomain = $existingDistributions[0].DomainName
    $distributionStatus = $existingDistributions[0].Status
    Write-Host "  Distribution ID: $distributionId"
    Write-Host "  Domain: $distributionDomain"
    Write-Host "  Status: $distributionStatus"
    Write-Host ""
    
    if ($distributionStatus -eq "Deployed") {
        Write-Host "CloudFront distribution is already deployed and ready!" -ForegroundColor Green
        Write-Host "HTTPS URL: https://$distributionDomain" -ForegroundColor Cyan
        Write-Host ""
        
        # Update aws-secret.md
        Write-Host "Updating aws-secret.md with CloudFront details..." -ForegroundColor Yellow
        $secretFile = "aws-secret.md"
        $content = Get-Content $secretFile -Raw
        
        # Check if CloudFront section exists
        if ($content -match "## CloudFront") {
            Write-Host "CloudFront section already exists in aws-secret.md" -ForegroundColor Green
        } else {
            # Add CloudFront section after S3 section
            $cloudFrontSection = @"

## CloudFront
CLOUDFRONT_DISTRIBUTION_ID=$distributionId
CLOUDFRONT_DOMAIN=$distributionDomain
CLOUDFRONT_URL=https://$distributionDomain
CLOUDFRONT_STATUS=$distributionStatus
CLOUDFRONT_CREATED_DATE=$(Get-Date -Format "yyyy-MM-dd")
"@
            $content = $content -replace "(## Deployment)", "$cloudFrontSection`n`n`$1"
            Set-Content -Path $secretFile -Value $content -NoNewline
            Write-Host "Updated aws-secret.md with CloudFront details" -ForegroundColor Green
        }
        
        exit 0
    } else {
        Write-Host "CloudFront distribution exists but is still deploying..." -ForegroundColor Yellow
        Write-Host "Status: $distributionStatus" -ForegroundColor Yellow
        Write-Host "Please wait for deployment to complete (this can take 15-20 minutes)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can check the status with:" -ForegroundColor Cyan
        Write-Host "  aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status'" -ForegroundColor Cyan
        exit 0
    }
}

Write-Host "No existing CloudFront distribution found. Creating new distribution..." -ForegroundColor Yellow
Write-Host ""

# Create CloudFront distribution configuration as JSON string
$callerRef = "insighthr-web-$(Get-Date -Format 'yyyyMMddHHmmss')"
$tempFile = Join-Path $PSScriptRoot "cloudfront-config.json"

# Write JSON configuration directly
$configJson = @"
{
  "CallerReference": "$callerRef",
  "Comment": "InsightHR Web App - Static Website Distribution",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-insighthr-web-app",
        "DomainName": "$s3WebsiteEndpoint",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-insighthr-web-app",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    }
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "PriceClass": "PriceClass_All",
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
"@

# Save to temporary file
[System.IO.File]::WriteAllText($tempFile, $configJson)

Write-Host "Creating CloudFront distribution..." -ForegroundColor Yellow
Write-Host "This may take 15-20 minutes to deploy globally..." -ForegroundColor Yellow
Write-Host ""

try {
    # Create distribution
    $result = aws cloudfront create-distribution --distribution-config file://$tempFile --region $region --output json | ConvertFrom-Json
    
    $distributionId = $result.Distribution.Id
    $distributionDomain = $result.Distribution.DomainName
    $distributionStatus = $result.Distribution.Status
    
    Write-Host "CloudFront distribution created successfully!" -ForegroundColor Green
    Write-Host "  Distribution ID: $distributionId" -ForegroundColor Cyan
    Write-Host "  Domain: $distributionDomain" -ForegroundColor Cyan
    Write-Host "  Status: $distributionStatus" -ForegroundColor Yellow
    Write-Host "  HTTPS URL: https://$distributionDomain" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Note: The distribution is being deployed globally." -ForegroundColor Yellow
    Write-Host "This process typically takes 15-20 minutes." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can check the deployment status with:" -ForegroundColor Cyan
    Write-Host "  aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status'" -ForegroundColor Cyan
    Write-Host ""
    
    # Update aws-secret.md
    Write-Host "Updating aws-secret.md with CloudFront details..." -ForegroundColor Yellow
    $secretFile = "aws-secret.md"
    $content = Get-Content $secretFile -Raw
    
    # Add CloudFront section after S3 section
    $cloudFrontSection = @"

## CloudFront
CLOUDFRONT_DISTRIBUTION_ID=$distributionId
CLOUDFRONT_DOMAIN=$distributionDomain
CLOUDFRONT_URL=https://$distributionDomain
CLOUDFRONT_STATUS=$distributionStatus
CLOUDFRONT_CREATED_DATE=$(Get-Date -Format "yyyy-MM-dd")
"@
    $content = $content -replace "(## Deployment)", "$cloudFrontSection`n`n`$1"
    Set-Content -Path $secretFile -Value $content -NoNewline
    Write-Host "Updated aws-secret.md with CloudFront details" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "CloudFront Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Wait for distribution to deploy (Status: Deployed)" -ForegroundColor White
    Write-Host "2. Test HTTPS access: https://$distributionDomain" -ForegroundColor White
    Write-Host "3. Update API Gateway CORS to allow CloudFront domain" -ForegroundColor White
    Write-Host "4. Update frontend .env with CloudFront URL" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "Error creating CloudFront distribution: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile
    }
}
