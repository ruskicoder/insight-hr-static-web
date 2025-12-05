# Custom Domain Setup Guide for InsightHR
## Setting up insight-hr.io.vn with Route53 and CloudFront

This guide walks you through connecting your newly purchased domain `insight-hr.io.vn` to your existing CloudFront distribution.

---

## Overview

Your InsightHR application is currently accessible at:
- **Current URL**: https://d2z6tht6rq32uy.cloudfront.net

After completing this setup, it will be accessible at:
- **Custom Domain**: https://insight-hr.io.vn
- **www Subdomain**: https://www.insight-hr.io.vn

---

## Prerequisites

✅ Domain purchased: `insight-hr.io.vn`  
✅ AWS CLI installed and configured  
✅ Access to your domain registrar (where you purchased the domain)  
✅ Existing CloudFront distribution: `d2z6tht6rq32uy.cloudfront.net`

---

## Setup Process

### Step 1: Run Route53 Setup Script

This script will:
- Create a Route53 hosted zone for your domain
- Request an SSL/TLS certificate from AWS Certificate Manager (ACM)
- Create DNS records pointing to your CloudFront distribution
- Set up www subdomain

```powershell
.\scripts\setup-route53-domain.ps1
```

**Expected Output:**
- Hosted Zone ID
- Certificate ARN
- Nameservers (IMPORTANT - save these!)

---

### Step 2: Update Domain Registrar Nameservers

After running the script, you'll receive 4 nameservers like:
```
ns-1234.awsdns-12.org
ns-5678.awsdns-34.com
ns-9012.awsdns-56.net
ns-3456.awsdns-78.co.uk
```

**Action Required:**
1. Log in to your domain registrar (where you purchased insight-hr.io.vn)
2. Find the DNS/Nameserver settings
3. Replace the current nameservers with the AWS nameservers
4. Save changes

**Note:** This change can take 24-48 hours to propagate globally, but often completes within 1-2 hours.

---

### Step 3: Wait for Certificate Validation

The script automatically creates DNS validation records in Route53. AWS will validate your certificate ownership.

**Check certificate status:**
```powershell
aws acm describe-certificate --certificate-arn <YOUR_CERTIFICATE_ARN> --region us-east-1
```

Look for `"Status": "ISSUED"` in the output.

**Typical timeline:** 5-30 minutes after nameservers are updated

---

### Step 4: Update CloudFront Distribution

Once the certificate is issued, run the second script to add your custom domain to CloudFront:

```powershell
.\scripts\update-cloudfront-domain.ps1
```

This script will:
- Add `insight-hr.io.vn` and `www.insight-hr.io.vn` as alternate domain names
- Attach the SSL certificate to CloudFront
- Deploy the changes (takes 10-15 minutes)

---

### Step 5: Verify Setup

After CloudFront deployment completes, test your domain:

**DNS Resolution:**
```powershell
nslookup insight-hr.io.vn
nslookup www.insight-hr.io.vn
```

**HTTPS Access:**
- Open browser: https://insight-hr.io.vn
- Open browser: https://www.insight-hr.io.vn

**Expected Result:** Your InsightHR application loads with a valid SSL certificate

---

## Troubleshooting

### Issue: Certificate stuck in "PENDING_VALIDATION"

**Cause:** Nameservers not updated at domain registrar

**Solution:**
1. Verify nameservers are correctly set at your registrar
2. Wait 1-2 hours for DNS propagation
3. Check again with: `aws acm describe-certificate --certificate-arn <ARN> --region us-east-1`

---

### Issue: "nslookup" returns no results

**Cause:** DNS propagation not complete

**Solution:**
1. Wait longer (up to 48 hours for global propagation)
2. Try different DNS servers: `nslookup insight-hr.io.vn 8.8.8.8`
3. Check Route53 records: `aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>`

---

### Issue: Browser shows "Certificate Error"

**Cause:** CloudFront not updated with certificate, or certificate not issued

**Solution:**
1. Verify certificate status is "ISSUED"
2. Re-run `update-cloudfront-domain.ps1`
3. Wait for CloudFront deployment to complete
4. Clear browser cache and try again

---

### Issue: CloudFront update fails

**Cause:** Certificate not in us-east-1 region, or certificate not issued

**Solution:**
1. Verify certificate is in us-east-1: `aws acm list-certificates --region us-east-1`
2. Verify certificate status is "ISSUED"
3. Check CloudFront distribution exists: `aws cloudfront list-distributions`

---

## Manual Setup (Alternative)

If you prefer to set up manually via AWS Console:

### 1. Route53 Hosted Zone
1. Go to Route53 → Hosted zones → Create hosted zone
2. Domain name: `insight-hr.io.vn`
3. Type: Public hosted zone
4. Create hosted zone
5. Note the 4 nameservers

### 2. Update Domain Registrar
1. Log in to your domain registrar
2. Update nameservers to the 4 AWS nameservers
3. Save changes

### 3. Request Certificate (ACM)
1. Go to Certificate Manager (us-east-1 region)
2. Request certificate → Request a public certificate
3. Domain name: `insight-hr.io.vn`
4. Add another name: `*.insight-hr.io.vn` (for www subdomain)
5. Validation method: DNS validation
6. Request certificate
7. Click "Create records in Route53" button
8. Wait for status to change to "Issued"

### 4. Update CloudFront
1. Go to CloudFront → Distributions
2. Select your distribution (d2z6tht6rq32uy.cloudfront.net)
3. Edit → General
4. Alternate domain names (CNAMEs): Add `insight-hr.io.vn` and `www.insight-hr.io.vn`
5. Custom SSL certificate: Select your certificate
6. Save changes
7. Wait for deployment (10-15 minutes)

### 5. Create Route53 Records
1. Go to Route53 → Hosted zones → insight-hr.io.vn
2. Create record:
   - Record name: (leave blank for root domain)
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to CloudFront distribution
   - Choose distribution: d2z6tht6rq32uy.cloudfront.net
   - Create record
3. Create another record for www:
   - Record name: www
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to CloudFront distribution
   - Choose distribution: d2z6tht6rq32uy.cloudfront.net
   - Create record

---

## Cost Estimate

**Route53 Hosted Zone:** $0.50/month  
**ACM Certificate:** FREE  
**CloudFront:** No additional cost (already using CloudFront)  
**DNS Queries:** $0.40 per million queries (first 1 billion queries/month)

**Total Additional Cost:** ~$0.50-$1.00/month

---

## Post-Setup Tasks

### Update Environment Variables

Update your frontend `.env` file if you have hardcoded URLs:

```env
VITE_API_BASE_URL=https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/prod
VITE_APP_URL=https://insight-hr.io.vn
```

### Update Google OAuth

If using Google OAuth, update authorized redirect URIs:
1. Go to Google Cloud Console
2. APIs & Services → Credentials
3. Edit OAuth 2.0 Client ID
4. Add authorized redirect URIs:
   - https://insight-hr.io.vn
   - https://www.insight-hr.io.vn
5. Save

### Update Cognito

Update Cognito callback URLs:
1. Go to Cognito → User pools
2. Select your user pool
3. App integration → App client settings
4. Add callback URLs:
   - https://insight-hr.io.vn
   - https://www.insight-hr.io.vn
5. Save changes

### Update CloudWatch Canaries

Update canary scripts to test the new domain:
```javascript
// In cloudwatch/canaries/*.js
const BASE_URL = 'https://insight-hr.io.vn';
```

---

## Verification Checklist

- [ ] Route53 hosted zone created
- [ ] Nameservers updated at domain registrar
- [ ] ACM certificate issued (Status: ISSUED)
- [ ] CloudFront distribution updated with custom domain
- [ ] CloudFront deployment complete (Status: Deployed)
- [ ] DNS resolution working (nslookup)
- [ ] HTTPS access working (browser test)
- [ ] SSL certificate valid (no browser warnings)
- [ ] www subdomain working
- [ ] Google OAuth redirect URIs updated
- [ ] Cognito callback URLs updated
- [ ] Environment variables updated
- [ ] CloudWatch canaries updated

---

## Support

If you encounter issues:

1. **Check AWS Service Health:** https://status.aws.amazon.com/
2. **Review CloudWatch Logs:** Check for errors in Lambda functions
3. **Test DNS:** Use online tools like https://dnschecker.org/
4. **Verify Certificate:** Check ACM console for certificate status
5. **Check CloudFront:** Verify distribution status and configuration

---

## Timeline Summary

| Step | Duration | Can Start After |
|------|----------|-----------------|
| Run setup script | 5 minutes | Immediately |
| Update nameservers | 5 minutes | Script completes |
| DNS propagation | 1-48 hours | Nameservers updated |
| Certificate validation | 5-30 minutes | DNS propagation |
| Update CloudFront | 2 minutes | Certificate issued |
| CloudFront deployment | 10-15 minutes | CloudFront updated |
| **Total Minimum** | **~30 minutes** | With fast DNS propagation |
| **Total Maximum** | **~48 hours** | With slow DNS propagation |

---

## Quick Reference Commands

```powershell
# Setup Route53 and request certificate
.\scripts\setup-route53-domain.ps1

# Check certificate status
aws acm describe-certificate --certificate-arn <ARN> --region us-east-1

# Update CloudFront with custom domain
.\scripts\update-cloudfront-domain.ps1

# Check CloudFront deployment status
aws cloudfront get-distribution --id <DISTRIBUTION_ID>

# Test DNS resolution
nslookup insight-hr.io.vn
nslookup www.insight-hr.io.vn

# List Route53 records
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>

# Invalidate CloudFront cache (if needed)
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

---

## Success!

Once complete, your InsightHR application will be accessible at:
- ✅ https://insight-hr.io.vn
- ✅ https://www.insight-hr.io.vn

With:
- ✅ Valid SSL/TLS certificate
- ✅ Fast global delivery via CloudFront
- ✅ Professional custom domain
- ✅ Automatic HTTPS redirect

---

**Last Updated:** December 5, 2025  
**InsightHR Version:** Phase 7 (In Progress)
