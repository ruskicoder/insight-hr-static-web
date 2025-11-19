# Known Issues - User Management API

## ✅ FULLY RESOLVED - Task 6.7 Complete

All issues have been resolved. Admin users can now successfully access and manage the user list.

### Issues Fixed

1. **Duplicate user records** - Consolidated into single Admin record with correct Cognito sub
2. **Missing Lambda dependencies** - Redeployed using proper `deploy-lambdas.ps1` script
3. **Status filter bug** - Fixed `status=all` being treated as a filter
4. **Response format mismatch** - Added transformation layer in frontend

### Final Status

✅ Authentication working (real JWT tokens)
✅ Authorization working (Admin role recognized)
✅ User list displays all users from DynamoDB
✅ Filtering by status, role, department works correctly
✅ All CRUD operations functional

### How to Promote User to Admin

```powershell
cd lambda/users
.\set-admin-role.ps1 -Email "your-email@gmail.com"
```

Then clear browser storage and log in again.
