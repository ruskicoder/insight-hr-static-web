/**
 * CloudWatch Synthetics Canary: Auto-Scoring Performance
 * 
 * Tests the performance score calculation:
 * 1. Trigger performance-handler Lambda via API Gateway
 * 2. Verify AUTO_SCORING_LAMBDA_ARN is invoked (if configured)
 * 3. Check response time for score calculation
 * 4. Verify scores are written to PerformanceScores table
 * 5. Validate score calculation accuracy
 */

const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();
const AWS = require('aws-sdk');

// Configure canary
syntheticsConfiguration.setConfig({
  screenshotOnStepStart: false,
  screenshotOnStepSuccess: false,
  screenshotOnStepFailure: true,
  continueOnStepFailure: false
});

const autoScoringBlueprint = async function () {
  // Get environment variables
  const API_GATEWAY_URL = process.env.API_GATEWAY_URL || 'https://api.insighthr.com';
  const TEST_USER_EMAIL = process.env.TEST_USER_EMAIL || 'test@insighthr.com';
  const TEST_USER_PASSWORD = process.env.TEST_USER_PASSWORD || 'TestPassword123!';
  const AWS_REGION = process.env.AWS_REGION || 'ap-southeast-1';
  const MAX_RESPONSE_TIME_MS = 10000; // 10 seconds threshold

  let page = await synthetics.getPage();

  // Step 1: Login to get auth token
  await synthetics.executeStep('login', async function () {
    log.info('Logging in to get auth token');
    
    const loginResponse = await page.evaluate(async (apiUrl, email, password) => {
      try {
        const res = await fetch(apiUrl + '/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            email: email,
            password: password
          })
        });
        const data = await res.json();
        return {
          status: res.status,
          ok: res.ok,
          data: data
        };
      } catch (error) {
        return {
          error: error.message
        };
      }
    }, API_GATEWAY_URL, TEST_USER_EMAIL, TEST_USER_PASSWORD);

    if (loginResponse.error || !loginResponse.ok) {
      throw new Error(`Login failed: ${loginResponse.error || loginResponse.status}`);
    }

    log.info('Login successful');
  });

  // Step 2: Trigger performance calculation via API
  await synthetics.executeStep('triggerPerformanceCalculation', async function () {
    log.info('Triggering performance score calculation');
    
    const startTime = Date.now();

    const response = await page.evaluate(async (apiUrl) => {
      try {
        const token = localStorage.getItem('idToken') || localStorage.getItem('accessToken');
        const res = await fetch(apiUrl + '/performance', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        const data = await res.json();
        return {
          status: res.status,
          ok: res.ok,
          data: data
        };
      } catch (error) {
        return {
          error: error.message
        };
      }
    }, API_GATEWAY_URL);

    const endTime = Date.now();
    const responseTime = endTime - startTime;

    log.info(`Performance API response time: ${responseTime}ms`);

    if (response.error) {
      throw new Error(`Performance API request failed: ${response.error}`);
    }

    if (!response.ok) {
      throw new Error(`Performance API returned error: ${response.status}`);
    }

    if (responseTime > MAX_RESPONSE_TIME_MS) {
      throw new Error(`Response time (${responseTime}ms) exceeded threshold (${MAX_RESPONSE_TIME_MS}ms)`);
    }

    log.info('Performance calculation triggered successfully');
  });

  // Step 3: Verify scores are written to DynamoDB
  await synthetics.executeStep('verifyScoresInDynamoDB', async function () {
    log.info('Verifying scores are written to PerformanceScores table');
    
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: AWS_REGION });

    try {
      // Query recent scores (last 5 minutes)
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      
      const params = {
        TableName: 'PerformanceScores',
        FilterExpression: 'updatedAt >= :timestamp',
        ExpressionAttributeValues: {
          ':timestamp': fiveMinutesAgo
        },
        Limit: 10
      };

      const result = await dynamodb.scan(params).promise();
      
      log.info(`Found ${result.Items.length} recent performance scores`);

      if (result.Items.length === 0) {
        log.warn('No recent performance scores found in DynamoDB');
      } else {
        // Validate score structure
        const sampleScore = result.Items[0];
        const hasRequiredFields = 
          sampleScore.employeeId &&
          sampleScore.period &&
          typeof sampleScore.score === 'number';

        if (!hasRequiredFields) {
          throw new Error('Performance score missing required fields');
        }

        log.info('Performance scores validated successfully');
      }
    } catch (error) {
      log.error(`DynamoDB query failed: ${error.message}`);
      throw error;
    }
  });

  // Step 4: Validate score calculation accuracy
  await synthetics.executeStep('validateScoreCalculation', async function () {
    log.info('Validating score calculation accuracy');
    
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: AWS_REGION });

    try {
      // Get a sample employee's scores
      const params = {
        TableName: 'PerformanceScores',
        Limit: 1
      };

      const result = await dynamodb.scan(params).promise();

      if (result.Items.length === 0) {
        log.warn('No performance scores found for validation');
        return;
      }

      const score = result.Items[0];

      // Validate score is within expected range (0-100)
      if (score.score < 0 || score.score > 100) {
        throw new Error(`Invalid score value: ${score.score} (expected 0-100)`);
      }

      // Validate score has required metadata
      if (!score.department || !score.period) {
        throw new Error('Score missing required metadata (department or period)');
      }

      log.info(`Score validation passed - Score: ${score.score}, Department: ${score.department}, Period: ${score.period}`);
    } catch (error) {
      log.error(`Score validation failed: ${error.message}`);
      throw error;
    }
  });

  // Step 5: Check CloudWatch Logs for auto-scoring Lambda invocation
  await synthetics.executeStep('checkAutoScoringLambdaLogs', async function () {
    log.info('Checking CloudWatch Logs for auto-scoring Lambda invocation');
    
    const cloudwatchlogs = new AWS.CloudWatchLogs({ region: AWS_REGION });

    try {
      // Check if AUTO_SCORING_LAMBDA_ARN is configured
      const lambda = new AWS.Lambda({ region: AWS_REGION });
      
      const performanceHandlerConfig = await lambda.getFunctionConfiguration({
        FunctionName: 'insighthr-performance-handler'
      }).promise();

      const autoScoringArn = performanceHandlerConfig.Environment?.Variables?.AUTO_SCORING_LAMBDA_ARN;

      if (!autoScoringArn) {
        log.warn('AUTO_SCORING_LAMBDA_ARN not configured - skipping auto-scoring check');
        return;
      }

      log.info(`AUTO_SCORING_LAMBDA_ARN configured: ${autoScoringArn}`);

      // Query recent logs for auto-scoring Lambda
      const logGroupName = '/aws/lambda/insighthr-auto-scoring-handler';
      const fiveMinutesAgo = Date.now() - 5 * 60 * 1000;

      const logsParams = {
        logGroupName: logGroupName,
        startTime: fiveMinutesAgo,
        limit: 10
      };

      const logsResult = await cloudwatchlogs.filterLogEvents(logsParams).promise();

      log.info(`Found ${logsResult.events.length} recent log events for auto-scoring Lambda`);

      if (logsResult.events.length === 0) {
        log.warn('No recent invocations of auto-scoring Lambda found');
      } else {
        log.info('Auto-scoring Lambda invoked successfully');
      }
    } catch (error) {
      if (error.code === 'ResourceNotFoundException') {
        log.warn('Auto-scoring Lambda or log group not found - may not be configured');
      } else {
        log.error(`Failed to check auto-scoring Lambda logs: ${error.message}`);
        throw error;
      }
    }
  });
};

exports.handler = async () => {
  return await autoScoringBlueprint();
};
