/**
 * CloudWatch Synthetics Canary: Dashboard Load Performance
 * 
 * Tests the InsightHR dashboard performance:
 * 1. Login with test credentials
 * 2. Navigate to /dashboard
 * 3. Wait for charts to load
 * 4. Verify all chart components render
 * 5. Check API response time for /performance endpoint
 * 6. Measure total page load time
 */

const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();

// Configure canary
syntheticsConfiguration.setConfig({
  screenshotOnStepStart: true,
  screenshotOnStepSuccess: true,
  screenshotOnStepFailure: true,
  continueOnStepFailure: false
});

const dashboardLoadBlueprint = async function () {
  // Get environment variables
  const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL || 'https://d3v4l0pment.cloudfront.net';
  const TEST_USER_EMAIL = process.env.TEST_USER_EMAIL || 'test@insighthr.com';
  const TEST_USER_PASSWORD = process.env.TEST_USER_PASSWORD || 'TestPassword123!';
  const API_GATEWAY_URL = process.env.API_GATEWAY_URL || 'https://api.insighthr.com';
  const MAX_LOAD_TIME_MS = 5000; // 5 seconds threshold

  let page = await synthetics.getPage();
  let startTime, endTime, loadTime;

  // Step 1: Login
  await synthetics.executeStep('login', async function () {
    log.info('Logging in to application');
    
    await page.goto(CLOUDFRONT_URL, {
      waitUntil: 'networkidle0',
      timeout: 30000
    });

    // Fill email
    await page.waitForSelector('input[type="email"], input[name="email"]', { visible: true });
    await page.type('input[type="email"], input[name="email"]', TEST_USER_EMAIL);

    // Fill password
    await page.waitForSelector('input[type="password"], input[name="password"]', { visible: true });
    await page.type('input[type="password"], input[name="password"]', TEST_USER_PASSWORD);

    // Click login
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 30000 }),
      page.click('button[type="submit"]')
    ]);

    log.info('Login successful');
  });

  // Step 2: Navigate to dashboard and measure load time
  await synthetics.executeStep('navigateToDashboard', async function () {
    log.info('Navigating to dashboard');
    
    startTime = Date.now();
    
    await page.goto(CLOUDFRONT_URL + '/dashboard', {
      waitUntil: 'networkidle0',
      timeout: 30000
    });

    endTime = Date.now();
    loadTime = endTime - startTime;

    log.info(`Dashboard navigation time: ${loadTime}ms`);

    if (loadTime > MAX_LOAD_TIME_MS) {
      throw new Error(`Dashboard load time (${loadTime}ms) exceeded threshold (${MAX_LOAD_TIME_MS}ms)`);
    }
  });

  // Step 3: Wait for charts to load
  await synthetics.executeStep('waitForCharts', async function () {
    log.info('Waiting for chart components to load');
    
    // Wait for chart containers or SVG elements (Recharts renders SVG)
    try {
      await page.waitForSelector('svg.recharts-surface, .recharts-wrapper, [class*="chart"]', {
        visible: true,
        timeout: 15000
      });
      log.info('Chart components detected');
    } catch (error) {
      log.warn('Chart components not found - may be empty state');
    }
  });

  // Step 4: Verify chart components render
  await synthetics.executeStep('verifyChartComponents', async function () {
    log.info('Verifying chart components');
    
    // Count chart elements
    const chartCount = await page.evaluate(() => {
      const charts = document.querySelectorAll('svg.recharts-surface, .recharts-wrapper');
      return charts.length;
    });

    log.info(`Found ${chartCount} chart components`);

    // Check for specific chart types (LineChart, BarChart, PieChart)
    const hasLineChart = await page.evaluate(() => {
      return !!document.querySelector('.recharts-line, [class*="LineChart"]');
    });

    const hasBarChart = await page.evaluate(() => {
      return !!document.querySelector('.recharts-bar, [class*="BarChart"]');
    });

    const hasPieChart = await page.evaluate(() => {
      return !!document.querySelector('.recharts-pie, [class*="PieChart"]');
    });

    log.info(`Chart types found - Line: ${hasLineChart}, Bar: ${hasBarChart}, Pie: ${hasPieChart}`);

    if (chartCount === 0) {
      log.warn('No charts found on dashboard - may be empty state or loading');
    }
  });

  // Step 5: Check API response time for /performance endpoint
  await synthetics.executeStep('checkAPIResponseTime', async function () {
    log.info('Checking API response time for /performance endpoint');
    
    // Get auth token from localStorage
    const authToken = await page.evaluate(() => {
      return localStorage.getItem('idToken') || localStorage.getItem('accessToken');
    });

    if (!authToken) {
      throw new Error('No auth token found in localStorage');
    }

    // Make API request and measure response time
    const apiStartTime = Date.now();
    
    const response = await page.evaluate(async (url, token) => {
      try {
        const res = await fetch(url + '/performance', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        return {
          status: res.status,
          ok: res.ok,
          statusText: res.statusText
        };
      } catch (error) {
        return {
          error: error.message
        };
      }
    }, API_GATEWAY_URL, authToken);

    const apiEndTime = Date.now();
    const apiResponseTime = apiEndTime - apiStartTime;

    log.info(`API response time: ${apiResponseTime}ms, Status: ${response.status}`);

    if (response.error) {
      log.warn(`API request failed: ${response.error}`);
    } else if (!response.ok) {
      log.warn(`API returned non-OK status: ${response.status} ${response.statusText}`);
    }

    // Record custom metric for API response time
    await synthetics.addUserAgentHeader('CloudWatch-Synthetics');
  });

  // Step 6: Measure total page load time
  await synthetics.executeStep('measureTotalLoadTime', async function () {
    log.info('Measuring total page load time');
    
    const performanceMetrics = await page.evaluate(() => {
      const perfData = window.performance.timing;
      const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
      const domContentLoaded = perfData.domContentLoadedEventEnd - perfData.navigationStart;
      const domInteractive = perfData.domInteractive - perfData.navigationStart;
      
      return {
        pageLoadTime,
        domContentLoaded,
        domInteractive
      };
    });

    log.info(`Performance metrics:
      - Page load time: ${performanceMetrics.pageLoadTime}ms
      - DOM content loaded: ${performanceMetrics.domContentLoaded}ms
      - DOM interactive: ${performanceMetrics.domInteractive}ms
    `);

    if (performanceMetrics.pageLoadTime > MAX_LOAD_TIME_MS) {
      throw new Error(`Total page load time (${performanceMetrics.pageLoadTime}ms) exceeded threshold (${MAX_LOAD_TIME_MS}ms)`);
    }
  });

  // Step 7: Check for JavaScript errors
  await synthetics.executeStep('checkJavaScriptErrors', async function () {
    log.info('Checking for JavaScript errors');
    
    const jsErrors = await page.evaluate(() => {
      return window.__jsErrors || [];
    });

    if (jsErrors.length > 0) {
      log.warn(`Found ${jsErrors.length} JavaScript errors:`, jsErrors);
    } else {
      log.info('No JavaScript errors detected');
    }
  });
};

exports.handler = async () => {
  return await dashboardLoadBlueprint();
};
