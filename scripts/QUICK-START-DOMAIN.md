# Quick Start: Custom Domain Setup

## TL;DR - 3 Simple Steps

### Step 1: Run Setup Script (5 minutes)
```powershell
.\scripts\setup-route53-domain.ps1
```
**Save the nameservers shown at the end!**

---

### Step 2: Update Domain Registrar (5 minutes)
1. Log in to where you bought `insight-hr.io.vn`
2. Find DNS/Nameserver settings
3. Replace with the 4 AWS nameservers from Step 1
4. Save

**Wait 1-2 hours for DNS propagation**

---

### Step 3: Update CloudFront (2 minutes)
```powershell
.\scripts\update-cloudfront-domain.ps1
```

**Wait 10-15 minutes for deployment**

---

## Done! 🎉

Your site is now live at:
- https://insight-hr.io.vn
- https://www.insight-hr.io.vn

---

## Check Status Anytime

```powershell
.\scripts\check-domain-status.ps1
```

---

## Troubleshooting

**Certificate stuck?**
- Wait longer (DNS propagation can take 1-48 hours)
- Verify nameservers are correct at your registrar

**CloudFront update fails?**
- Make sure certificate status is "ISSUED"
- Run: `aws acm describe-certificate --certificate-arn <ARN> --region us-east-1`

**Site not loading?**
- DNS propagation takes time (up to 48 hours)
- Test with: `nslookup insight-hr.io.vn`
- Clear browser cache

---

## Need More Details?

See the full guide: `.\scripts\DOMAIN-SETUP-GUIDE.md`

---

## What Gets Created

✅ Route53 hosted zone for your domain  
✅ SSL/TLS certificate (free from AWS)  
✅ DNS A records pointing to CloudFront  
✅ www subdomain  
✅ HTTPS enabled automatically  

**Cost:** ~$0.50/month for Route53 hosted zone

---

## Post-Setup (Optional)

Update these if you use them:

**Google OAuth:**
- Add https://insight-hr.io.vn to authorized redirect URIs

**Cognito:**
- Add https://insight-hr.io.vn to callback URLs

**Environment Variables:**
```env
VITE_APP_URL=https://insight-hr.io.vn
```

---

**Questions?** Check the full guide or AWS documentation.
