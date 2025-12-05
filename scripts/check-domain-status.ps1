# Check Domain Setup Status
# Quick script to verify the status of your custom domain setup

$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Domain Setup Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Route53 Hosted Zone
Write-Host "1. Route53 Hosted Zone" -ForegroundColor Yellow
$hostedZones = aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query "HostedZones[?Name=='$DOMAIN_NAME.']" --output json | ConvertFrom-Json

if ($hostedZones.Count -gt 0) {
    $zoneId = $hostedZones[0].Id
    Write-Host "   ✓ Hosted zone exists: $zoneId" -ForegroundColor Green
    
    # Get nameservers
    $zoneDetails = aws route53 get-hosted-zone --id $zoneId --output json | ConvertFrom-Json
    Write-Host "   Nameservers:" -ForegroundColor Cyan
    foreach ($ns in $zoneDetails.DelegationSet.NameServers) {
        Write-Host "     - $ns" -ForegroundColor White
    }
} else {
    Write-Host "   ✗ No hosted zone found" -ForegroundColor Red
    Write-Host "   Run: .\scripts\setup-route53-domain.ps1" -ForegroundColor Yellow
}

Write-Host ""

# Check 2: ACM Certificate
Write-Host "2. ACM Certificate (us-east-1)" -ForegroundColor Yellow
$certs = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME']" --output json | ConvertFrom-Json

if ($certs.Count -gt 0) {
    $certArn = $certs[0].CertificateArn
    $certDetails = aws acm describe-certificate --certificate-arn $certArn --region us-east-1 --output json | ConvertFrom-Json
    $certStatus = $certDetails.Certificate.Status
    
    if ($certStatus -eq "ISSUED") {
        Write-Host "   ✓ Certificate issued: $certArn" -ForegroundColor Green
    } elseif ($certStatus -eq "PENDING_VALIDATION") {
        Write-Host "   ⚠ Certificate pending validation" -ForegroundColor Yellow
        Write-Host "   Status: $certStatus" -ForegroundColor Yellow
        Write-Host "   This typically takes 5-30 minutes after DNS records are created" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠ Certificate status: $certStatus" -ForegroundColor Yellow
    }
    
    Write-Host "   ARN: $certArn" -ForegroundColor Cyan
} else {
    Write-Host "   ✗ No certificate found" -ForegroundColor Red
    Write-Host "   Run: .\scripts\setup-route53-domain.ps1" -ForegroundColor Yellow
}

Write-Host ""

# Check 3: CloudFront Distribution
Write-Host "3. CloudFront Distribution" -ForegroundColor Yellow
$distributions = aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$CLOUDFRONT_DOMAIN']" --output json | ConvertFrom-Json

if ($distributions.Count -gt 0) {
    $distId = $distributions[0].Id
    $distStatus = $distributions[0].Status
    $aliases = $distributions[0].Aliases.Items
    
    Write-Host "   Distribution ID: $distId" -ForegroundColor Cyan
    Write-Host "   Status: $distStatus" -ForegroundColor $(if ($distStatus -eq "Deployed") { "Green" } else { "Yellow" })
    
    if ($aliases -contains $DOMAIN_NAME) {
        Write-Host "   ✓ Custom domain configured: $DOMAIN_NAME" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Custom domain not configured" -ForegroundColor Red
        Write-Host "   Run: .\scripts\update-cloudfront-domain.ps1" -ForegroundColor Yellow
    }
    
    if ($aliases -contains "www.$DOMAIN_NAME") {
        Write-Host "   ✓ www subdomain configured: www.$DOMAIN_NAME" -ForegroundColor Green
    } else {
        Write-Host "   ✗ www subdomain not configured" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ CloudFront distribution not found" -ForegroundColor Red
}

Write-Host ""

# Check 4: DNS Records
Write-Host "4. DNS Records" -ForegroundColor Yellow
if ($hostedZones.Count -gt 0) {
    $zoneId = $hostedZones[0].Id
    $records = aws route53 list-resource-record-sets --hosted-zone-id $zoneId --output json | ConvertFrom-Json
    
    $aRecord = $records.ResourceRecordSets | Where-Object { $_.Name -eq "$DOMAIN_NAME." -and $_.Type -eq "A" }
    $wwwRecord = $records.ResourceRecordSets | Where-Object { $_.Name -eq "www.$DOMAIN_NAME." -and $_.Type -eq "A" }
    
    if ($aRecord) {
        Write-Host "   ✓ A record exists for $DOMAIN_NAME" -ForegroundColor Green
    } else {
        Write-Host "   ✗ No A record for $DOMAIN_NAME" -ForegroundColor Red
    }
    
    if ($wwwRecord) {
        Write-Host "   ✓ A record exists for www.$DOMAIN_NAME" -ForegroundColor Green
    } else {
        Write-Host "   ✗ No A record for www.$DOMAIN_NAME" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠ Cannot check DNS records (no hosted zone)" -ForegroundColor Yellow
}

Write-Host ""

# Check 5: DNS Resolution
Write-Host "5. DNS Resolution Test" -ForegroundColor Yellow
try {
    $dnsResult = Resolve-DnsName -Name $DOMAIN_NAME -Type A -ErrorAction SilentlyContinue
    if ($dnsResult) {
        Write-Host "   ✓ DNS resolves for $DOMAIN_NAME" -ForegroundColor Green
        foreach ($record in $dnsResult) {
            if ($record.Type -eq "A") {
                Write-Host "     IP: $($record.IPAddress)" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "   ✗ DNS does not resolve yet" -ForegroundColor Red
        Write-Host "   This is normal if you just updated nameservers (wait 1-48 hours)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ DNS resolution failed" -ForegroundColor Red
    Write-Host "   This is normal if you just updated nameservers (wait 1-48 hours)" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$allGood = $true

if ($hostedZones.Count -eq 0) {
    Write-Host "⚠ Action Required: Create Route53 hosted zone" -ForegroundColor Yellow
    Write-Host "  Run: .\scripts\setup-route53-domain.ps1" -ForegroundColor White
    $allGood = $false
}

if ($certs.Count -eq 0) {
    Write-Host "⚠ Action Required: Request ACM certificate" -ForegroundColor Yellow
    Write-Host "  Run: .\scripts\setup-route53-domain.ps1" -ForegroundColor White
    $allGood = $false
} elseif ($certStatus -ne "ISSUED") {
    Write-Host "⚠ Waiting: Certificate validation in progress" -ForegroundColor Yellow
    Write-Host "  Check status: aws acm describe-certificate --certificate-arn $certArn --region us-east-1" -ForegroundColor White
    $allGood = $false
}

if ($distributions.Count -gt 0 -and -not ($aliases -contains $DOMAIN_NAME)) {
    Write-Host "⚠ Action Required: Update CloudFront with custom domain" -ForegroundColor Yellow
    Write-Host "  Run: .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
    $allGood = $false
}

if ($allGood) {
    Write-Host ""
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your site should be accessible at:" -ForegroundColor Cyan
    Write-Host "  https://$DOMAIN_NAME" -ForegroundColor Green
    Write-Host "  https://www.$DOMAIN_NAME" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: DNS propagation may take up to 48 hours globally" -ForegroundColor Yellow
}

Write-Host ""
