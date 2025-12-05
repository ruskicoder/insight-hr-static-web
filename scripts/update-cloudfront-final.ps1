# Final CloudFront Update
$DOMAIN_NAME = "insight-hr.io.vn"
$CERTIFICATE_ARN = "arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c"
$DISTRIBUTION_ID = "E3MHW5VALWTOCI"

Write-Host "Updating CloudFront distribution..." -ForegroundColor Yellow
Write-Host "Distribution ID: $DISTRIBUTION_ID" -ForegroundColor Cyan

# Get current config
Write-Host "Getting current configuration..." -ForegroundColor Cyan
$result = aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --output json
$json = $result | ConvertFrom-Json
$etag = $json.ETag

# Modify the config directly in JSON
Write-Host "Modifying configuration..." -ForegroundColor Cyan
$config = $json.DistributionConfig

# Update aliases
$config.Aliases = @{
    Quantity = 2
    Items = @($DOMAIN_NAME, "www.$DOMAIN_NAME")
}

# Update viewer certificate
$config.ViewerCertificate = @{
    ACMCertificateArn = $CERTIFICATE_ARN
    Certificate = $CERTIFICATE_ARN
    CertificateSource = "acm"
    MinimumProtocolVersion = "TLSv1.2_2021"
    SSLSupportMethod = "sni-only"
}

# Save to file
$configJson = $config | ConvertTo-Json -Depth 20
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("temp-cloudfront-config.json", $configJson, $utf8)

# Update distribution
Write-Host "Applying changes..." -ForegroundColor Yellow
$updateResult = aws cloudfront update-distribution `
    --id $DISTRIBUTION_ID `
    --distribution-config file://temp-cloudfront-config.json `
    --if-match $etag `
    --output json 2>&1

Remove-Item "temp-cloudfront-config.json" -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "Update failed. Error:" -ForegroundColor Red
    Write-Host $updateResult -ForegroundColor Red
    Write-Host ""
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Use AWS CLI to update directly
    $cliUpdate = "aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config '{`"Aliases`":{`"Quantity`":2,`"Items`":[`"$DOMAIN_NAME`",`"www.$DOMAIN_NAME`"]},`"ViewerCertificate`":{`"ACMCertificateArn`":`"$CERTIFICATE_ARN`",`"SSLSupportMethod`":`"sni-only`",`"MinimumProtocolVersion`":`"TLSv1.2_2021`"}}' --if-match $etag"
    
    Write-Host "Please run this command manually:" -ForegroundColor Yellow
    Write-Host $cliUpdate -ForegroundColor White
    exit 1
}

Write-Host "CloudFront updated successfully!" -ForegroundColor Green

# Wait for deployment
Write-Host ""
Write-Host "Waiting for deployment (10-15 minutes)..." -ForegroundColor Yellow

$deployed = $false
$attempts = 0

while (-not $deployed -and $attempts -lt 20) {
    Start-Sleep -Seconds 30
    $attempts++
    
    $status = aws cloudfront get-distribution --id $DISTRIBUTION_ID --query "Distribution.Status" --output text
    
    if ($status -eq "Deployed") {
        $deployed = $true
        Write-Host "Deployment complete!" -ForegroundColor Green
    } else {
        Write-Host "  Status: $status (check $attempts/20)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your site is now live at:" -ForegroundColor Yellow
Write-Host "  https://$DOMAIN_NAME" -ForegroundColor Green
Write-Host "  https://www.$DOMAIN_NAME" -ForegroundColor Green
Write-Host ""
