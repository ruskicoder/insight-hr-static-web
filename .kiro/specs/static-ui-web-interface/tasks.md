# Implementation Plan

## Overview

This implementation plan breaks down the InsightHR Static Web Interface MVP into discrete, manageable coding tasks. Each task builds incrementally on previous work, with a focus on delivering core functionality within the 1-month timeline.

**Tech Stack:** React + TypeScript, Vite, Zustand, Axios, Recharts, Tailwind CSS, shadcn/ui, React Hook Form
**Backend:** Python Lambda + API Gateway + DynamoDB (separate implementation)
**Timeline:** 4 weeks (20 working days)

**Development Strategy:**
- Build full UI components first (frame/structure)
- API integration on hold until Lambda functions are ready
- Apply Frutiger Aero theme from the start
- Use component library optimized for S3 deployment
- TypeScript in non-strict mode for rapid development
- Feature branches: `feat-[task-name]`
- Commit after task confirmation

**Build Order:** Login → Dashboard Frame → Admin Frame

---

## Task List

- [x] 1. Project setup and foundation





  - Initialize Vite + React + TypeScript project with required dependencies
  - Install shadcn/ui, React Hook Form, Zustand, Axios, Recharts
  - Configure Tailwind CSS with Frutiger Aero theme (green/blue colors)
  - Set up project structure (components, pages, services, store, types, utils)
  - Create .env files with AWS credentials from aws-secret.md
  - Create .env.example with placeholder values
  - Add aws-secret.md to .gitignore
  - Configure for S3/CloudFront deployment
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 1.1 Configure build and development tools


  - Set up Vite configuration with code splitting and optimization for S3
  - Configure TypeScript in non-strict mode with path aliases
  - Add ESLint and Prettier for code quality
  - Configure build output for static hosting
  - _Requirements: 11.5_

- [x] 1.2 Create theme and global styles


  - Implement Frutiger Aero color palette in theme.ts
  - Create global CSS with typography and spacing variables
  - Set up Tailwind configuration with custom theme
  - _Requirements: 10.2, 10.3_

- [x] 2. Common UI components with Frutiger Aero styling





  - Set up shadcn/ui components (Button, Input, Select, Dialog)
  - Customize components with Frutiger Aero theme (green/blue)
  - Create LoadingSpinner component with theme colors
  - Create Toast notification component
  - Create ConfirmDialog component
  - Create ErrorBoundary component
  - Fully style all components as they are built
  - Test each component in isolation
  - _Requirements: 10.3, 10.5, 9.5, 10.2_

- [ ] 3. Routing and layout structure
  - Set up React Router with route configuration
  - Create MainLayout component with Header and Sidebar
  - Create ProtectedRoute component for role-based access
  - Implement navigation menu with role-based visibility
  - _Requirements: 1.2, 10.1_

- [ ] 4. API service layer (stub for now)
  - Create Axios instance with base configuration
  - Implement request interceptor for JWT token attachment
  - Implement response interceptor for token refresh and error handling
  - Create error handler utility for consistent error messages
  - Note: API calls will return empty/placeholder data until Lambda functions are ready
  - _Requirements: 11.6_

- [ ] 5. Authentication - Cognito integration
  - Install and configure amazon-cognito-identity-js
  - Create authService with login, register, Google OAuth methods
  - Create auth store (Zustand) for user state management
  - Implement token storage and retrieval from localStorage
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [ ] 5.1 Login and registration UI (full UI, API on hold)
  - Create LoginForm component with email/password fields using React Hook Form
  - Create RegisterForm component for self-registration
  - Create GoogleAuthButton component for OAuth flow
  - Create LoginPage with form switching
  - Implement form validation for email and password
  - Fully style with Frutiger Aero theme
  - UI functional, Cognito integration pending Lambda availability
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 5.2 Authentication flow and session management
  - Implement login flow with Cognito authentication
  - Implement Google OAuth flow
  - Implement registration flow
  - Implement logout functionality
  - Implement automatic token refresh on expiration
  - Add backdoor admin account configuration
  - _Requirements: 1.2, 1.5, 1.6_

- [ ] 6. Admin Panel - KPI Management
  - Create KPI types and interfaces (kpi.types.ts)
  - Create kpiService for API calls (getAll, create, update, disable)
  - Create KPI store (Zustand) for state management
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 6.1 KPI UI components
  - Create KPIManager container component
  - Create KPIForm component with name, description, dataType, category fields
  - Create KPIList component with edit and disable actions
  - Implement KPI category organization view
  - Add form validation for KPI creation
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 7. Admin Panel - Formula Builder
  - Create Formula types and interfaces (formula.types.ts)
  - Create formulaService for API calls
  - Create formula store (Zustand)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 7.1 Formula Builder UI
  - Create FormulaBuilder component with semantic input field
  - Implement autocomplete for KPI selection (Ctrl+space trigger)
  - Create weight assignment interface
  - Implement real-time validation (sum = 100%)
  - Create FormulaPreview component to display formula
  - Support both simple and complex expressions
  - Support multiple active formulas
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [ ] 8. Admin Panel - User Management
  - Create User types and interfaces (user.types.ts)
  - Create userService for API calls
  - Create UserManagement component with user list
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 8.1 User creation and bulk import
  - Create manual user creation form (one-by-one)
  - Implement bulk user import from CSV file
  - Add user edit functionality (role, department, employeeId)
  - Implement user disable/enable actions
  - Add search and filter for user list
  - _Requirements: 2.4_

- [ ] 9. Admin Panel - Notification Rules
  - Create Notification types and interfaces
  - Create notificationService for API calls
  - Create NotificationRuleManager component
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 9.1 Notification rule configuration
  - Create condition builder supporting simple and complex logic
  - Implement recipient selection (roles, departments, specific users)
  - Add enable/disable toggle for rules
  - Create email template configuration
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. File Upload system
  - Create FileUpload types and interfaces
  - Create uploadService with presigned URL and file processing
  - Create FileUploader component with drag-and-drop
  - Implement file type validation (CSV, Excel)
  - Implement file size validation (10,000+ records)
  - Use LoadingSpinner during upload (no progress bar)
  - _Requirements: 5.1, 5.2, 5.6_

- [ ] 10.1 Column mapping (simplified)
  - Create ColumnMapper component
  - Display file headers with KPI dropdown mapping
  - Remove pattern detection - always create new table
  - Implement validation before submission
  - Upload file to S3 using presigned URL
  - Send mapping configuration to API Gateway
  - _Requirements: 5.3, 5.4, 5.5, 5.6_

- [ ] 11. Dashboard - Data display
  - Create Performance types and interfaces
  - Create performanceService for API calls
  - Create performance store (Zustand) with filters
  - Create PerformanceDashboard container component
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 11.1 Dashboard table and filters
  - Create DataTable component with sortable columns
  - Create FilterPanel with department, time period, employee filters
  - Implement role-based data display (Admin/Manager/Employee)
  - Add manual data refresh (browser refresh)
  - _Requirements: 6.1, 6.3, 6.4_

- [ ] 11.2 Dashboard charts
  - Install and configure Recharts library
  - Create LineChart component for performance trends
  - Create BarChart component for comparative performance
  - Create PieChart component for distribution
  - Implement static visualizations (no interactivity)
  - Add responsive design for charts
  - _Requirements: 6.2_

- [ ] 11.3 Data export
  - Create ExportButton component
  - Implement CSV export functionality
  - Apply current filters to export
  - _Requirements: 6.5_

- [ ] 12. Chatbot integration
  - Create ChatMessage and ChatSession types
  - Create chatbotService for API calls to Lex/Bedrock
  - Create ChatbotPage
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 12.1 Chatbot UI (simplified)
  - Create ChatbotWidget component for dedicated tab
  - Create MessageList component (no history persistence)
  - Create MessageInput component
  - Create ChatbotInstructions component with usage guide
  - Remove suggested queries
  - Implement one-off query mode (no session history)
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 13. Profile page (read-only)
  - Create ProfileView component (read-only display)
  - Display user information (name, email, role, department, employeeId)
  - Remove profile editing capability
  - Remove avatar upload
  - _Requirements: 2.1_

- [ ] 14. Admin page integration
  - Create AdminPage component
  - Integrate KPIManager component
  - Integrate FormulaBuilder component
  - Integrate UserManagement component
  - Integrate NotificationRuleManager component
  - Add tab navigation between sections
  - _Requirements: 3.1, 4.1, 8.1_

- [ ] 15. Dashboard page integration
  - Create DashboardPage component
  - Integrate PerformanceDashboard component
  - Integrate FilterPanel component
  - Integrate all chart components
  - Integrate ExportButton component
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 16. Upload page integration
  - Create UploadPage component
  - Integrate FileUploader component
  - Integrate ColumnMapper component
  - Add upload status feedback
  - _Requirements: 5.1, 5.6_

- [ ] 17. Error handling and validation
  - Implement form validators (email, password, required, number, percentage)
  - Add API error handling with user-friendly messages
  - Implement toast notifications for success/error feedback
  - Add confirm dialogs for destructive actions (delete, disable)
  - Test error boundaries
  - _Requirements: 10.5, 10.6_

- [ ] 18. Responsive design and styling
  - Ensure all components are responsive for desktop (1366x768+)
  - Apply consistent Frutiger Aero theme across all pages
  - Implement loading states for all async operations
  - Add visual feedback for user actions
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 19. Testing and bug fixes
  - Test authentication flow (login, register, Google OAuth, logout)
  - Test KPI management (create, edit, disable, categories)
  - Test formula builder (simple and complex expressions, validation)
  - Test user management (manual and bulk creation)
  - Test file upload and column mapping
  - Test dashboard (charts, filters, export)
  - Test chatbot (data queries)
  - Test role-based access control
  - Fix identified bugs
  - _Requirements: All_

- [ ] 20. Deployment preparation
  - Configure environment variables for production
  - Build production bundle with Vite
  - Test production build locally
  - Create deployment script for S3
  - Document deployment process
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

---

## Notes

### Development Approach
- **Build UI frame first**: Create full UI components without API integration
- **API integration on hold**: Lambda functions are being developed separately
- **Component library**: Use shadcn/ui and React Hook Form (optimized for S3 deployment)
- **Chart library**: Use Recharts (optimized for S3 deployment)
- **Styling**: Apply Frutiger Aero theme from the start, fully style as you build
- **Testing**: Manually test each component in isolation
- **Git workflow**: Feature branches (`feat-[task-name]`), commit after task confirmation
- **TypeScript**: Non-strict mode for rapid development
- **AWS credentials**: Stored in aws-secret.md (added to .gitignore)

### MVP Constraints
- Each task should be completed and tested before moving to the next
- Focus on desktop experience (1366x768 and above)
- Use browser refresh instead of manual refresh buttons
- All data validation handled by Lambda (minimal frontend validation)
- No password reset flow - users contact admin
- Backdoor admin account must be configured
- Chatbot shows instructions, no suggested queries
- No empty state designs - show blank/nothing when no data

### Build Order
1. Common components with Frutiger Aero theme
2. Login page (full UI)
3. Dashboard frame (layout + placeholder content)
4. Admin frame (layout + placeholder content)
5. Integrate API calls when Lambda functions become available
