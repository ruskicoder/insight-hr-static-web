# KPIs Lambda Functions

KPI calculation and aggregation Lambda functions for InsightHR platform.

## Overview

Handles KPI calculations, performance metrics aggregation, and dashboard data.

## Functions

### kpis_handler.py
KPI calculation and aggregation handler.

**Endpoints:**
- `GET /kpis/dashboard` - Get dashboard KPIs (overview cards, trends, distribution)
- `GET /kpis/department/{department}` - Get department-specific KPIs
- `GET /kpis/employee/{employeeId}` - Get employee-specific KPIs
- `GET /kpis/trends` - Get performance trends over time
- `GET /kpis/distribution` - Get score distribution data

## Deployment

```powershell
# Deploy Lambda function
.\deploy-kpis-handler.ps1

# Setup API Gateway endpoints
.\setup-api-gateway.ps1

# Create endpoints
.\create-endpoints.ps1
```

## Environment Variables

- `PERFORMANCE_SCORES_TABLE` - DynamoDB table (insighthr-performance-scores-dev)
- `EMPLOYEES_TABLE` - DynamoDB table (insighthr-employees-dev)
- `ATTENDANCE_TABLE` - DynamoDB table (insighthr-attendance-history-dev)
- `REGION` - AWS region (ap-southeast-1)

## IAM Permissions Required

- `dynamodb:Scan`
- `dynamodb:Query`
- `dynamodb:GetItem`

## API Gateway Integration

- **API ID**: lqk4t6qzag
- **Stage**: prod
- **Base URL**: https://lqk4t6qzag.execute-api.ap-southeast-1.amazonaws.com/prod
- **Authorization**: Cognito User Pool (ap-southeast-1_rzDtdAhvp)

## KPI Calculations

### Dashboard Overview
- Total Employees
- Average Performance Score
- Highest Score
- Lowest Score
- Department Breakdown
- Performance Trends (quarterly)
- Score Distribution

### Department KPIs
- Department average score
- Employee count
- Top performers
- Score trends

### Employee KPIs
- Individual performance scores
- Quarterly trends
- Attendance metrics
- 360 points

## Role-Based Access

- **Admin**: Access to all KPIs across all departments
- **Manager**: Access to department-specific KPIs
- **Employee**: Access to own KPIs only

## Testing

```powershell
# Test KPI endpoints
.\test-kpi-endpoints.ps1

# Test KPI backend
.\test-kpi-backend.ps1

# Simple KPI test
.\test-kpi-simple.ps1
```

## Data Sources

- Performance Scores: 900+ quarterly records
- Employees: 300+ across 5 departments
- Attendance: 9,300+ historical records

## Related

- Frontend: `insighthr-web/src/services/performanceService.ts`
- Store: `insighthr-web/src/store/performanceStore.ts`
- Components: `insighthr-web/src/components/dashboard/PerformanceDashboard.tsx`
