# Setup Route53 for Custom Domain: insight-hr.io.vn
# This script configures Route53 to point your custom domain to CloudFront distribution

# Configuration
$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"
$REGION = "ap-southeast-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Route53 Setup for $DOMAIN_NAME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if hosted zone exists
Write-Host "Step 1: Checking for existing hosted zone..." -ForegroundColor Yellow
$hostedZones = aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query "HostedZones[?Name=='$DOMAIN_NAME.']" --output json | ConvertFrom-Json

if ($hostedZones.Count -eq 0) {
    Write-Host "No hosted zone found. Creating new hosted zone..." -ForegroundColor Yellow
    
    # Create hosted zone
    $callerReference = [System.Guid]::NewGuid().ToString()
    $createResult = aws route53 create-hosted-zone `
        --name $DOMAIN_NAME `
        --caller-reference $callerReference `
        --hosted-zone-config Comment="InsightHR Production Domain" `
        --output json | ConvertFrom-Json
    
    $HOSTED_ZONE_ID = $createResult.HostedZone.Id
    Write-Host "✓ Hosted zone created: $HOSTED_ZONE_ID" -ForegroundColor Green
    
    # Get nameservers
    $nameservers = $createResult.DelegationSet.NameServers
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "IMPORTANT: Update your domain registrar" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Add these nameservers to your domain registrar:" -ForegroundColor Yellow
    foreach ($ns in $nameservers) {
        Write-Host "  - $ns" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "This is required for DNS to work properly!" -ForegroundColor Red
    Write-Host ""
} else {
    $HOSTED_ZONE_ID = $hostedZones[0].Id
    Write-Host "✓ Hosted zone already exists: $HOSTED_ZONE_ID" -ForegroundColor Green
}

# Step 2: Get CloudFront distribution ID
Write-Host ""
Write-Host "Step 2: Getting CloudFront distribution details..." -ForegroundColor Yellow
$distributions = aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$CLOUDFRONT_DOMAIN']" --output json | ConvertFrom-Json

if ($distributions.Count -eq 0) {
    Write-Host "✗ CloudFront distribution not found: $CLOUDFRONT_DOMAIN" -ForegroundColor Red
    exit 1
}

$DISTRIBUTION_ID = $distributions[0].Id
$DISTRIBUTION_ARN = $distributions[0].ARN
Write-Host "✓ CloudFront distribution found: $DISTRIBUTION_ID" -ForegroundColor Green

# Step 3: Request ACM certificate (must be in us-east-1 for CloudFront)
Write-Host ""
Write-Host "Step 3: Requesting ACM certificate in us-east-1..." -ForegroundColor Yellow
Write-Host "Note: CloudFront requires certificates in us-east-1 region" -ForegroundColor Cyan

# Check if certificate already exists
$existingCerts = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME']" --output json | ConvertFrom-Json

if ($existingCerts.Count -gt 0) {
    $CERTIFICATE_ARN = $existingCerts[0].CertificateArn
    Write-Host "✓ Certificate already exists: $CERTIFICATE_ARN" -ForegroundColor Green
} else {
    Write-Host "Requesting new certificate..." -ForegroundColor Yellow
    $certResult = aws acm request-certificate `
        --domain-name $DOMAIN_NAME `
        --validation-method DNS `
        --region us-east-1 `
        --output json | ConvertFrom-Json
    
    $CERTIFICATE_ARN = $certResult.CertificateArn
    Write-Host "✓ Certificate requested: $CERTIFICATE_ARN" -ForegroundColor Green
    
    # Wait a moment for certificate details to be available
    Start-Sleep -Seconds 5
    
    # Get validation records
    Write-Host ""
    Write-Host "Getting DNS validation records..." -ForegroundColor Yellow
    $certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json
    
    if ($certDetails.Certificate.DomainValidationOptions) {
        $validationRecord = $certDetails.Certificate.DomainValidationOptions[0].ResourceRecord
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Certificate Validation Required" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Add this DNS record to validate certificate:" -ForegroundColor Yellow
        Write-Host "  Name:  $($validationRecord.Name)" -ForegroundColor White
        Write-Host "  Type:  $($validationRecord.Type)" -ForegroundColor White
        Write-Host "  Value: $($validationRecord.Value)" -ForegroundColor White
        Write-Host ""
        Write-Host "Creating validation record in Route53..." -ForegroundColor Yellow
        
        # Create validation record in Route53
        $changeFile = @"
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$($validationRecord.Name)",
        "Type": "$($validationRecord.Type)",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$($validationRecord.Value)"
          }
        ]
      }
    }
  ]
}
"@
        
        $changeFile | Out-File -FilePath "temp-validation-record.json" -Encoding UTF8
        aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-validation-record.json
        Remove-Item "temp-validation-record.json"
        
        Write-Host "✓ Validation record created" -ForegroundColor Green
        Write-Host ""
        Write-Host "Waiting for certificate validation (this may take 5-30 minutes)..." -ForegroundColor Yellow
        Write-Host "You can check status with: aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1" -ForegroundColor Cyan
    }
}

# Step 4: Create A record pointing to CloudFront
Write-Host ""
Write-Host "Step 4: Creating DNS A record for $DOMAIN_NAME..." -ForegroundColor Yellow

$changeFile = @"
{
  "Changes": [
    {
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
    }
  ]
}
"@

$changeFile | Out-File -FilePath "temp-dns-record.json" -Encoding UTF8
$changeResult = aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-dns-record.json --output json | ConvertFrom-Json
Remove-Item "temp-dns-record.json"

Write-Host "✓ DNS A record created" -ForegroundColor Green
Write-Host "  Change ID: $($changeResult.ChangeInfo.Id)" -ForegroundColor Cyan

# Step 5: Create www subdomain (optional)
Write-Host ""
Write-Host "Step 5: Creating www subdomain (optional)..." -ForegroundColor Yellow

$changeFile = @"
{
  "Changes": [
    {
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
    }
  ]
}
"@

$changeFile | Out-File -FilePath "temp-www-record.json" -Encoding UTF8
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-www-record.json
Remove-Item "temp-www-record.json"

Write-Host "✓ www subdomain created" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Domain:              $DOMAIN_NAME" -ForegroundColor White
Write-Host "Hosted Zone ID:      $HOSTED_ZONE_ID" -ForegroundColor White
Write-Host "CloudFront Domain:   $CLOUDFRONT_DOMAIN" -ForegroundColor White
Write-Host "CloudFront ID:       $DISTRIBUTION_ID" -ForegroundColor White
Write-Host "Certificate ARN:     $CERTIFICATE_ARN" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait for certificate validation (5-30 minutes)" -ForegroundColor White
Write-Host "2. Update CloudFront distribution to use custom domain" -ForegroundColor White
Write-Host "3. Test DNS propagation: nslookup $DOMAIN_NAME" -ForegroundColor White
Write-Host ""
Write-Host "Run the following script to update CloudFront:" -ForegroundColor Cyan
Write-Host "  .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
Write-Host ""
