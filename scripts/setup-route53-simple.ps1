# Simple Route53 Setup for insight-hr.io.vn
# This script creates the Route53 hosted zone and requests SSL certificate

$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Route53 Setup for $DOMAIN_NAME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create hosted zone
Write-Host "Step 1: Creating Route53 hosted zone..." -ForegroundColor Yellow
$callerReference = [System.Guid]::NewGuid().ToString()

try {
    $createResult = aws route53 create-hosted-zone --name $DOMAIN_NAME --caller-reference $callerReference --hosted-zone-config "Comment=InsightHR Production Domain" --output json | ConvertFrom-Json
    
    $HOSTED_ZONE_ID = $createResult.HostedZone.Id
    Write-Host "✓ Hosted zone created: $HOSTED_ZONE_ID" -ForegroundColor Green
    
    # Get nameservers
    $nameservers = $createResult.DelegationSet.NameServers
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "IMPORTANT: Update Matbao.net Nameservers" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Log in to Matbao.net and update nameservers to:" -ForegroundColor Yellow
    foreach ($ns in $nameservers) {
        Write-Host "  $ns" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Save these nameservers - you will need them!" -ForegroundColor Red
    Write-Host ""
} catch {
    Write-Host "Note: Hosted zone may already exist" -ForegroundColor Yellow
    $zones = aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --output json | ConvertFrom-Json
    $zone = $zones.HostedZones | Where-Object { $_.Name -eq "$DOMAIN_NAME." }
    if ($zone) {
        $HOSTED_ZONE_ID = $zone.Id
        Write-Host "✓ Using existing hosted zone: $HOSTED_ZONE_ID" -ForegroundColor Green
        
        # Get nameservers
        $zoneDetails = aws route53 get-hosted-zone --id $HOSTED_ZONE_ID --output json | ConvertFrom-Json
        $nameservers = $zoneDetails.DelegationSet.NameServers
        Write-Host ""
        Write-Host "Nameservers for Matbao.net:" -ForegroundColor Yellow
        foreach ($ns in $nameservers) {
            Write-Host "  $ns" -ForegroundColor White
        }
        Write-Host ""
    }
}

# Step 2: Request ACM certificate
Write-Host "Step 2: Requesting SSL certificate (us-east-1)..." -ForegroundColor Yellow

$existingCerts = aws acm list-certificates --region us-east-1 --output json | ConvertFrom-Json
$cert = $existingCerts.CertificateSummaryList | Where-Object { $_.DomainName -eq $DOMAIN_NAME }

if ($cert) {
    $CERTIFICATE_ARN = $cert.CertificateArn
    Write-Host "✓ Certificate already exists: $CERTIFICATE_ARN" -ForegroundColor Green
} else {
    $certResult = aws acm request-certificate --domain-name $DOMAIN_NAME --subject-alternative-names "www.$DOMAIN_NAME" --validation-method DNS --region us-east-1 --output json | ConvertFrom-Json
    $CERTIFICATE_ARN = $certResult.CertificateArn
    Write-Host "✓ Certificate requested: $CERTIFICATE_ARN" -ForegroundColor Green
}

# Wait for certificate details
Start-Sleep -Seconds 5

# Get validation records
Write-Host ""
Write-Host "Step 3: Getting certificate validation records..." -ForegroundColor Yellow
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json

if ($certDetails.Certificate.DomainValidationOptions) {
    foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
        if ($validation.ResourceRecord) {
            $validationRecord = $validation.ResourceRecord
            Write-Host ""
            Write-Host "Creating DNS validation record..." -ForegroundColor Yellow
            Write-Host "  Name:  $($validationRecord.Name)" -ForegroundColor Cyan
            Write-Host "  Type:  $($validationRecord.Type)" -ForegroundColor Cyan
            Write-Host "  Value: $($validationRecord.Value)" -ForegroundColor Cyan
            
            # Create validation record JSON
            $recordJson = @{
                Changes = @(
                    @{
                        Action = "UPSERT"
                        ResourceRecordSet = @{
                            Name = $validationRecord.Name
                            Type = $validationRecord.Type
                            TTL = 300
                            ResourceRecords = @(
                                @{
                                    Value = $validationRecord.Value
                                }
                            )
                        }
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $recordJson | Out-File -FilePath "temp-validation.json" -Encoding UTF8
            aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-validation.json
            Remove-Item "temp-validation.json" -ErrorAction SilentlyContinue
            
            Write-Host "✓ Validation record created in Route53" -ForegroundColor Green
        }
    }
}

# Step 4: Create A records
Write-Host ""
Write-Host "Step 4: Creating A records for domain..." -ForegroundColor Yellow

# Create A record for root domain
$aRecordJson = @{
    Changes = @(
        @{
            Action = "UPSERT"
            ResourceRecordSet = @{
                Name = $DOMAIN_NAME
                Type = "A"
                AliasTarget = @{
                    HostedZoneId = "Z2FDTNDATAQYW2"
                    DNSName = $CLOUDFRONT_DOMAIN
                    EvaluateTargetHealth = $false
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$aRecordJson | Out-File -FilePath "temp-a-record.json" -Encoding UTF8
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-a-record.json
Remove-Item "temp-a-record.json" -ErrorAction SilentlyContinue

Write-Host "✓ A record created for $DOMAIN_NAME" -ForegroundColor Green

# Create A record for www subdomain
$wwwRecordJson = @{
    Changes = @(
        @{
            Action = "UPSERT"
            ResourceRecordSet = @{
                Name = "www.$DOMAIN_NAME"
                Type = "A"
                AliasTarget = @{
                    HostedZoneId = "Z2FDTNDATAQYW2"
                    DNSName = $CLOUDFRONT_DOMAIN
                    EvaluateTargetHealth = $false
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$wwwRecordJson | Out-File -FilePath "temp-www-record.json" -Encoding UTF8
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp-www-record.json
Remove-Item "temp-www-record.json" -ErrorAction SilentlyContinue

Write-Host "✓ A record created for www.$DOMAIN_NAME" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Hosted Zone ID: $HOSTED_ZONE_ID" -ForegroundColor White
Write-Host "Certificate ARN: $CERTIFICATE_ARN" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update nameservers at Matbao.net (see above)" -ForegroundColor White
Write-Host "2. Wait 1-2 hours for DNS propagation" -ForegroundColor White
Write-Host "3. Wait for certificate validation (5-30 minutes)" -ForegroundColor White
Write-Host "4. Run: .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Check status: .\scripts\check-domain-status.ps1" -ForegroundColor Cyan
Write-Host ""
