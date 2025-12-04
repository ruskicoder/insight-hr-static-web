# InsightHR CloudWatch Synthetics Canaries

This directory contains CloudWatch Synthetics canary scripts for monitoring critical InsightHR application workflows.

## Overview

CloudWatch Synthetics canaries are configurable scripts that run on a schedule to monitor your endpoints and APIs. They follow the same routes and perform the same actions as a customer, making it possible to continually verify your customer experience even when you don't have any customer traffic.

## Canaries

### 1. Login Canary (`insighthr-login-canary`)
- **Purpose**: Tests the login flow end-to-end
- **Schedule**: Every 5 minutes
- **Alarm**: 2 consecutive failures
- **Script**: `login-canary.js`

### 2. Dashboard Load Canary (`insighthr-dashboard-canary`)
- **Purpose**: Tests dashboard performance and chart rendering
- **Schedule**: Every 10 minutes
- **Alarm**: Load time > 5 seconds or 2 consecutive failures
- **Script**: `dashboard-canary.js`

### 3. Auto-Scoring Performance Canary (`insighthr-autoscoring-canary`)
- **Purpose**: Tests performance score calculation
- **Schedule**: Every 30 minutes
- **Alarm**: Response time > 10 seconds or calculation errors
- **Script**: `autoscoring-canary.js`

### 4. AI Assistant Response Time Canary (`insighthr-chatbot-canary`)
- **Purpose**: Tests chatbot performance and Bedrock API
- **Schedule**: Every 15 minutes
- **Alarm**: Response time > 15 seconds or 2 consecutive failures
- **Script**: `chatbot-canary.js`

## Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- IAM role for Synthetics with required permissions
- S3 bucket for canary artifacts: `insighthr-canary-artifacts-sg`
- SNS topic for alerts: `insighthr-canary-alerts`

### Deploy Canaries

Use the provided PowerShell scripts to deploy canaries:

```powershell
# Deploy all canaries
.\deploy-canaries.ps1

# Deploy individual canary
.\deploy-login-canary.ps1
.\deploy-dashboard-canary.ps1
.\deploy-autoscoring-canary.ps1
.\deploy-chatbot-canary.ps1
```

### Create Alarms

```powershell
# Create CloudWatch alarms for all canaries
.\create-alarms.ps1
```

## Testing

Test canaries manually before deployment:

```powershell
# Test locally (requires Synthetics recorder)
node login-canary.js

# Trigger canary in AWS
aws synthetics start-canary --name insighthr-login-canary --region ap-southeast-1
```

## Monitoring

- **CloudWatch Dashboard**: InsightHR-Monitoring
- **SNS Alerts**: insighthr-canary-alerts
- **Artifacts**: s3://insighthr-canary-artifacts-sg/

## Troubleshooting

### Canary Failures

1. Check canary run details in CloudWatch Synthetics console
2. Review screenshots and HAR files in S3 artifacts bucket
3. Check CloudWatch Logs for detailed error messages
4. Verify test credentials are valid
5. Ensure CloudFront URL is accessible

### Common Issues

- **Authentication failures**: Check test user credentials in aws-secret.md
- **Timeout errors**: Increase timeout in canary configuration
- **Element not found**: Update selectors if UI changed
- **Network errors**: Verify API Gateway endpoints are accessible

## Runbook

### Responding to Canary Alerts

1. **Receive SNS notification** with canary name and failure reason
2. **Check CloudWatch dashboard** for system health overview
3. **Review canary artifacts** (screenshots, logs) in S3
4. **Investigate root cause**:
   - Login failures → Check Cognito User Pool status
   - Dashboard failures → Check Lambda/DynamoDB performance
   - Auto-scoring failures → Check performance-handler Lambda logs
   - Chatbot failures → Check Bedrock API status
5. **Take corrective action** based on root cause
6. **Verify fix** by manually triggering canary
7. **Document incident** in incident log

### Escalation

- **1 canary failure**: Investigate within 15 minutes
- **2+ canary failures**: Escalate to on-call engineer immediately
- **All canaries failing**: Critical incident - escalate to engineering lead

## Configuration

Test credentials and endpoints are stored in `aws-secret.md` (not in version control).

Required environment variables:
- `CLOUDFRONT_URL`: CloudFront distribution URL
- `TEST_USER_EMAIL`: Test user email for login
- `TEST_USER_PASSWORD`: Test user password
- `API_GATEWAY_URL`: API Gateway base URL
