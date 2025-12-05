# Complete Custom Domain Setup Workflow
# This script guides you through the entire process

$DOMAIN_NAME = "insight-hr.io.vn"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "InsightHR Custom Domain Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This wizard will guide you through setting up:" -ForegroundColor White
Write-Host "  Domain: $DOMAIN_NAME" -ForegroundColor Green
Write-Host ""
Write-Host "The process has 3 main steps:" -ForegroundColor Yellow
Write-Host "  1. Setup Route53 and request SSL certificate (5 min)" -ForegroundColor White
Write-Host "  2. Update nameservers at domain registrar (5 min + wait)" -ForegroundColor White
Write-Host "  3. Update CloudFront distribution (2 min + wait)" -ForegroundColor White
Write-Host ""
Write-Host "Total time: 30 minutes to 48 hours (depending on DNS propagation)" -ForegroundColor Cyan
Write-Host ""

# Confirm to proceed
$proceed = Read-Host "Ready to start? (yes/no)"
if ($proceed -ne "yes" -and $proceed -ne "y") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Route53 and Certificate Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  - Create Route53 hosted zone" -ForegroundColor White
Write-Host "  - Request SSL certificate from ACM" -ForegroundColor White
Write-Host "  - Create DNS records" -ForegroundColor White
Write-Host ""

$runStep1 = Read-Host "Run Step 1 now? (yes/no)"
if ($runStep1 -eq "yes" -or $runStep1 -eq "y") {
    Write-Host ""
    Write-Host "Running setup-route53-domain.ps1..." -ForegroundColor Green
    Write-Host ""
    
    & "$PSScriptRoot\setup-route53-domain.ps1"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "STEP 1 COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Skipping Step 1. Run manually: .\scripts\setup-route53-domain.ps1" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Update Domain Registrar" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: You must update nameservers at your domain registrar!" -ForegroundColor Red
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "  1. Log in to where you purchased $DOMAIN_NAME" -ForegroundColor White
Write-Host "  2. Find DNS or Nameserver settings" -ForegroundColor White
Write-Host "  3. Replace current nameservers with the 4 AWS nameservers shown above" -ForegroundColor White
Write-Host "  4. Save changes" -ForegroundColor White
Write-Host ""
Write-Host "The nameservers look like:" -ForegroundColor Cyan
Write-Host "  ns-1234.awsdns-12.org" -ForegroundColor White
Write-Host "  ns-5678.awsdns-34.com" -ForegroundColor White
Write-Host "  ns-9012.awsdns-56.net" -ForegroundColor White
Write-Host "  ns-3456.awsdns-78.co.uk" -ForegroundColor White
Write-Host ""
Write-Host "DNS propagation typically takes 1-2 hours, but can take up to 48 hours." -ForegroundColor Yellow
Write-Host ""

$nameserversUpdated = Read-Host "Have you updated the nameservers? (yes/no)"
if ($nameserversUpdated -ne "yes" -and $nameserversUpdated -ne "y") {
    Write-Host ""
    Write-Host "Please update nameservers first, then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To check status later, run:" -ForegroundColor Cyan
    Write-Host "  .\scripts\check-domain-status.ps1" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Great! Now we need to wait for:" -ForegroundColor Yellow
Write-Host "  1. DNS propagation (1-48 hours)" -ForegroundColor White
Write-Host "  2. Certificate validation (5-30 minutes after DNS propagates)" -ForegroundColor White
Write-Host ""
Write-Host "Let's check the current status..." -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 2

# Check status
& "$PSScriptRoot\check-domain-status.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Certificate Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$certs = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME']" --output json | ConvertFrom-Json

if ($certs.Count -eq 0) {
    Write-Host "✗ No certificate found. Please run Step 1 first." -ForegroundColor Red
    exit 1
}

$certArn = $certs[0].CertificateArn
$certDetails = aws acm describe-certificate --certificate-arn $certArn --region us-east-1 --output json | ConvertFrom-Json
$certStatus = $certDetails.Certificate.Status

Write-Host "Certificate Status: $certStatus" -ForegroundColor $(if ($certStatus -eq "ISSUED") { "Green" } else { "Yellow" })
Write-Host ""

if ($certStatus -ne "ISSUED") {
    Write-Host "The certificate is not yet issued." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is normal if you just updated nameservers." -ForegroundColor Cyan
    Write-Host "Certificate validation typically takes 5-30 minutes after DNS propagates." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What would you like to do?" -ForegroundColor Yellow
    Write-Host "  1. Wait and check again (recommended)" -ForegroundColor White
    Write-Host "  2. Exit and check later" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1 or 2)"
    
    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "Waiting 5 minutes before checking again..." -ForegroundColor Cyan
        Write-Host "You can press Ctrl+C to cancel and check later." -ForegroundColor Yellow
        Write-Host ""
        
        $waitMinutes = 5
        for ($i = $waitMinutes; $i -gt 0; $i--) {
            Write-Host "  Checking again in $i minutes..." -ForegroundColor Cyan
            Start-Sleep -Seconds 60
        }
        
        Write-Host ""
        Write-Host "Checking certificate status again..." -ForegroundColor Yellow
        $certDetails = aws acm describe-certificate --certificate-arn $certArn --region us-east-1 --output json | ConvertFrom-Json
        $certStatus = $certDetails.Certificate.Status
        
        Write-Host "Certificate Status: $certStatus" -ForegroundColor $(if ($certStatus -eq "ISSUED") { "Green" } else { "Yellow" })
        Write-Host ""
        
        if ($certStatus -ne "ISSUED") {
            Write-Host "Certificate is still not issued. This can take up to 48 hours." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To check status later, run:" -ForegroundColor Cyan
            Write-Host "  aws acm describe-certificate --certificate-arn $certArn --region us-east-1" -ForegroundColor White
            Write-Host ""
            Write-Host "Once issued, run Step 3:" -ForegroundColor Cyan
            Write-Host "  .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
            Write-Host ""
            exit 0
        }
    } else {
        Write-Host ""
        Write-Host "To check status later, run:" -ForegroundColor Cyan
        Write-Host "  .\scripts\check-domain-status.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "Once certificate is issued, run Step 3:" -ForegroundColor Cyan
        Write-Host "  .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
        Write-Host ""
        exit 0
    }
}

Write-Host "✓ Certificate is issued and ready!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 3: Update CloudFront Distribution" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  - Add custom domain to CloudFront" -ForegroundColor White
Write-Host "  - Attach SSL certificate" -ForegroundColor White
Write-Host "  - Deploy changes (10-15 minutes)" -ForegroundColor White
Write-Host ""

$runStep3 = Read-Host "Run Step 3 now? (yes/no)"
if ($runStep3 -eq "yes" -or $runStep3 -eq "y") {
    Write-Host ""
    Write-Host "Running update-cloudfront-domain.ps1..." -ForegroundColor Green
    Write-Host ""
    
    & "$PSScriptRoot\update-cloudfront-domain.ps1"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your InsightHR application is now accessible at:" -ForegroundColor Yellow
    Write-Host "  https://$DOMAIN_NAME" -ForegroundColor Green
    Write-Host "  https://www.$DOMAIN_NAME" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: DNS propagation may take up to 48 hours globally." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps (optional):" -ForegroundColor Yellow
    Write-Host "  1. Update Google OAuth redirect URIs" -ForegroundColor White
    Write-Host "  2. Update Cognito callback URLs" -ForegroundColor White
    Write-Host "  3. Update environment variables" -ForegroundColor White
    Write-Host ""
    Write-Host "See DOMAIN-SETUP-SUMMARY.md for details." -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Run Step 3 manually when ready:" -ForegroundColor Yellow
    Write-Host "  .\scripts\update-cloudfront-domain.ps1" -ForegroundColor White
    Write-Host ""
}

Write-Host "To check status anytime, run:" -ForegroundColor Cyan
Write-Host "  .\scripts\check-domain-status.ps1" -ForegroundColor White
Write-Host ""
