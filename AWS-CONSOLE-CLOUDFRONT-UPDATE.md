# Update CloudFront via AWS Console (Manual Method)

The automated script is having issues, so let's do this via AWS Console. It's actually faster and easier!

---

## Step-by-Step Guide

### 1. Open AWS CloudFront Console

Go to: https://console.aws.amazon.com/cloudfront/v3/home

### 2. Find Your Distribution

- Look for distribution ID: **E3MHW5VALWTOCI**
- Domain name: **d2z6tht6rq32uy.cloudfront.net**
- Click on the distribution ID to open it

### 3. Edit Distribution Settings

- Click the **"General"** tab
- Click **"Edit"** button (top right)

### 4. Update Alternate Domain Names (CNAMEs)

Scroll down to **"Alternate domain names (CNAMEs)"** section:

- Click **"Add item"**
- Enter: `insight-hr.io.vn`
- Click **"Add item"** again
- Enter: `www.insight-hr.io.vn`

### 5. Update SSL Certificate

Scroll down to **"Custom SSL certificate"** section:

- Select: **"Custom SSL Certificate"**
- From the dropdown, select the certificate that shows:
  - Domain: `insight-hr.io.vn`
  - Or ARN ending in: `...a94eebf5-5edf-4658-9d5c-5ea48ffda11c`

### 6. Save Changes

- Scroll to the bottom
- Click **"Save changes"**

### 7. Wait for Deployment

- Status will show: **"Deploying"** or **"In Progress"**
- Wait 10-15 minutes for deployment to complete
- Status will change to: **"Deployed"**

---

## Verification

After deployment completes (status shows "Deployed"):

### Test Your Domain:

Open in browser:
- https://insight-hr.io.vn
- https://www.insight-hr.io.vn

Both should load your InsightHR application with a valid SSL certificate!

### Check DNS:

```powershell
nslookup insight-hr.io.vn
nslookup www.insight-hr.io.vn
```

Both should resolve to CloudFront IPs.

---

## Troubleshooting

### Can't Find Certificate in Dropdown?

**Check certificate status:**
```powershell
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c --region us-east-1
```

Status should be: **"ISSUED"**

If not issued, wait a bit longer and refresh the CloudFront page.

### Certificate Not Showing?

Make sure you're looking at **us-east-1** region certificates. CloudFront only uses certificates from us-east-1.

### Domain Already in Use Error?

This means another CloudFront distribution is using this domain. Check if you have multiple distributions.

---

## Quick Reference

**Distribution ID:** E3MHW5VALWTOCI  
**Certificate ARN:** arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c  
**Domains to add:**
- insight-hr.io.vn
- www.insight-hr.io.vn

**CloudFront Console:** https://console.aws.amazon.com/cloudfront/v3/home

---

## After Setup Complete

Your InsightHR application will be accessible at:
- ✅ https://insight-hr.io.vn
- ✅ https://www.insight-hr.io.vn

With:
- ✅ Valid SSL certificate
- ✅ Custom domain
- ✅ Fast global delivery via CloudFront

---

**Estimated Time:** 15-20 minutes (including deployment wait time)

**Last Updated:** December 5, 2025
