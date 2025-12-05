# Step 3: Update CloudFront with Custom Domain
$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"
$CERTIFICATE_ARN = "arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c"

Write-Host "Step 3: Updating CloudFront distribution..." -ForegroundColor Yellow

# Check certificate status
Write-Host "Checking certificate status..." -ForegroundColor Cyan
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json
$certStatus = $certDetails.Certificate.Status

Write-Host "Certificate Status: $certStatus" -ForegroundColor $(if ($certStatus -eq "ISSUED") { "Green" } else { "Yellow" })

if ($certStatus -ne "ISSUED") {
    Write-Host ""
    Write-Host "Certificate is not yet issued!" -ForegroundColor Red
    Write-Host "Please wait for DNS propagation and certificate validation." -ForegroundColor Yellow
    Write-Host "This typically takes 5-30 minutes after updating nameservers at Matbao.net" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check status with: .\scripts\check-domain-status.ps1" -ForegroundColor Cyan
    exit 1
}

# Get CloudFront distribution
Write-Host "Getting CloudFront distribution..." -ForegroundColor Cyan
$distributions = aws cloudfront list-distributions --output json | ConvertFrom-Json
$dist = $distributions.DistributionList.Items | Where-Object { $_.DomainName -eq $CLOUDFRONT_DOMAIN }

if (-not $dist) {
    Write-Host "CloudFront distribution not found!" -ForegroundColor Red
    exit 1
}

$DISTRIBUTION_ID = $dist.Id
Write-Host "Distribution ID: $DISTRIBUTION_ID" -ForegroundColor Cyan

# Get current config
Write-Host "Getting current configuration..." -ForegroundColor Cyan
$configResult = aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --output json | ConvertFrom-Json
$config = $configResult.DistributionConfig
$etag = $configResult.ETag

# Update config
Write-Host "Updating configuration..." -ForegroundColor Yellow

# Add custom domains
if (-not $config.Aliases.Items) {
    $config.Aliases.Items = @()
}
if ($config.Aliases.Items -notcontains $DOMAIN_NAME) {
    $config.Aliases.Items += $DOMAIN_NAME
}
if ($config.Aliases.Items -notcontains "www.$DOMAIN_NAME") {
    $config.Aliases.Items += "www.$DOMAIN_NAME"
}
$config.Aliases.Quantity = $config.Aliases.Items.Count

# Update SSL certificate
$config.ViewerCertificate.ACMCertificateArn = $CERTIFICATE_ARN
$config.ViewerCertificate.Certificate = $CERTIFICATE_ARN
$config.ViewerCertificate.CertificateSource = "acm"
$config.ViewerCertificate.MinimumProtocolVersion = "TLSv1.2_2021"
$config.ViewerCertificate.SSLSupportMethod = "sni-only"
$config.ViewerCertificate.PSObject.Properties.Remove('CloudFrontDefaultCertificate')

# Save config
$configJson = $config | ConvertTo-Json -Depth 20
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("temp-dist-config.json", $configJson, $utf8)

# Update distribution
Write-Host "Applying changes to CloudFront..." -ForegroundColor Yellow
$updateResult = aws cloudfront update-distribution `
    --id $DISTRIBUTION_ID `
    --distribution-config file://temp-dist-config.json `
    --if-match $etag `
    --output json 2>&1

Remove-Item "temp-dist-config.json" -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to update CloudFront!" -ForegroundColor Red
    Write-Host $updateResult -ForegroundColor Red
    exit 1
}

Write-Host "CloudFront updated successfully!" -ForegroundColor Green

# Wait for deployment
Write-Host ""
Write-Host "Waiting for CloudFront deployment..." -ForegroundColor Yellow
Write-Host "This takes 10-15 minutes..." -ForegroundColor Cyan

$deployed = $false
$attempts = 0

while (-not $deployed -and $attempts -lt 20) {
    Start-Sleep -Seconds 30
    $attempts++
    
    $distStatus = aws cloudfront get-distribution --id $DISTRIBUTION_ID --query "Distribution.Status" --output text
    
    if ($distStatus -eq "Deployed") {
        $deployed = $true
        Write-Host "CloudFront deployment complete!" -ForegroundColor Green
    } else {
        Write-Host "  Status: $distStatus (check $attempts/20)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your site is now accessible at:" -ForegroundColor Yellow
Write-Host "  https://$DOMAIN_NAME" -ForegroundColor Green
Write-Host "  https://www.$DOMAIN_NAME" -ForegroundColor Green
Write-Host ""
Write-Host "Note: DNS propagation may take up to 48 hours globally" -ForegroundColor Cyan
Write-Host ""
