# Step 2: Request SSL Certificate and Create DNS Records
$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"

Write-Host "Step 2: Requesting SSL certificate..." -ForegroundColor Yellow

# Get hosted zone ID
$zones = aws route53 list-hosted-zones --output json | ConvertFrom-Json
$zone = $zones.HostedZones | Where-Object { $_.Name -eq "$DOMAIN_NAME." }
$HOSTED_ZONE_ID = $zone.Id

Write-Host "Using hosted zone: $HOSTED_ZONE_ID" -ForegroundColor Cyan

# Request certificate
Write-Host "Requesting certificate from ACM (us-east-1)..." -ForegroundColor Yellow
$certResult = aws acm request-certificate `
    --domain-name $DOMAIN_NAME `
    --subject-alternative-names "www.$DOMAIN_NAME" `
    --validation-method DNS `
    --region us-east-1 `
    --output json 2>&1

if ($LASTEXITCODE -eq 0) {
    $certJson = $certResult | ConvertFrom-Json
    $CERTIFICATE_ARN = $certJson.CertificateArn
    Write-Host "Certificate requested: $CERTIFICATE_ARN" -ForegroundColor Green
} else {
    Write-Host "Checking for existing certificate..." -ForegroundColor Yellow
    $certs = aws acm list-certificates --region us-east-1 --output json | ConvertFrom-Json
    $cert = $certs.CertificateSummaryList | Where-Object { $_.DomainName -eq $DOMAIN_NAME }
    if ($cert) {
        $CERTIFICATE_ARN = $cert.CertificateArn
        Write-Host "Using existing certificate: $CERTIFICATE_ARN" -ForegroundColor Green
    }
}

# Wait for certificate details
Write-Host "Waiting for certificate details..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Get validation records
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json

Write-Host ""
Write-Host "Creating DNS validation records..." -ForegroundColor Yellow

foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
    if ($validation.ResourceRecord) {
        $record = $validation.ResourceRecord
        Write-Host "  Domain: $($validation.DomainName)" -ForegroundColor Cyan
        Write-Host "  Record: $($record.Name)" -ForegroundColor White
        
        # Create validation record
        $changeJson = @"
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$($record.Name)",
      "Type": "$($record.Type)",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$($record.Value)"}]
    }
  }]
}
"@
        
        $changeJson | Out-File -FilePath "temp-validation.json" -Encoding UTF8
        aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-validation.json | Out-Null
        Remove-Item "temp-validation.json" -ErrorAction SilentlyContinue
        
        Write-Host "  Validation record created" -ForegroundColor Green
    }
}

# Create A records for domain
Write-Host ""
Write-Host "Creating A records..." -ForegroundColor Yellow

# Root domain A record
$aRecordJson = @"
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$DOMAIN_NAME",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2FDTNDATAQYW2",
        "DNSName": "$CLOUDFRONT_DOMAIN",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
"@

$aRecordJson | Out-File -FilePath "temp-a.json" -Encoding UTF8
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-a.json | Out-Null
Remove-Item "temp-a.json" -ErrorAction SilentlyContinue
Write-Host "  A record created for $DOMAIN_NAME" -ForegroundColor Green

# www subdomain A record
$wwwRecordJson = @"
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "www.$DOMAIN_NAME",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2FDTNDATAQYW2",
        "DNSName": "$CLOUDFRONT_DOMAIN",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
"@

$wwwRecordJson | Out-File -FilePath "temp-www.json" -Encoding UTF8
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-www.json | Out-Null
Remove-Item "temp-www.json" -ErrorAction SilentlyContinue
Write-Host "  A record created for www.$DOMAIN_NAME" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DNS Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Certificate ARN: $CERTIFICATE_ARN" -ForegroundColor Cyan
Write-Host ""
Write-Host "Waiting for:" -ForegroundColor Yellow
Write-Host "  1. DNS propagation (1-48 hours)" -ForegroundColor White
Write-Host "  2. Certificate validation (5-30 minutes after DNS)" -ForegroundColor White
Write-Host ""
Write-Host "Check status: .\scripts\check-domain-status.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Once certificate is ISSUED, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\setup-domain-step3.ps1" -ForegroundColor White
Write-Host ""
