# KPI Management Lambda

## Overview
This Lambda function handles KPI (Key Performance Indicator) management operations for the InsightHR system.

## Deployment Status
✅ Lambda function deployed: `insighthr-kpis-handler`
✅ ARN: `arn:aws:lambda:ap-southeast-1:151507815244:function:insighthr-kpis-handler`
✅ API Gateway endpoints configured and deployed
✅ CORS enabled on all endpoints
✅ Cognito authorizer configured
✅ Deployment date: 2025-11-23

## API Endpoints
All endpoints are deployed and accessible:

- **GET /kpis** - List all KPIs (with optional filters: category, dataType, isActive)
- **POST /kpis** - Create new KPI (Admin only)
- **GET /kpis/{kpiId}** - Get single KPI by ID
- **PUT /kpis/{kpiId}** - Update KPI (Admin only)
- **DELETE /kpis/{kpiId}** - Soft delete KPI (Admin only, sets isActive=false)

Base URL: `https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev`

## Features
- **Role-based Authorization**: Admin-only operations for create, update, delete
- **Soft Delete**: DELETE operation sets isActive=false instead of removing records
- **Unique Name Validation**: Prevents duplicate KPI names
- **Category Organization**: KPIs can be organized by category
- **Data Type Support**: number, percentage, boolean, text
- **CORS Enabled**: All endpoints support CORS for frontend integration

## Testing
Use the provided test script:
```powershell
# Interactive test (requires manual token from browser)
./test-kpi-simple.ps1
```

Or test manually with curl:
```bash
# List KPIs
curl -H "Authorization: Bearer <token>" https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/kpis

# Create KPI
curl -X POST -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"name":"Customer Satisfaction","description":"Average customer rating","dataType":"number","category":"Customer Service"}' \
  https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/kpis

# Get single KPI
curl -H "Authorization: Bearer <token>" https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/kpis/{kpiId}

# Update KPI
curl -X PUT -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"description":"Updated description"}' \
  https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/kpis/{kpiId}

# Soft delete KPI
curl -X DELETE -H "Authorization: Bearer <token>" https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/dev/kpis/{kpiId}
```

## Environment Variables
- DYNAMODB_KPIS_TABLE: insighthr-kpis-dev

## DynamoDB Table
- Table: insighthr-kpis-dev
- Primary Key: kpiId (String)
- GSI: category-index (category as HASH)
- Status: ACTIVE
- Item Count: 0 (ready for KPI creation)

## Lambda Handler Functions
- `list_kpis()` - Scan all KPIs with optional filters
- `get_kpi()` - Get single KPI by ID
- `create_kpi()` - Create new KPI with validation
- `update_kpi()` - Update existing KPI
- `delete_kpi()` - Soft delete (set isActive=false)

## Error Handling
- 401: Unauthorized (invalid or missing token)
- 403: Forbidden (non-Admin trying Admin-only operations)
- 404: KPI not found
- 400: Bad request (missing required fields, duplicate name)
- 500: Internal server error
