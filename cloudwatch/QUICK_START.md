# CloudWatch Monitoring Quick Start Guide

This guide will help you deploy CloudWatch monitoring for InsightHR in under 30 minutes.

## Prerequisites

- AWS CLI configured with credentials for account 151507815244
- PowerShell 5.1 or later
- Access to aws-secret.md file (contains CloudFront URL and test credentials)
- Admin access to AWS Console (for SNS email subscription)

## Step-by-Step Deployment

### Step 1: Deploy Canaries (10 minutes)

```powershell
cd cloudwatch/canaries
.\deploy-canaries.ps1
```

This script will:
- Create S3 bucket for canary artifacts
- Create IAM role for Synthetics
- Create SNS topic for alerts
- Package and deploy all 4 canaries
- Start canaries on their schedules

**Expected output:**
```
✓ S3 bucket created: insighthr-canary-artifacts-sg
✓ IAM role created: CloudWatchSyntheticsRole-InsightHR
✓ SNS topic created: arn:aws:sns:ap-southeast-1:...:insighthr-canary-alerts
✓ Canary created: insighthr-login-canary
✓ Canary created: insighthr-dashboard-canary
✓ Canary created: insighthr-autoscoring-canary
✓ Canary created: insighthr-chatbot-canary
```

### Step 2: Create Alarms (5 minutes)

```powershell
.\create-alarms.ps1
```

This script will:
- Create success rate alarms for each canary
- Create response time alarms
- Create composite alarm for system health

**Expected output:**
```
✓ Alarm created: insighthr-login-canary-alarm
✓ Alarm created: insighthr-dashboard-canary-alarm
✓ Alarm created: insighthr-autoscoring-canary-alarm
✓ Alarm created: insighthr-chatbot-canary-alarm
✓ Composite alarm created: insighthr-system-health-alarm
✓ Alarm created: insighthr-dashboard-slow-response
✓ Alarm created: insighthr-autoscoring-slow-response
✓ Alarm created: insighthr-chatbot-slow-response
```

### Step 3: Subscribe to Email Alerts (2 minutes)

Get the SNS topic ARN from the output of Step 1, then run:

```powershell
aws sns subscribe `
  --topic-arn arn:aws:sns:ap-southeast-1:151507815244:insighthr-canary-alerts `
  --protocol email `
  --notification-endpoint your-email@example.com `
  --region ap-southeast-1
```

**Important:** Check your email and confirm the subscription!

### Step 4: Create Dashboard (5 minutes)

```powershell
.\create-dashboard.ps1
```

This script will:
- Create CloudWatch dashboard with all metrics
- Add widgets for canaries, Lambda, DynamoDB, API Gateway

**Expected output:**
```
✓ Dashboard created successfully
Dashboard name: InsightHR-Monitoring
View dashboard: https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=InsightHR-Monitoring
```

### Step 5: Set Up Error Analysis (5 minutes)

```powershell
.\create-contributor-insights.ps1
```

This script will:
- Create CloudWatch Logs Insights queries for error analysis
- Save queries to .txt files for manual import

**Expected output:**
```
✓ Query saved to error-analysis-query.txt
✓ 4xx errors query saved
✓ 5xx errors query saved
✓ Authentication failures query saved
✓ DynamoDB throttling query saved
✓ Bedrock errors query saved
✓ Prompt injection detection query saved
```

### Step 6: Test Canaries (5 minutes)

```powershell
.\test-canaries.ps1
```

This script will:
- Check status of all canaries
- Display last run results
- Check alarm states
- Verify SNS subscriptions

**Expected output:**
```
Testing: insighthr-login-canary
  Status: RUNNING
  Last run: 2025-12-04T10:30:00Z
  Status: PASSED
  Duration: 3500ms
  ✓ Canary is active and will run on schedule

insighthr-login-canary-alarm : OK
insighthr-dashboard-canary-alarm : OK
insighthr-autoscoring-canary-alarm : OK
insighthr-chatbot-canary-alarm : OK
insighthr-system-health-alarm : OK
```

## Verification Checklist

After deployment, verify the following:

- [ ] All 4 canaries are in RUNNING state
- [ ] All 8 alarms are in OK state (or INSUFFICIENT_DATA initially)
- [ ] SNS email subscription is confirmed
- [ ] Dashboard displays all widgets correctly
- [ ] Canary artifacts are being stored in S3
- [ ] CloudWatch Logs show canary executions

## View Your Monitoring

### CloudWatch Synthetics Console
View canaries and their run history:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#synthetics:canary/list
```

### CloudWatch Alarms Console
View all alarms and their states:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#alarmsV2:
```

### CloudWatch Dashboard
View comprehensive monitoring dashboard:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=InsightHR-Monitoring
```

### CloudWatch Logs Insights
Run error analysis queries:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#logsV2:logs-insights
```

## What Gets Monitored

### Login Canary (Every 5 minutes)
- ✓ CloudFront URL accessibility
- ✓ Login form rendering
- ✓ Authentication flow
- ✓ Token storage
- ✓ Redirect to dashboard

### Dashboard Canary (Every 10 minutes)
- ✓ Dashboard page load time
- ✓ Chart rendering (LineChart, BarChart, PieChart)
- ✓ API response time for /performance endpoint
- ✓ JavaScript errors
- ✓ Performance metrics

### Auto-Scoring Canary (Every 30 minutes)
- ✓ Performance calculation API
- ✓ DynamoDB write operations
- ✓ Score calculation accuracy
- ✓ Auto-scoring Lambda invocation (if configured)
- ✓ Response time

### Chatbot Canary (Every 15 minutes)
- ✓ Chatbot UI loading
- ✓ Message sending
- ✓ Bedrock API response time
- ✓ Response content validation
- ✓ Prompt injection detection

## Troubleshooting

### Canaries Not Running
```powershell
# Check canary status
aws synthetics get-canary --name insighthr-login-canary --region ap-southeast-1

# Start canary if stopped
aws synthetics start-canary --name insighthr-login-canary --region ap-southeast-1
```

### Alarms in ALARM State
1. Check canary run details in AWS Console
2. Review screenshots and HAR files in S3
3. Check CloudWatch Logs for error messages
4. Follow RUNBOOK.md for specific failure scenarios

### No Email Alerts
```powershell
# Check SNS subscriptions
aws sns list-subscriptions-by-topic `
  --topic-arn arn:aws:sns:ap-southeast-1:151507815244:insighthr-canary-alerts `
  --region ap-southeast-1

# Verify subscription is confirmed (not PendingConfirmation)
```

### Dashboard Not Showing Data
- Wait 10-15 minutes for canaries to run and generate metrics
- Refresh dashboard
- Check that canaries are in RUNNING state

## Cost Estimate

CloudWatch Synthetics pricing (ap-southeast-1):
- Canary runs: $0.0012 per run
- 4 canaries running at different intervals
- Estimated monthly cost: ~$50-70

Breakdown:
- Login canary: 8,640 runs/month × $0.0012 = $10.37
- Dashboard canary: 4,320 runs/month × $0.0012 = $5.18
- Auto-scoring canary: 1,440 runs/month × $0.0012 = $1.73
- Chatbot canary: 2,880 runs/month × $0.0012 = $3.46
- S3 storage for artifacts: ~$5/month
- CloudWatch Logs: ~$10/month
- CloudWatch Alarms: $0.10 per alarm × 8 = $0.80
- SNS notifications: $0.50 per 1M requests (negligible)

**Total: ~$37/month** (may vary based on actual usage)

## Next Steps

1. **Monitor for 24 hours** - Let canaries run and collect baseline data
2. **Review dashboard** - Check for any anomalies or patterns
3. **Test alert flow** - Simulate a failure to verify alerts work
4. **Document incidents** - Use RUNBOOK.md for incident response
5. **Optimize thresholds** - Adjust alarm thresholds based on actual performance

## Support

- **Documentation**: See README.md and RUNBOOK.md in cloudwatch/canaries/
- **AWS Support**: https://console.aws.amazon.com/support/
- **CloudWatch Synthetics Docs**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html

## Cleanup (If Needed)

To remove all monitoring resources:

```powershell
# Delete canaries
aws synthetics delete-canary --name insighthr-login-canary --region ap-southeast-1
aws synthetics delete-canary --name insighthr-dashboard-canary --region ap-southeast-1
aws synthetics delete-canary --name insighthr-autoscoring-canary --region ap-southeast-1
aws synthetics delete-canary --name insighthr-chatbot-canary --region ap-southeast-1

# Delete alarms
aws cloudwatch delete-alarms --alarm-names `
  insighthr-login-canary-alarm `
  insighthr-dashboard-canary-alarm `
  insighthr-autoscoring-canary-alarm `
  insighthr-chatbot-canary-alarm `
  insighthr-system-health-alarm `
  insighthr-dashboard-slow-response `
  insighthr-autoscoring-slow-response `
  insighthr-chatbot-slow-response `
  --region ap-southeast-1

# Delete dashboard
aws cloudwatch delete-dashboards --dashboard-names InsightHR-Monitoring --region ap-southeast-1

# Delete SNS topic
aws sns delete-topic --topic-arn arn:aws:sns:ap-southeast-1:151507815244:insighthr-canary-alerts --region ap-southeast-1

# Delete S3 bucket (after emptying it)
aws s3 rm s3://insighthr-canary-artifacts-sg --recursive --region ap-southeast-1
aws s3 rb s3://insighthr-canary-artifacts-sg --region ap-southeast-1
```

---

**Deployment Date**: 2025-12-04  
**Region**: ap-southeast-1 (Singapore)  
**Status**: Ready for deployment
