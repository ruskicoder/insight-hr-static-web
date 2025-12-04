# InsightHR Canary Alert Runbook

This runbook provides step-by-step procedures for responding to CloudWatch Synthetics canary alerts.

## Table of Contents

1. [Alert Response Overview](#alert-response-overview)
2. [Login Canary Failures](#login-canary-failures)
3. [Dashboard Canary Failures](#dashboard-canary-failures)
4. [Auto-Scoring Canary Failures](#auto-scoring-canary-failures)
5. [Chatbot Canary Failures](#chatbot-canary-failures)
6. [System Health Composite Alarm](#system-health-composite-alarm)
7. [Escalation Procedures](#escalation-procedures)

---

## Alert Response Overview

### When You Receive an Alert

1. **Acknowledge the alert** within 5 minutes
2. **Check the CloudWatch dashboard** for system health overview
3. **Review canary artifacts** (screenshots, logs, HAR files) in S3
4. **Investigate root cause** using the specific runbook section below
5. **Take corrective action** based on findings
6. **Verify fix** by manually triggering the canary or waiting for next scheduled run
7. **Document the incident** in incident log

### Alert Severity Levels

- **P1 (Critical)**: All canaries failing or system health alarm triggered
  - Response time: Immediate (within 5 minutes)
  - Escalation: Engineering lead immediately
  
- **P2 (High)**: 2+ canaries failing
  - Response time: Within 15 minutes
  - Escalation: On-call engineer
  
- **P3 (Medium)**: Single canary failing
  - Response time: Within 30 minutes
  - Escalation: If not resolved within 1 hour

---

## Login Canary Failures

### Symptoms
- Users unable to log in
- Authentication errors
- Redirect failures after login

### Investigation Steps

1. **Check Cognito User Pool status**
   ```powershell
   aws cognito-idp describe-user-pool --user-pool-id <USER_POOL_ID> --region ap-southeast-1
   ```

2. **Review auth Lambda logs**
   ```powershell
   aws logs tail /aws/lambda/insighthr-auth-login-handler --follow --region ap-southeast-1
   ```

3. **Check canary artifacts in S3**
   - Navigate to: `s3://insighthr-canary-artifacts-sg/canary-artifacts/insighthr-login-canary/`
   - Review latest screenshots to see where login failed
   - Check HAR file for network errors

4. **Test login manually**
   - Go to CloudFront URL
   - Attempt login with test credentials
   - Check browser console for JavaScript errors

### Common Root Causes

#### Cognito User Pool Issues
- **Symptom**: 400/500 errors from Cognito
- **Fix**: Check Cognito service health, verify user pool configuration
- **Command**: 
  ```powershell
  aws cognito-idp admin-get-user --user-pool-id <USER_POOL_ID> --username <TEST_USER_EMAIL> --region ap-southeast-1
  ```

#### Lambda Function Errors
- **Symptom**: Lambda timeout or error in logs
- **Fix**: Check Lambda logs, increase timeout if needed, verify DynamoDB access
- **Command**:
  ```powershell
  aws lambda get-function-configuration --function-name insighthr-auth-login-handler --region ap-southeast-1
  ```

#### Frontend Issues
- **Symptom**: JavaScript errors in canary logs
- **Fix**: Check CloudFront distribution, verify S3 bucket has latest build
- **Command**:
  ```powershell
  aws cloudfront get-distribution --id <DISTRIBUTION_ID> --region ap-southeast-1
  ```

#### Invalid Test Credentials
- **Symptom**: "Invalid username or password" error
- **Fix**: Verify test user exists and credentials are correct in aws-secret.md
- **Command**:
  ```powershell
  aws cognito-idp admin-get-user --user-pool-id <USER_POOL_ID> --username <TEST_USER_EMAIL> --region ap-southeast-1
  ```

### Resolution Steps

1. Fix identified issue
2. Manually trigger canary to verify fix:
   ```powershell
   aws synthetics start-canary --name insighthr-login-canary --region ap-southeast-1
   ```
3. Monitor next scheduled run
4. Document incident and resolution

---

## Dashboard Canary Failures

### Symptoms
- Dashboard not loading
- Charts not rendering
- Slow page load times (>5 seconds)
- API errors

### Investigation Steps

1. **Check performance Lambda logs**
   ```powershell
   aws logs tail /aws/lambda/insighthr-performance-handler --follow --region ap-southeast-1
   ```

2. **Check DynamoDB table status**
   ```powershell
   aws dynamodb describe-table --table-name PerformanceScores --region ap-southeast-1
   ```

3. **Review canary artifacts**
   - Check screenshots for visual errors
   - Review HAR file for slow API calls
   - Check console logs for JavaScript errors

4. **Test dashboard manually**
   - Login and navigate to /dashboard
   - Open browser DevTools Network tab
   - Check API response times

### Common Root Causes

#### DynamoDB Throttling
- **Symptom**: ProvisionedThroughputExceededException in logs
- **Fix**: Increase read/write capacity or enable auto-scaling
- **Command**:
  ```powershell
  aws dynamodb update-table --table-name PerformanceScores --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 --region ap-southeast-1
  ```

#### Lambda Timeout
- **Symptom**: Task timed out after X seconds
- **Fix**: Increase Lambda timeout or optimize query
- **Command**:
  ```powershell
  aws lambda update-function-configuration --function-name insighthr-performance-handler --timeout 30 --region ap-southeast-1
  ```

#### Empty Data
- **Symptom**: Charts not rendering, no data returned
- **Fix**: Verify PerformanceScores table has data
- **Command**:
  ```powershell
  aws dynamodb scan --table-name PerformanceScores --limit 10 --region ap-southeast-1
  ```

#### Frontend Build Issues
- **Symptom**: JavaScript errors, missing components
- **Fix**: Rebuild and redeploy frontend
- **Commands**:
  ```powershell
  cd insighthr-web
  npm run build
  aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1
  aws cloudfront create-invalidation --distribution-id <ID> --paths "/*" --region ap-southeast-1
  ```

### Resolution Steps

1. Fix identified issue
2. Wait for next scheduled run (10 minutes)
3. Verify dashboard loads correctly
4. Document incident

---

## Auto-Scoring Canary Failures

### Symptoms
- Performance score calculation failing
- Scores not being written to DynamoDB
- Slow response times (>10 seconds)

### Investigation Steps

1. **Check performance handler logs**
   ```powershell
   aws logs tail /aws/lambda/insighthr-performance-handler --follow --region ap-southeast-1
   ```

2. **Check if AUTO_SCORING_LAMBDA_ARN is configured**
   ```powershell
   aws lambda get-function-configuration --function-name insighthr-performance-handler --region ap-southeast-1 | jq '.Environment.Variables.AUTO_SCORING_LAMBDA_ARN'
   ```

3. **Check auto-scoring Lambda logs (if configured)**
   ```powershell
   aws logs tail /aws/lambda/insighthr-auto-scoring-handler --follow --region ap-southeast-1
   ```

4. **Verify recent scores in DynamoDB**
   ```powershell
   aws dynamodb scan --table-name PerformanceScores --filter-expression "updatedAt >= :timestamp" --expression-attribute-values '{":timestamp":{"S":"2024-01-01T00:00:00Z"}}' --region ap-southeast-1
   ```

### Common Root Causes

#### Lambda Invocation Failure
- **Symptom**: Error invoking auto-scoring Lambda
- **Fix**: Check Lambda permissions, verify ARN is correct
- **Command**:
  ```powershell
  aws lambda get-policy --function-name insighthr-auto-scoring-handler --region ap-southeast-1
  ```

#### DynamoDB Write Errors
- **Symptom**: ConditionalCheckFailedException or throttling
- **Fix**: Check table capacity, verify item structure
- **Command**:
  ```powershell
  aws dynamodb describe-table --table-name PerformanceScores --region ap-southeast-1
  ```

#### Calculation Logic Errors
- **Symptom**: Invalid score values or missing fields
- **Fix**: Review Lambda code, check input data
- **Action**: Review Lambda logs for detailed error messages

### Resolution Steps

1. Fix identified issue
2. Manually trigger performance calculation via API
3. Verify scores are written correctly
4. Wait for next canary run (30 minutes)
5. Document incident

---

## Chatbot Canary Failures

### Symptoms
- Chatbot not responding
- Slow response times (>15 seconds)
- Bedrock API errors
- Prompt injection not detected

### Investigation Steps

1. **Check chatbot Lambda logs**
   ```powershell
   aws logs tail /aws/lambda/insighthr-chatbot-handler --follow --region ap-southeast-1
   ```

2. **Check Bedrock API status**
   - Review AWS Service Health Dashboard
   - Check for Bedrock throttling or quota limits

3. **Review canary artifacts**
   - Check screenshots for UI errors
   - Review console logs for API errors

4. **Test chatbot manually**
   - Login and navigate to /chatbot
   - Send test query
   - Check response time and content

### Common Root Causes

#### Bedrock API Throttling
- **Symptom**: ThrottlingException in logs
- **Fix**: Request quota increase or implement retry logic
- **Action**: Contact AWS Support for quota increase

#### Bedrock API Errors
- **Symptom**: 400/500 errors from Bedrock
- **Fix**: Check request format, verify model ID
- **Command**:
  ```powershell
  aws bedrock list-foundation-models --region us-east-1
  ```

#### Lambda Timeout
- **Symptom**: Task timed out after X seconds
- **Fix**: Increase Lambda timeout (Bedrock can be slow)
- **Command**:
  ```powershell
  aws lambda update-function-configuration --function-name insighthr-chatbot-handler --timeout 60 --region ap-southeast-1
  ```

#### Prompt Injection Detection False Negative
- **Symptom**: Malicious prompts not blocked
- **Fix**: Review and update prompt injection detection logic
- **Action**: Update Lambda code with improved detection patterns

#### DynamoDB Access Issues
- **Symptom**: Unable to fetch employee data for context
- **Fix**: Verify Lambda has DynamoDB read permissions
- **Command**:
  ```powershell
  aws lambda get-policy --function-name insighthr-chatbot-handler --region ap-southeast-1
  ```

### Resolution Steps

1. Fix identified issue
2. Test chatbot manually with various queries
3. Wait for next canary run (15 minutes)
4. Verify prompt injection detection works
5. Document incident

---

## System Health Composite Alarm

### Symptoms
- Multiple canaries failing simultaneously
- System-wide outage

### Investigation Steps

1. **Check all canary statuses**
   ```powershell
   .\test-canaries.ps1
   ```

2. **Review CloudWatch dashboard**
   - Check all metrics for anomalies
   - Look for patterns (all Lambda errors, all DynamoDB throttling, etc.)

3. **Check AWS Service Health Dashboard**
   - Verify no AWS service outages in ap-southeast-1

4. **Check CloudFront distribution**
   ```powershell
   aws cloudfront get-distribution --id <DISTRIBUTION_ID> --region ap-southeast-1
   ```

5. **Check API Gateway**
   ```powershell
   aws apigateway get-rest-api --rest-api-id <API_ID> --region ap-southeast-1
   ```

### Common Root Causes

#### AWS Service Outage
- **Symptom**: Multiple AWS services unavailable
- **Fix**: Wait for AWS to resolve, monitor Service Health Dashboard
- **Action**: Communicate status to stakeholders

#### CloudFront Distribution Issue
- **Symptom**: All canaries fail at navigation step
- **Fix**: Check distribution status, verify origin is accessible
- **Command**:
  ```powershell
  aws cloudfront get-distribution --id <DISTRIBUTION_ID> --region ap-southeast-1
  ```

#### API Gateway Issue
- **Symptom**: All API calls failing
- **Fix**: Check API Gateway deployment, verify Cognito authorizer
- **Command**:
  ```powershell
  aws apigateway get-deployments --rest-api-id <API_ID> --region ap-southeast-1
  ```

#### DynamoDB Table Issue
- **Symptom**: All Lambda functions failing with DynamoDB errors
- **Fix**: Check table status, verify not deleted or misconfigured
- **Command**:
  ```powershell
  aws dynamodb list-tables --region ap-southeast-1
  ```

### Resolution Steps

1. Identify root cause (likely infrastructure-level)
2. Fix infrastructure issue
3. Manually trigger all canaries to verify
4. Monitor dashboard for 30 minutes
5. Send all-clear notification
6. Conduct post-incident review

---

## Escalation Procedures

### Escalation Matrix

| Severity | Initial Response | Escalate After | Escalate To |
|----------|-----------------|----------------|-------------|
| P1 (Critical) | Immediate | Immediately | Engineering Lead |
| P2 (High) | 15 minutes | 1 hour | On-call Engineer |
| P3 (Medium) | 30 minutes | 2 hours | Team Lead |

### Escalation Contacts

Update this section with actual contact information:

- **Engineering Lead**: [Name] - [Email] - [Phone]
- **On-call Engineer**: [Rotation] - [PagerDuty/Slack]
- **Team Lead**: [Name] - [Email] - [Phone]
- **AWS Support**: [Support Plan] - [Case Portal]

### Communication Templates

#### Initial Alert
```
[P1/P2/P3] InsightHR Canary Alert: [Canary Name]

Status: Investigating
Time: [Timestamp]
Canary: [Canary Name]
Failure Reason: [Brief description]
Impact: [User impact description]
Investigating: [Your name]

Next update in 15 minutes.
```

#### Resolution
```
[RESOLVED] InsightHR Canary Alert: [Canary Name]

Status: Resolved
Time: [Timestamp]
Duration: [Duration]
Root Cause: [Brief description]
Fix Applied: [What was done]
Verification: [How fix was verified]

Incident report to follow.
```

---

## Useful Commands

### Check Canary Status
```powershell
aws synthetics get-canary --name <CANARY_NAME> --region ap-southeast-1
```

### Get Recent Canary Runs
```powershell
aws synthetics get-canary-runs --name <CANARY_NAME> --max-results 5 --region ap-southeast-1
```

### Manually Trigger Canary
```powershell
aws synthetics start-canary --name <CANARY_NAME> --region ap-southeast-1
```

### Check Alarm Status
```powershell
aws cloudwatch describe-alarms --alarm-names <ALARM_NAME> --region ap-southeast-1
```

### View Lambda Logs
```powershell
aws logs tail /aws/lambda/<FUNCTION_NAME> --follow --region ap-southeast-1
```

### Query CloudWatch Logs Insights
```powershell
aws logs start-query --log-group-name /aws/lambda/<FUNCTION_NAME> --start-time <TIMESTAMP> --end-time <TIMESTAMP> --query-string "fields @timestamp, @message | filter @message like /ERROR/" --region ap-southeast-1
```

---

## Post-Incident Review Template

After resolving an incident, complete this template:

### Incident Summary
- **Date/Time**: 
- **Duration**: 
- **Severity**: 
- **Canary(s) Affected**: 
- **User Impact**: 

### Timeline
- **Detection**: 
- **Investigation Started**: 
- **Root Cause Identified**: 
- **Fix Applied**: 
- **Verification**: 
- **Resolution**: 

### Root Cause
[Detailed description of what caused the incident]

### Resolution
[Detailed description of how the incident was resolved]

### Action Items
1. [Preventive measure 1]
2. [Preventive measure 2]
3. [Documentation update]
4. [Monitoring improvement]

### Lessons Learned
[What went well, what could be improved]

---

## Additional Resources

- [AWS CloudWatch Synthetics Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
- [AWS Service Health Dashboard](https://status.aws.amazon.com/)
- [InsightHR Architecture Documentation](../../README.md)
- [AWS Support Portal](https://console.aws.amazon.com/support/)
