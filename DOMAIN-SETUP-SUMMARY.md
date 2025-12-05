# Domain Setup Summary for InsightHR

## What Was Done

### 1. Updated Proposal Template ✅

**File:** `Proposal template.md`

**Section 1.3 (Assumptions)** has been updated to reflect the actual implementation status:

**Changes:**
- ✅ All assumptions marked as VALIDATED
- ✅ Added production deployment details
- ✅ Included actual data counts (300+ employees, 900+ scores, 9,300+ attendance records)
- ✅ Updated with current CloudFront URL and new domain
- ✅ Documented all implemented features and their status
- ✅ Added cost estimates and monitoring details

**Key Updates:**
- Technical assumptions validated with actual AWS services deployed
- Business assumptions confirmed with feature completion status
- External dependencies verified with production URLs
- Constraints documented with implementation details
- Risks addressed with actual mitigations implemented

---

### 2. Created Custom Domain Setup Scripts ✅

**New Domain:** `insight-hr.io.vn`

**Scripts Created:**

#### A. `scripts/setup-route53-domain.ps1`
Automated script to:
- Create Route53 hosted zone
- Request ACM SSL certificate (us-east-1)
- Create DNS validation records
- Create A records for domain and www subdomain
- Display nameservers for domain registrar update

#### B. `scripts/update-cloudfront-domain.ps1`
Automated script to:
- Update CloudFront distribution with custom domain
- Attach SSL certificate
- Configure HTTPS with TLS 1.2+
- Deploy changes to CloudFront

#### C. `scripts/check-domain-status.ps1`
Status checking script to verify:
- Route53 hosted zone
- ACM certificate status
- CloudFront configuration
- DNS records
- DNS resolution

#### D. `scripts/DOMAIN-SETUP-GUIDE.md`
Comprehensive documentation including:
- Step-by-step setup instructions
- Manual setup alternative (AWS Console)
- Troubleshooting guide
- Cost estimates
- Post-setup tasks (OAuth, Cognito, env variables)
- Verification checklist
- Timeline summary

#### E. `scripts/QUICK-START-DOMAIN.md`
Quick reference guide with:
- 3-step setup process
- Common troubleshooting
- Status check commands
- Post-setup optional tasks

#### F. Updated `scripts/README.md`
Added domain setup section with:
- Overview of all domain scripts
- Quick start instructions
- Script descriptions
- Cost breakdown

---

## How to Use

### Quick Setup (3 Steps)

#### Step 1: Run Setup Script
```powershell
.\scripts\setup-route53-domain.ps1
```
**Duration:** 5 minutes  
**Output:** Nameservers (save these!)

#### Step 2: Update Domain Registrar
1. Log in to where you purchased `insight-hr.io.vn`
2. Find DNS/Nameserver settings
3. Replace with the 4 AWS nameservers from Step 1
4. Save changes

**Duration:** 5 minutes  
**Wait:** 1-48 hours for DNS propagation (usually 1-2 hours)

#### Step 3: Update CloudFront
```powershell
.\scripts\update-cloudfront-domain.ps1
```
**Duration:** 2 minutes  
**Wait:** 10-15 minutes for CloudFront deployment

### Check Status Anytime
```powershell
.\scripts\check-domain-status.ps1
```

---

## What You'll Get

After completing the setup:

✅ **Custom Domain:** https://insight-hr.io.vn  
✅ **www Subdomain:** https://www.insight-hr.io.vn  
✅ **Valid SSL Certificate:** Free from AWS Certificate Manager  
✅ **HTTPS Enabled:** Automatic redirect from HTTP  
✅ **Global CDN:** Fast delivery via CloudFront  
✅ **Professional URL:** Replace CloudFront default domain  

---

## Cost

**Monthly Costs:**
- Route53 Hosted Zone: $0.50/month
- ACM Certificate: FREE
- CloudFront: No additional cost (already using)
- DNS Queries: $0.40 per million queries

**Total Additional Cost:** ~$0.50-$1.00/month

---

## Timeline

| Step | Duration | Can Start After |
|------|----------|-----------------|
| Run setup script | 5 minutes | Immediately |
| Update nameservers | 5 minutes | Script completes |
| DNS propagation | 1-48 hours | Nameservers updated |
| Certificate validation | 5-30 minutes | DNS propagation |
| Update CloudFront | 2 minutes | Certificate issued |
| CloudFront deployment | 10-15 minutes | CloudFront updated |
| **Minimum Total** | **~30 minutes** | With fast DNS |
| **Maximum Total** | **~48 hours** | With slow DNS |

---

## Post-Setup Tasks (Optional)

### 1. Update Google OAuth
If using Google OAuth, add new redirect URIs:
```
https://insight-hr.io.vn
https://www.insight-hr.io.vn
```

### 2. Update Cognito
Add new callback URLs in Cognito User Pool:
```
https://insight-hr.io.vn
https://www.insight-hr.io.vn
```

### 3. Update Environment Variables
In `insighthr-web/.env`:
```env
VITE_APP_URL=https://insight-hr.io.vn
```

### 4. Update CloudWatch Canaries
Update canary scripts to test new domain:
```javascript
const BASE_URL = 'https://insight-hr.io.vn';
```

---

## Troubleshooting

### Certificate Stuck in "PENDING_VALIDATION"
**Cause:** Nameservers not updated at registrar  
**Solution:** Verify nameservers, wait 1-2 hours, check again

### DNS Not Resolving
**Cause:** DNS propagation not complete  
**Solution:** Wait up to 48 hours, test with `nslookup insight-hr.io.vn`

### Browser Shows Certificate Error
**Cause:** CloudFront not updated or certificate not issued  
**Solution:** Verify certificate is "ISSUED", re-run update script

### CloudFront Update Fails
**Cause:** Certificate not in us-east-1 or not issued  
**Solution:** Verify certificate region and status

---

## Support Commands

```powershell
# Check certificate status
aws acm describe-certificate --certificate-arn <ARN> --region us-east-1

# Check CloudFront deployment
aws cloudfront get-distribution --id <DISTRIBUTION_ID>

# Test DNS resolution
nslookup insight-hr.io.vn
nslookup www.insight-hr.io.vn

# List Route53 records
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

---

## Documentation Files

All documentation is in the `scripts/` folder:

1. **QUICK-START-DOMAIN.md** - Quick 3-step guide
2. **DOMAIN-SETUP-GUIDE.md** - Comprehensive guide with troubleshooting
3. **README.md** - Updated with domain setup section

---

## Current Status

**Before Setup:**
- URL: https://d2z6tht6rq32uy.cloudfront.net
- Domain: CloudFront default
- SSL: CloudFront default certificate

**After Setup:**
- URL: https://insight-hr.io.vn
- Domain: Custom domain
- SSL: Custom ACM certificate
- www: https://www.insight-hr.io.vn

---

## Next Steps

1. **Run the setup script** when you're ready to configure the domain
2. **Update nameservers** at your domain registrar (critical step)
3. **Wait for DNS propagation** (1-48 hours, usually 1-2 hours)
4. **Run the CloudFront update script** once certificate is issued
5. **Test your new domain** in a browser
6. **Update OAuth and Cognito** settings (optional but recommended)
7. **Update environment variables** in your app

---

## Questions?

- Check the full guide: `scripts/DOMAIN-SETUP-GUIDE.md`
- Check status: `.\scripts\check-domain-status.ps1`
- AWS Documentation: https://docs.aws.amazon.com/route53/
- CloudFront Documentation: https://docs.aws.amazon.com/cloudfront/

---

**Last Updated:** December 5, 2025  
**InsightHR Version:** Phase 7 (In Progress)  
**Current CloudFront:** d2z6tht6rq32uy.cloudfront.net  
**Target Domain:** insight-hr.io.vn
