# Simple Status Check
$DOMAIN_NAME = "insight-hr.io.vn"
$CERTIFICATE_ARN = "arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Domain Setup Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Route53
Write-Host "1. Route53 Hosted Zone" -ForegroundColor Yellow
$zones = aws route53 list-hosted-zones --output json | ConvertFrom-Json
$zone = $zones.HostedZones | Where-Object { $_.Name -eq "$DOMAIN_NAME." }
if ($zone) {
    Write-Host "   Status: Created" -ForegroundColor Green
    Write-Host "   Zone ID: $($zone.Id)" -ForegroundColor Cyan
} else {
    Write-Host "   Status: Not found" -ForegroundColor Red
}

# Check 2: Certificate
Write-Host ""
Write-Host "2. SSL Certificate" -ForegroundColor Yellow
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json
$certStatus = $certDetails.Certificate.Status

if ($certStatus -eq "ISSUED") {
    Write-Host "   Status: ISSUED (Ready!)" -ForegroundColor Green
} elseif ($certStatus -eq "PENDING_VALIDATION") {
    Write-Host "   Status: PENDING_VALIDATION (Waiting...)" -ForegroundColor Yellow
    Write-Host "   This is normal. Wait for DNS propagation." -ForegroundColor Cyan
} else {
    Write-Host "   Status: $certStatus" -ForegroundColor Yellow
}

# Check 3: DNS Resolution
Write-Host ""
Write-Host "3. DNS Resolution" -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName -Name $DOMAIN_NAME -Type A -ErrorAction SilentlyContinue
    if ($dns) {
        Write-Host "   Status: Resolving" -ForegroundColor Green
        foreach ($record in $dns) {
            if ($record.Type -eq "A") {
                Write-Host "   IP: $($record.IPAddress)" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "   Status: Not resolving yet" -ForegroundColor Yellow
        Write-Host "   This is normal if you just updated nameservers" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   Status: Not resolving yet" -ForegroundColor Yellow
    Write-Host "   This is normal if you just updated nameservers" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($certStatus -eq "ISSUED") {
    Write-Host "Certificate is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run this command:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup-domain-step3.ps1" -ForegroundColor White
    Write-Host ""
} elseif ($certStatus -eq "PENDING_VALIDATION") {
    Write-Host "Waiting for certificate validation..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Have you updated nameservers at Matbao.net?" -ForegroundColor Cyan
    Write-Host "  ns-1213.awsdns-23.org" -ForegroundColor White
    Write-Host "  ns-1875.awsdns-42.co.uk" -ForegroundColor White
    Write-Host "  ns-968.awsdns-57.net" -ForegroundColor White
    Write-Host "  ns-247.awsdns-30.com" -ForegroundColor White
    Write-Host ""
    Write-Host "If yes, wait 1-2 hours and check again." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Check again: .\scripts\check-status-simple.ps1" -ForegroundColor Cyan
Write-Host ""
