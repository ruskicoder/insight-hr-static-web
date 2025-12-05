# Hướng Dẫn Cập Nhật Nameserver tại Matbao.net
## Guide to Update Nameservers at Matbao.net

---

## Tiếng Việt

### Bước 1: Đăng nhập Matbao.net

1. Truy cập: https://matbao.net
2. Đăng nhập vào tài khoản của bạn
3. Vào mục "Quản lý tên miền" hoặc "Domain Management"

### Bước 2: Chọn tên miền insight-hr.io.vn

1. Tìm tên miền `insight-hr.io.vn` trong danh sách
2. Click vào tên miền để vào trang quản lý
3. Tìm mục "Nameserver" hoặc "DNS Management"

### Bước 3: Thay đổi Nameserver

**Nameserver cần cập nhật:**
```
ns-1213.awsdns-23.org
ns-1875.awsdns-42.co.uk
ns-968.awsdns-57.net
ns-247.awsdns-30.com
```

**Các bước:**
1. Click "Thay đổi Nameserver" hoặc "Change Nameserver"
2. Chọn "Sử dụng Nameserver tùy chỉnh" hoặc "Custom Nameserver"
3. Xóa các nameserver cũ
4. Nhập 4 nameserver AWS ở trên (mỗi dòng một nameserver)
5. Click "Lưu" hoặc "Save"

### Bước 4: Xác nhận

1. Kiểm tra lại 4 nameserver đã nhập đúng chưa
2. Click "Xác nhận" hoặc "Confirm"
3. Đợi email xác nhận từ Matbao.net

### Thời gian chờ đợi

- **Cập nhật tại Matbao:** Ngay lập tức
- **DNS lan truyền:** 1-48 giờ (thường là 1-2 giờ)
- **Xác thực SSL:** 5-30 phút sau khi DNS lan truyền

### Kiểm tra trạng thái

Sau khi cập nhật nameserver, chạy lệnh:
```powershell
.\scripts\check-domain-status.ps1
```

---

## English

### Step 1: Login to Matbao.net

1. Go to: https://matbao.net
2. Login to your account
3. Navigate to "Domain Management" section

### Step 2: Select domain insight-hr.io.vn

1. Find `insight-hr.io.vn` in your domain list
2. Click on the domain to access management page
3. Find "Nameserver" or "DNS Management" section

### Step 3: Change Nameservers

**Nameservers to update:**
```
ns-1213.awsdns-23.org
ns-1875.awsdns-42.co.uk
ns-968.awsdns-57.net
ns-247.awsdns-30.com
```

**Steps:**
1. Click "Change Nameserver"
2. Select "Use Custom Nameserver"
3. Remove old nameservers
4. Enter the 4 AWS nameservers above (one per line)
5. Click "Save"

### Step 4: Confirm

1. Verify all 4 nameservers are entered correctly
2. Click "Confirm"
3. Wait for confirmation email from Matbao.net

### Wait Times

- **Update at Matbao:** Immediate
- **DNS Propagation:** 1-48 hours (usually 1-2 hours)
- **SSL Validation:** 5-30 minutes after DNS propagates

### Check Status

After updating nameservers, run:
```powershell
.\scripts\check-domain-status.ps1
```

---

## Screenshots Guide / Hướng dẫn có ảnh

### 1. Matbao.net Dashboard
Look for "Quản lý tên miền" or "Domain Management"

### 2. Domain List
Find `insight-hr.io.vn` and click on it

### 3. Nameserver Section
Look for one of these:
- "Nameserver"
- "DNS Management"
- "Quản lý DNS"
- "Máy chủ tên miền"

### 4. Change Nameserver
Click button that says:
- "Thay đổi Nameserver"
- "Change Nameserver"
- "Sửa Nameserver"

### 5. Custom Nameserver
Select option:
- "Sử dụng Nameserver tùy chỉnh"
- "Custom Nameserver"
- "Nameserver riêng"

### 6. Enter AWS Nameservers
Enter these 4 nameservers (copy exactly):
```
ns-1213.awsdns-23.org
ns-1875.awsdns-42.co.uk
ns-968.awsdns-57.net
ns-247.awsdns-30.com
```

### 7. Save
Click:
- "Lưu" or "Save"
- "Cập nhật" or "Update"
- "Xác nhận" or "Confirm"

---

## Troubleshooting / Xử lý sự cố

### Không tìm thấy mục Nameserver
**Vietnamese:** Liên hệ support Matbao.net qua chat hoặc hotline  
**English:** Contact Matbao.net support via chat or hotline

### Nameserver không được chấp nhận
**Vietnamese:** Kiểm tra lại chính tả, không có khoảng trắng thừa  
**English:** Check spelling, no extra spaces

### Mất quá nhiều thời gian
**Vietnamese:** DNS lan truyền có thể mất đến 48 giờ, hãy kiên nhẫn  
**English:** DNS propagation can take up to 48 hours, be patient

---

## Support Contacts

**Matbao.net:**
- Website: https://matbao.net
- Hotline: 1900 6680
- Email: support@matbao.net
- Live Chat: Available on website

**AWS Support:**
- Check status: `.\scripts\check-domain-status.ps1`
- View nameservers: `cat nameservers.txt`

---

## Next Steps After Updating Nameservers

1. **Wait 1-2 hours** for DNS propagation
2. **Check certificate status:**
   ```powershell
   .\scripts\check-domain-status.ps1
   ```
3. **Once certificate is ISSUED, run:**
   ```powershell
   .\scripts\setup-domain-step3.ps1
   ```
4. **Your site will be live at:**
   - https://insight-hr.io.vn
   - https://www.insight-hr.io.vn

---

**Last Updated:** December 5, 2025  
**Domain:** insight-hr.io.vn  
**Registrar:** Matbao.net
