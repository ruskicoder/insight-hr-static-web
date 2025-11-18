# InsightHR - Static Web Interface

Modern, serverless HR automation platform built with React, TypeScript, and AWS services.

## Features

- ✅ **Authentication**: Email/password and Google OAuth via AWS Cognito
- ✅ **Admin Panel**: KPI management, formula builder, user management
- ✅ **Dashboard**: Performance visualization with charts
- ✅ **File Upload**: CSV/Excel upload with column mapping
- ✅ **Role-Based Access**: Admin, Manager, and Employee roles

## Tech Stack

- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS
- **State**: Zustand
- **Backend**: AWS Lambda + API Gateway + DynamoDB + Cognito
- **Auth**: Google OAuth 2.0

## Quick Start

```bash
# Install dependencies
cd insighthr-web
npm install

# Configure environment
cp .env.example .env
# Add your Google Client ID to .env

# Start dev server
npm run dev
```

## Google OAuth Setup

1. Get Client ID from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Add to `insighthr-web/.env`: `VITE_GOOGLE_CLIENT_ID=your-client-id`
3. Deploy Lambda: `cd lambda/auth && .\deploy-google-oauth.ps1`

See `insighthr-web/README.md` for detailed setup instructions.

## Deployment

```bash
# Build frontend
cd insighthr-web
npm run build

# Deploy to S3
aws s3 sync dist/ s3://insighthr-web-app-sg --region ap-southeast-1

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id E3MHW5VALWTOCI --paths "/*"
```

**Production URL**: https://d2z6tht6rq32uy.cloudfront.net

## Project Structure

```
insighthr-web/          # React frontend
lambda/auth/            # Authentication Lambda functions
stub-api/               # Local development API
.kiro/specs/            # Feature specifications
```

## Documentation

- Frontend: `insighthr-web/README.md`
- Backend: `lambda/auth/README.md`
- Specs: `.kiro/specs/static-ui-web-interface/`
