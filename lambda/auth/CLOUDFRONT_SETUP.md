# CloudFront Distribution Setup - Task 5.7

## Overview
CloudFront distribution has been successfully created and deployed to provide HTTPS access and global CDN caching for the InsightHR web application.

## CloudFront Details
- **Distribution ID**: E3MHW5VALWTOCI
- **Domain**: d2z6tht6rq32uy.cloudfront.net
- **HTTPS URL**: https://d2z6tht6rq32uy.cloudfront.net
- **Status**: Deployed
- **Region**: Global (CloudFront is a global service)
- **Origin**: insighthr-web-app-sg.s3-website-ap-southeast-1.amazonaws.com

## Configuration
- **Origin Protocol**: HTTP only (S3 website endpoints don't support HTTPS)
- **Viewer Protocol**: Redirect HTTP to HTTPS
- **Compression**: Enabled
- **Default Root Object**: index.html
- **Custom Error Responses**:
  - 404 → /index.html (Status: 200) - For SPA routing
  - 403 → /index.html (Status: 200) - For SPA routing
- **Cache Behavior**:
  - Min TTL: 0 seconds
  - Default TTL: 86400 seconds (24 hours)
  - Max TTL: 31536000 seconds (1 year)
- **Price Class**: All edge locations

## Access URLs
You now have two ways to access the application:

1. **CloudFront (HTTPS - Recommended)**:
   - URL: https://d2z6tht6rq32uy.cloudfront.net
   - Benefits: HTTPS, global CDN, faster load times

2. **S3 Direct (HTTP)**:
   - URL: http://insighthr-web-app-sg.s3-website-ap-southeast-1.amazonaws.com
   - Benefits: Direct access, no CDN caching

Both URLs serve the same content from the S3 bucket.

## CORS Configuration
The API Gateway CORS is already configured with `Access-Control-Allow-Origin: *`, which allows requests from both the S3 website endpoint and the CloudFront domain.

## Testing
Run the test script to verify CloudFront is working:
```powershell
.\lambda\auth\test-cloudfront.ps1
```

Test results:
- ✓ HTTPS access working (Status: 200)
- ✓ SPA routing working (404 redirects to index.html)
- ✓ Content delivery successful

## Custom Domain (Future Enhancement)
The CloudFront domain `d2z6tht6rq32uy.cloudfront.net` is auto-generated and cannot be customized.

To use a custom domain like `app.insighthr.com`:
1. Purchase domain via Route 53 or another registrar
2. Request SSL certificate via AWS Certificate Manager (ACM) in us-east-1 region
3. Add custom domain as alternate domain name (CNAME) in CloudFront distribution
4. Create Route 53 alias record pointing to CloudFront distribution

This is outside the MVP scope but can be added later.

## Scripts
- **setup-cloudfront.ps1**: Creates CloudFront distribution
- **test-cloudfront.ps1**: Tests CloudFront functionality
- **update-cors-for-cloudfront.ps1**: Updates API Gateway CORS (not needed - already using wildcard)

## Updated Files
- `aws-secret.md`: Added CloudFront configuration
- `insighthr-web/.env`: Added VITE_CLOUDFRONT_URL and VITE_S3_WEBSITE_URL
- `insighthr-web/.env.example`: Added CloudFront URL placeholders

## Deployment
The CloudFront distribution is now live and serving the application with HTTPS.

To deploy new versions of the frontend:
1. Build: `npm run build` (in insighthr-web folder)
2. Upload to S3: `aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1`
3. Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id E3MHW5VALWTOCI --paths "/*"`

## Notes
- CloudFront deployment took approximately 15-20 minutes
- The distribution is deployed globally to all CloudFront edge locations
- HTTPS is provided free with the default *.cloudfront.net domain
- No custom SSL certificate needed for the default domain
- CloudFront caches content at edge locations for faster delivery
- The S3 website endpoint remains accessible and functional
