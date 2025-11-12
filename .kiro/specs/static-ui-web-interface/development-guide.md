# Development Guide

## Quick Start

### 1. Initial Setup
```bash
# Clone repository
git clone <repo-url>
cd insighthr-web

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
# Edit .env with values from aws-secret.md

# Start development server
npm run dev
```

### 2. Git Workflow
```bash
# Create feature branch
git checkout -b feat-project-setup

# Make changes, test manually

# Commit after task confirmation
git add .
git commit -m "feat: complete project setup and foundation"
git push origin feat-project-setup

# Create pull request for review
```

## AWS Credentials

**Location:** `aws-secret.md` (DO NOT COMMIT)



**Usage in .env:**
```env
VITE_AWS_ACCESS_KEY_ID=
VITE_AWS_SECRET_ACCESS_KEY=
VITE_AWS_REGION=us-east-1
VITE_API_BASE_URL=https://api.insighthr.com/v1
VITE_COGNITO_USER_POOL_ID=<to-be-provided>
VITE_COGNITO_CLIENT_ID=<to-be-provided>
VITE_GOOGLE_CLIENT_ID=<to-be-provided>
VITE_S3_BUCKET=insighthr-uploads
```

## Technology Stack

### Core
- **React 18** - UI library
- **TypeScript** - Type safety (non-strict mode)
- **Vite** - Build tool optimized for S3 deployment

### UI Components
- **shadcn/ui** - Component library (Tailwind-based)
- **Tailwind CSS** - Utility-first CSS with Frutiger Aero theme
- **Recharts** - Chart library for data visualization

### State & Forms
- **Zustand** - Lightweight state management
- **React Hook Form** - Form handling and validation
- **Axios** - HTTP client for API calls

### Routing
- **React Router v6** - Client-side routing

## Frutiger Aero Theme

### Color Palette
```typescript
// Primary (Cyan/Teal)
primary: {
  50: '#e6f7f7',
  100: '#b3e8e8',
  200: '#80d9d9',
  300: '#4dcaca',
  400: '#1abbbb',
  500: '#00a8a8', // Main
  600: '#008a8a',
  700: '#006b6b',
  800: '#004d4d',
  900: '#002e2e',
}

// Secondary (Green)
secondary: {
  50: '#e6f4e6',
  100: '#b3e0b3',
  200: '#80cc80',
  300: '#4db84d',
  400: '#1aa41a',
  500: '#009000', // Main
  600: '#007500',
  700: '#005a00',
  800: '#004000',
  900: '#002500',
}
```

### Design Principles
- Clean, modern interface
- Gradient backgrounds (green/blue)
- Smooth animations
- Glass morphism effects
- Rounded corners
- Soft shadows

## Development Approach

### Phase 1: UI Frame (Current)
Build full UI components without API integration:
- All components fully styled with Frutiger Aero theme
- Forms functional with validation
- Navigation and routing working
- State management in place
- API service layer stubbed (returns empty data)

### Phase 2: API Integration (Later)
When Lambda functions are ready:
- Replace stubbed API calls with real endpoints
- Connect Cognito authentication
- Integrate S3 file upload
- Connect chatbot to Lex/Bedrock
- Test end-to-end flows

## Component Development Checklist

For each component:
- [ ] Create TypeScript interface for props
- [ ] Build component structure
- [ ] Apply Frutiger Aero styling
- [ ] Add form validation (if applicable)
- [ ] Test component in isolation
- [ ] Ensure works in S3/CloudFront environment
- [ ] Document props and usage

## Testing Strategy

### Manual Testing
- Test each component in isolation
- Test responsive design (1366x768+)
- Test form validation
- Test navigation and routing
- Test state management
- Test error handling

### Browser Testing
- Chrome (primary)
- Firefox
- Safari
- Edge

## Deployment to S3

### Build for Production
```bash
npm run build
```

### Deploy to S3
```bash
# Sync build to S3
aws s3 sync dist/ s3://insighthr-web-app --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

## Common Issues

### Issue: Components not working in S3
**Solution:** Ensure all imports use relative paths, no Node.js-specific APIs

### Issue: Environment variables not loading
**Solution:** Vite requires `VITE_` prefix for env vars

### Issue: Routing 404 on refresh
**Solution:** Configure S3 error document to redirect to index.html

## Project Structure

```
insighthr-web/
├── src/
│   ├── components/
│   │   ├── auth/
│   │   ├── layout/
│   │   ├── admin/
│   │   ├── dashboard/
│   │   ├── upload/
│   │   ├── chatbot/
│   │   ├── profile/
│   │   └── common/
│   ├── pages/
│   ├── services/
│   ├── store/
│   ├── types/
│   ├── utils/
│   ├── hooks/
│   ├── styles/
│   ├── App.tsx
│   ├── main.tsx
│   └── router.tsx
├── public/
├── .env
├── .env.example
├── .gitignore
├── aws-secret.md (DO NOT COMMIT)
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## Resources

- [Vite Documentation](https://vitejs.dev/)
- [React Documentation](https://react.dev/)
- [shadcn/ui Components](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [React Hook Form](https://react-hook-form.com/)
- [Zustand](https://github.com/pmndrs/zustand)
- [Recharts](https://recharts.org/)
