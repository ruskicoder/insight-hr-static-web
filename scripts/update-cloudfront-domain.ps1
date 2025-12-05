# Update CloudFront Distribution with Custom Domain
# This script adds the custom domain to your CloudFront distribution

# Configuration
$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update CloudFront with Custom Domain" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get CloudFront distribution
Write-Host "Step 1: Getting CloudFront distribution..." -ForegroundColor Yellow
$distributions = aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$CLOUDFRONT_DOMAIN']" --output json | ConvertFrom-Json

if ($distributions.Count -eq 0) {
    Write-Host "✗ CloudFront distribution not found: $CLOUDFRONT_DOMAIN" -ForegroundColor Red
    exit 1
}

$DISTRIBUTION_ID = $distributions[0].Id
Write-Host "✓ Distribution found: $DISTRIBUTION_ID" -ForegroundColor Green

# Step 2: Get current distribution config
Write-Host ""
Write-Host "Step 2: Getting current distribution configuration..." -ForegroundColor Yellow
$configResult = aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --output json | ConvertFrom-Json
$config = $configResult.DistributionConfig
$etag = $configResult.ETag

Write-Host "✓ Current configuration retrieved" -ForegroundColor Green

# Step 3: Check certificate status
Write-Host ""
Write-Host "Step 3: Checking ACM certificate status..." -ForegroundColor Yellow
$certs = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME']" --output json | ConvertFrom-Json

if ($certs.Count -eq 0) {
    Write-Host "✗ No certificate found for $DOMAIN_NAME" -ForegroundColor Red
    Write-Host "Please run setup-route53-domain.ps1 first" -ForegroundColor Yellow
    exit 1
}

$CERTIFICATE_ARN = $certs[0].CertificateArn
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json
$certStatus = $certDetails.Certificate.Status

Write-Host "Certificate ARN: $CERTIFICATE_ARN" -ForegroundColor Cyan
Write-Host "Certificate Status: $certStatus" -ForegroundColor Cyan

if ($certStatus -ne "ISSUED") {
    Write-Host ""
    Write-Host "✗ Certificate is not yet issued (Status: $certStatus)" -ForegroundColor Red
    Write-Host "Please wait for certificate validation to complete" -ForegroundColor Yellow
    Write-Host "This typically takes 5-30 minutes after DNS validation records are added" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check status with:" -ForegroundColor Cyan
    Write-Host "  aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1" -ForegroundColor White
    exit 1
}

Write-Host "✓ Certificate is issued and ready" -ForegroundColor Green

# Step 4: Update distribution config
Write-Host ""
Write-Host "Step 4: Updating CloudFront distribution..." -ForegroundColor Yellow

# Add custom domain to Aliases
if ($config.Aliases.Items -notcontains $DOMAIN_NAME) {
    $config.Aliases.Items += $DOMAIN_NAME
    $config.Aliases.Quantity = $config.Aliases.Items.Count
}

if ($config.Aliases.Items -notcontains "www.$DOMAIN_NAME") {
    $config.Aliases.Items += "www.$DOMAIN_NAME"
    $config.Aliases.Quantity = $config.Aliases.Items.Count
}

# Update SSL certificate
$config.ViewerCertificate.ACMCertificateArn = $CERTIFICATE_ARN
$config.ViewerCertificate.Certificate = $CERTIFICATE_ARN
$config.ViewerCertificate.CertificateSource = "acm"
$config.ViewerCertificate.MinimumProtocolVersion = "TLSv1.2_2021"
$config.ViewerCertificate.SSLSupportMethod = "sni-only"

# Remove CloudFrontDefaultCertificate flag
$config.ViewerCertificate.PSObject.Properties.Remove('CloudFrontDefaultCertificate')

# Save updated config to file
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath "temp-distribution-config.json" -Encoding UTF8

# Update distribution
Write-Host "Applying configuration changes..." -ForegroundColor Yellow
$updateResult = aws cloudfront update-distribution `
    --id $DISTRIBUTION_ID `
    --distribution-config file://temp-distribution-config.json `
    --if-match $etag `
    --output json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to update distribution" -ForegroundColor Red
    Write-Host $updateResult -ForegroundColor Red
    Remove-Item "temp-distribution-config.json" -ErrorAction SilentlyContinue
    exit 1
}

Remove-Item "temp-distribution-config.json"
Write-Host "✓ Distribution updated successfully" -ForegroundColor Green

# Step 5: Wait for deployment
Write-Host ""
Write-Host "Step 5: Waiting for CloudFront deployment..." -ForegroundColor Yellow
Write-Host "This may take 10-15 minutes..." -ForegroundColor Cyan

$deployed = $false
$attempts = 0
$maxAttempts = 30

while (-not $deployed -and $attempts -lt $maxAttempts) {
    Start-Sleep -Seconds 30
    $attempts++
    
    $distStatus = aws cloudfront get-distribution --id $DISTRIBUTION_ID --query "Distribution.Status" --output text
    
    if ($distStatus -eq "Deployed") {
        $deployed = $true
        Write-Host "✓ CloudFront deployment complete!" -ForegroundColor Green
    } else {
        Write-Host "  Status: $distStatus (attempt $attempts/$maxAttempts)" -ForegroundColor Yellow
    }
}

if (-not $deployed) {
    Write-Host "⚠ Deployment is taking longer than expected" -ForegroundColor Yellow
    Write-Host "Check status with: aws cloudfront get-distribution --id $DISTRIBUTION_ID" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Domain:              $DOMAIN_NAME" -ForegroundColor White
Write-Host "www Domain:          www.$DOMAIN_NAME" -ForegroundColor White
Write-Host "CloudFront ID:       $DISTRIBUTION_ID" -ForegroundColor White
Write-Host "Certificate ARN:     $CERTIFICATE_ARN" -ForegroundColor White
Write-Host ""
Write-Host "Your site should now be accessible at:" -ForegroundColor Yellow
Write-Host "  https://$DOMAIN_NAME" -ForegroundColor Green
Write-Host "  https://www.$DOMAIN_NAME" -ForegroundColor Green
Write-Host ""
Write-Host "Note: DNS propagation may take up to 48 hours globally" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test DNS resolution:" -ForegroundColor Yellow
Write-Host "  nslookup $DOMAIN_NAME" -ForegroundColor White
Write-Host "  nslookup www.$DOMAIN_NAME" -ForegroundColor White
Write-Host ""
