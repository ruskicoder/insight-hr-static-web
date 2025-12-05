# What You Need To Do - Matbao.net Nameserver Update

## ✅ What I've Done (Automated)

1. ✅ Created Route53 hosted zone for `insight-hr.io.vn`
2. ✅ Requested SSL certificate from AWS
3. ✅ Created DNS validation records
4. ✅ Created A records pointing to CloudFront
5. ✅ Set up www subdomain

**Zone ID:** `/hostedzone/Z08960594R6LW27WTB1P`  
**Certificate ARN:** `arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c`

---

## ⚠️ What YOU Need To Do (Manual - Only You Can Do This)

### Update Nameservers at Matbao.net

**You MUST update these 4 nameservers at Matbao.net:**

```
ns-1213.awsdns-23.org
ns-1875.awsdns-42.co.uk
ns-968.awsdns-57.net
ns-247.awsdns-30.com
```

**These nameservers are also saved in:** `nameservers.txt`

---

## 📋 Step-by-Step Instructions for Matbao.net

### Quick Steps (Vietnamese/English)

1. **Đăng nhập / Login:** https://matbao.net
2. **Vào / Go to:** "Quản lý tên miền" / "Domain Management"
3. **Chọn / Select:** `insight-hr.io.vn`
4. **Tìm / Find:** "Nameserver" hoặc "DNS Management"
5. **Click:** "Thay đổi Nameserver" / "Change Nameserver"
6. **Chọn / Select:** "Nameserver tùy chỉnh" / "Custom Nameserver"
7. **Nhập / Enter:** 4 nameservers AWS (see above)
8. **Lưu / Save:** Click "Lưu" / "Save"

**Detailed guide with screenshots:** `scripts/MATBAO-NAMESERVER-GUIDE.md`

---

## ⏱️ Timeline After You Update Nameservers

| Step | Time | Status |
|------|------|--------|
| Update at Matbao.net | 5 minutes | ⚠️ **YOU DO THIS** |
| DNS propagation | 1-48 hours | ⏳ Wait |
| Certificate validation | 5-30 minutes | ⏳ Wait |
| Update CloudFront | 2 minutes | ✅ I'll do this |
| CloudFront deployment | 10-15 minutes | ⏳ Wait |
| **Site live!** | **Total: 1-48 hours** | 🎉 Done! |

---

## 🔍 How to Check Status

After updating nameservers at Matbao.net, run this command to check progress:

```powershell
.\scripts\check-domain-status.ps1
```

This will show you:
- ✅ Route53 hosted zone status
- ⏳ Certificate validation status
- ⏳ DNS propagation status
- ⏳ CloudFront configuration status

---

## 🚀 What Happens Next

### After You Update Nameservers:

1. **Wait 1-2 hours** (DNS propagation)
2. **Check status:**
   ```powershell
   .\scripts\check-domain-status.ps1
   ```
3. **When certificate shows "ISSUED", tell me or run:**
   ```powershell
   .\scripts\setup-domain-step3.ps1
   ```
4. **Wait 10-15 minutes** (CloudFront deployment)
5. **Your site will be live at:**
   - https://insight-hr.io.vn
   - https://www.insight-hr.io.vn

---

## 📞 Need Help?

### Matbao.net Support
- **Hotline:** 1900 6680
- **Email:** support@matbao.net
- **Website:** https://matbao.net
- **Live Chat:** Available on website

### Can't Find Nameserver Settings?
Contact Matbao.net support and say:
> "Tôi cần thay đổi nameserver cho tên miền insight-hr.io.vn"
> 
> "I need to change nameservers for domain insight-hr.io.vn"

They will guide you to the right page.

---

## 📝 Summary

**What's done:**
- ✅ AWS Route53 configured
- ✅ SSL certificate requested
- ✅ DNS records created
- ✅ Everything ready on AWS side

**What you need to do:**
- ⚠️ **Update 4 nameservers at Matbao.net** (5 minutes)
- ⏳ **Wait for DNS propagation** (1-48 hours)
- ✅ **Tell me when certificate is ISSUED** (I'll finish the setup)

**Result:**
- 🎉 Your site will be live at https://insight-hr.io.vn

---

## 🔗 Quick Links

- **Matbao.net Login:** https://matbao.net
- **Nameserver Guide:** `scripts/MATBAO-NAMESERVER-GUIDE.md`
- **Check Status Script:** `.\scripts\check-domain-status.ps1`
- **Nameservers File:** `nameservers.txt`

---

**Last Updated:** December 5, 2025  
**Your Domain:** insight-hr.io.vn  
**Current Site:** https://d2z6tht6rq32uy.cloudfront.net  
**Future Site:** https://insight-hr.io.vn
