/**
 * CloudWatch Synthetics Canary: Simple Login Check
 * Tests basic site availability and login page load
 */

const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const handler = async () => {
  const syntheticsConfiguration = synthetics.getConfiguration();
  syntheticsConfiguration.setConfig({
    screenshotOnStepStart: true,
    screenshotOnStepSuccess: true,
    screenshotOnStepFailure: true,
    continueOnStepFailure: false
  });

  const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL || 'https://d2z6tht6rq32uy.cloudfront.net';
  
  let page = await synthetics.getPage();

  // Step 1: Check if site loads
  await synthetics.executeStep('checkSiteAvailability', async function () {
    log.info('Checking site availability: ' + CLOUDFRONT_URL);
    
    const response = await page.goto(CLOUDFRONT_URL, {
      waitUntil: ['domcontentloaded', 'networkidle0'],
      timeout: 60000
    });

    if (!response) {
      throw new Error('No response from site');
    }

    const status = response.status();
    log.info('Site responded with status: ' + status);

    if (status !== 200) {
      throw new Error('Site returned status ' + status);
    }

    // Wait for page to be interactive
    await page.waitForTimeout(3000);
    
    log.info('Site is available and responding');
  });

  // Step 2: Check if login form exists
  await synthetics.executeStep('checkLoginForm', async function () {
    log.info('Checking for login form elements');
    
    // Wait for email input
    try {
      await page.waitForSelector('#email', {
        visible: true,
        timeout: 10000
      });
      log.info('Email input found');
    } catch (e) {
      log.error('Email input not found');
      throw new Error('Login form not found - email input missing');
    }

    // Wait for password input
    try {
      await page.waitForSelector('#password', {
        visible: true,
        timeout: 10000
      });
      log.info('Password input found');
    } catch (e) {
      log.error('Password input not found');
      throw new Error('Login form not found - password input missing');
    }

    // Wait for submit button
    try {
      await page.waitForSelector('button[type="submit"]', {
        visible: true,
        timeout: 10000
      });
      log.info('Submit button found');
    } catch (e) {
      log.error('Submit button not found');
      throw new Error('Login form not found - submit button missing');
    }

    log.info('Login form check complete - all elements present');
  });

  log.info('Canary completed successfully');
};

exports.handler = handler;
