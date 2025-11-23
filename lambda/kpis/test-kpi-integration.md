# KPI Management Integration Test

## Test Date: 2025-11-23
## Task: 8.3 Integration & Deploy - KPI management

## Test Environment
- Frontend: http://localhost:5174
- API Gateway: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev
- DynamoDB Table: insighthr-kpis-dev (ap-southeast-1)
- Lambda Function: insighthr-kpis-handler

## Test Scenarios

### 1. Test KPI List (Empty State)
**URL**: http://localhost:5174/test/kpi
**Expected**: 
- Page loads successfully
- Shows "No KPIs found. Create your first KPI to get started."
- "Create New KPI" button is visible

### 2. Test KPI Creation
**Steps**:
1. Click "Create New KPI" button
2. Fill in form:
   - Name: "Task Completion Rate"
   - Description: "Percentage of tasks completed on time"
   - Data Type: "percentage"
   - Category: "Productivity"
3. Click "Create KPI"

**Expected**:
- Success toast appears: "KPI created successfully"
- Form closes
- KPI appears in the list
- KPI has green "Active" badge

### 3. Test KPI Filtering
**Steps**:
1. Create multiple KPIs with different categories
2. Use category filter dropdown
3. Use search box

**Expected**:
- Filtering works correctly
- Search filters by name and description

### 4. Test KPI Edit
**Steps**:
1. Click "Edit" button on a KPI
2. Modify description
3. Click "Update KPI"

**Expected**:
- Success toast appears: "KPI updated successfully"
- Form closes
- KPI list refreshes with updated data

### 5. Test KPI Disable
**Steps**:
1. Click "Disable" button on a KPI
2. Confirm in dialog

**Expected**:
- Confirmation dialog appears
- After confirm, success toast: "KPI disabled successfully"
- KPI badge changes to red "Disabled"
- "Disable" button changes to "Enable" button

### 6. Test KPI Enable
**Steps**:
1. Click "Enable" button on a disabled KPI
2. Confirm in dialog

**Expected**:
- Confirmation dialog appears
- After confirm, success toast: "KPI enabled successfully"
- KPI badge changes to green "Active"
- "Enable" button changes to "Disable" button

### 7. Test Category Filtering
**Steps**:
1. Create KPIs in different categories
2. Select "Performance" from category filter
3. Select "All Categories"

**Expected**:
- Only Performance KPIs show when filtered
- All KPIs show when "All Categories" selected

### 8. Test Data Type Filtering
**Steps**:
1. Create KPIs with different data types
2. Select "number" from data type filter
3. Select "All Types"

**Expected**:
- Only number KPIs show when filtered
- All KPIs show when "All Types" selected

### 9. Test Status Filtering
**Steps**:
1. Disable some KPIs
2. Select "Active" from status filter
3. Select "Disabled" from status filter
4. Select "All Status"

**Expected**:
- Only active KPIs show when "Active" selected
- Only disabled KPIs show when "Disabled" selected
- All KPIs show when "All Status" selected

### 10. Test Production Page
**URL**: http://localhost:5174/admin/kpis (requires Admin login)
**Expected**:
- Same functionality as test page
- Integrated with MainLayout
- Navigation works correctly

## Test Results

### Manual Testing Results (to be filled after testing)

#### Test 1: KPI List (Empty State)
- [ ] PASS / [ ] FAIL
- Notes: 

#### Test 2: KPI Creation
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 3: KPI Filtering
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 4: KPI Edit
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 5: KPI Disable
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 6: KPI Enable
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 7: Category Filtering
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 8: Data Type Filtering
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 9: Status Filtering
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 10: Production Page
- [ ] PASS / [ ] FAIL
- Notes:

## Issues Found
(List any issues discovered during testing)

## Next Steps
1. Fix any issues found
2. Build production bundle
3. Deploy to S3
4. Test on live CloudFront site
