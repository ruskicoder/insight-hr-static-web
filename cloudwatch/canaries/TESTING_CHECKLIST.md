# CloudWatch Monitoring Testing Checklist

Use this checklist to verify that CloudWatch monitoring is working correctly after deployment.

## Pre-Deployment Checks

- [ ] AWS CLI is configured with correct credentials
- [ ] PowerShell 5.1 or later is installed
- [ ] aws-secret.md file exists and contains required values:
  - [ ] CLOUDFRONT_URL
  - [ ] API_GATEWAY_URL
  - [ ] TEST_USER_EMAIL
  - [ ] TEST_USER_PASSWORD
- [ ] Test user account exists in Cognito
- [ ] Test user can log in to InsightHR application

## Deployment Verification

### Step 1: Canary Deployment

- [ ] Run `.\deploy-canaries.ps1` successfully
- [ ] S3 bucket created: `insighthr-canary-artifacts-sg`
- [ ] IAM role created: `CloudWatchSyntheticsRole-InsightHR`
- [ ] SNS topic created: `insighthr-canary-alerts`
- [ ] All 4 canaries created:
  - [ ] insighthr-login-canary
  - [ ] insighthr-dashboard-canary
  - [ ] insighthr-autoscoring-canary
  - [ ] insighthr-chatbot-canary
- [ ] All canaries started successfully

### Step 2: Alarm Creation

- [ ] Run `.\create-alarms.ps1` successfully
- [ ] 8 alarms created:
  - [ ] insighthr-login-canary-alarm
  - [ ] insighthr-dashboard-canary-alarm
  - [ ] insighthr-autoscoring-canary-alarm
  - [ ] insighthr-chatbot-canary-alarm
  - [ ] insighthr-system-health-alarm
  - [ ] insighthr-dashboard-slow-response
  - [ ] insighthr-autoscoring-slow-response
  - [ ] insighthr-chatbot-slow-response

### Step 3: SNS Subscription

- [ ] Subscribe email to SNS topic
- [ ] Receive confirmation email
- [ ] Confirm subscription
- [ ] Subscription status is "Confirmed" (not "PendingConfirmation")

### Step 4: Dashboard Creation

- [ ] Run `.\create-dashboard.ps1` successfully
- [ ] Dashboard created: `InsightHR-Monitoring`
- [ ] Dashboard accessible in AWS Console
- [ ] All widgets visible (may show "No data" initially)

### Step 5: Contributor Insights

- [ ] Run `.\create-contributor-insights.ps1` successfully
- [ ] Query files created:
  - [ ] error-analysis-query.txt
  - [ ] 4xx-errors-query.txt
  - [ ] 5xx-errors-query.txt
  - [ ] auth-failures-query.txt
  - [ ] dynamodb-throttling-query.txt
  - [ ] bedrock-errors-query.txt
  - [ ] prompt-injection-query.txt

## Functional Testing

### Canary Execution (Wait 15-30 minutes after deployment)

#### Login Canary
- [ ] Canary status is "RUNNING"
- [ ] At least one successful run completed
- [ ] Screenshots captured in S3
- [ ] HAR file captured in S3
- [ ] CloudWatch Logs show execution details
- [ ] No errors in logs

#### Dashboard Canary
- [ ] Canary status is "RUNNING"
- [ ] At least one successful run completed
- [ ] Screenshots show dashboard loaded
- [ ] Charts visible in screenshots
- [ ] Response time < 5 seconds
- [ ] No JavaScript errors in logs

#### Auto-Scoring Canary
- [ ] Canary status is "RUNNING"
- [ ] At least one successful run completed
- [ ] Performance API called successfully
- [ ] Response time < 10 seconds
- [ ] DynamoDB queries successful
- [ ] No errors in logs

#### Chatbot Canary
- [ ] Canary status is "RUNNING"
- [ ] At least one successful run completed
- [ ] Chatbot UI loaded
- [ ] Message sent successfully
- [ ] Response received from Bedrock
- [ ] Response time < 15 seconds
- [ ] Prompt injection test executed

### Alarm Testing

#### Success Rate Alarms
- [ ] All alarms initially in "INSUFFICIENT_DATA" state
- [ ] After 2+ canary runs, alarms transition to "OK" state
- [ ] Alarms show correct metric data

#### Response Time Alarms
- [ ] Dashboard slow response alarm in "OK" state
- [ ] Auto-scoring slow response alarm in "OK" state
- [ ] Chatbot slow response alarm in "OK" state

#### Composite Alarm
- [ ] System health alarm in "OK" state
- [ ] Alarm rule correctly references all 4 canary alarms

### Dashboard Testing

- [ ] Dashboard loads without errors
- [ ] Canary success rate widget shows data
- [ ] Canary response time widget shows data
- [ ] Lambda invocations widget shows data
- [ ] Lambda errors widget shows data (should be 0 or low)
- [ ] Lambda duration widget shows data
- [ ] Lambda throttles widget shows data (should be 0)
- [ ] DynamoDB capacity widget shows data
- [ ] DynamoDB errors widget shows data (should be 0)
- [ ] API Gateway requests widget shows data
- [ ] API Gateway errors widget shows data (should be 0 or low)
- [ ] API Gateway latency widget shows data
- [ ] Alarm status widget shows all alarms

### CloudWatch Logs Insights Testing

- [ ] Open CloudWatch Logs Insights console
- [ ] Select log groups: `/aws/lambda/insighthr-*`
- [ ] Copy error-analysis-query.txt content
- [ ] Run query successfully
- [ ] Results show error patterns (if any)
- [ ] Test other queries (4xx, 5xx, auth failures, etc.)

## Failure Simulation Testing

### Test Login Failure Alert

1. [ ] Temporarily change test user password in Cognito
2. [ ] Wait for next login canary run (max 5 minutes)
3. [ ] Verify canary fails
4. [ ] Verify alarm transitions to "ALARM" state
5. [ ] Verify email alert received
6. [ ] Check S3 for failure screenshots
7. [ ] Review CloudWatch Logs for error details
8. [ ] Restore test user password
9. [ ] Verify canary recovers on next run
10. [ ] Verify alarm returns to "OK" state

### Test Dashboard Failure Alert

1. [ ] Temporarily stop performance-handler Lambda
2. [ ] Wait for next dashboard canary run (max 10 minutes)
3. [ ] Verify canary fails or shows errors
4. [ ] Verify alarm transitions to "ALARM" state
5. [ ] Verify email alert received
6. [ ] Restart Lambda
7. [ ] Verify canary recovers

### Test System Health Composite Alarm

1. [ ] Trigger 2+ individual canary failures
2. [ ] Verify composite alarm transitions to "ALARM" state
3. [ ] Verify email alert received with composite alarm details
4. [ ] Resolve individual failures
5. [ ] Verify composite alarm returns to "OK" state

## Performance Validation

### Canary Performance Metrics

- [ ] Login canary average duration: < 10 seconds
- [ ] Dashboard canary average duration: < 15 seconds
- [ ] Auto-scoring canary average duration: < 30 seconds
- [ ] Chatbot canary average duration: < 30 seconds

### Success Rates (After 24 hours)

- [ ] Login canary success rate: > 95%
- [ ] Dashboard canary success rate: > 95%
- [ ] Auto-scoring canary success rate: > 90%
- [ ] Chatbot canary success rate: > 90%

### Alert Response Time

- [ ] Email alerts received within 5 minutes of failure
- [ ] Alert contains canary name and failure reason
- [ ] Alert includes link to canary details

## Documentation Verification

- [ ] README.md is complete and accurate
- [ ] RUNBOOK.md contains all failure scenarios
- [ ] QUICK_START.md provides clear deployment steps
- [ ] TESTING_CHECKLIST.md (this file) is complete
- [ ] aws-secret.md updated with CloudWatch configuration
- [ ] All scripts have clear comments and error handling

## Cost Monitoring

- [ ] Review AWS Cost Explorer for CloudWatch Synthetics charges
- [ ] Verify costs align with estimates (~$37/month)
- [ ] No unexpected charges for S3, CloudWatch Logs, or SNS

## Security Verification

- [ ] Test credentials stored securely (not in version control)
- [ ] IAM role has minimum required permissions
- [ ] S3 bucket has appropriate access controls
- [ ] SNS topic has appropriate access policy
- [ ] CloudWatch Logs retention set appropriately

## Maintenance Tasks

- [ ] Schedule weekly review of canary results
- [ ] Schedule monthly review of alarm thresholds
- [ ] Schedule quarterly review of monitoring coverage
- [ ] Document any incidents in incident log
- [ ] Update RUNBOOK.md with new failure scenarios

## Sign-Off

**Deployment Date**: _______________

**Deployed By**: _______________

**Verified By**: _______________

**Status**: 
- [ ] All checks passed - Production ready
- [ ] Some checks failed - Needs attention
- [ ] Major issues - Not ready for production

**Notes**:
_______________________________________________
_______________________________________________
_______________________________________________

## Troubleshooting Common Issues

### Issue: Canaries stuck in "CREATING" state
**Solution**: Wait 5-10 minutes. If still stuck, check IAM role permissions.

### Issue: Canaries fail with "Navigation timeout"
**Solution**: Check CloudFront URL is accessible. Verify test credentials are correct.

### Issue: No email alerts received
**Solution**: Check SNS subscription is confirmed. Check spam folder. Verify alarm actions are configured.

### Issue: Dashboard shows "No data"
**Solution**: Wait 15-30 minutes for canaries to run and generate metrics. Refresh dashboard.

### Issue: Canaries fail with "Element not found"
**Solution**: UI may have changed. Update canary scripts with new selectors.

### Issue: High costs
**Solution**: Review canary schedules. Consider reducing frequency or disabling non-critical canaries.

## Additional Resources

- [AWS CloudWatch Synthetics Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
- [CloudWatch Synthetics Pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [SNS Email Notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)

---

**Last Updated**: 2025-12-04  
**Version**: 1.0  
**Maintainer**: InsightHR DevOps Team
