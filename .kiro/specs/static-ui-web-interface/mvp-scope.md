# MVP Scope - Features to Remove/Simplify

## Features REMOVED from MVP

### Authentication
- ❌ **Password reset flow** - Users contact admin to reset password
- ⚠️ **Backdoor admin account** - Must have emergency admin account in case of lockout

### Profile Management
- ❌ **User profile editing** - Users cannot edit their own profiles
- ❌ **Avatar upload** - No profile photos for MVP

### Admin Panel
- ❌ **Notification history log** - Only configure rules, no history view

### Dashboard
- ❌ **Manual refresh button** - Users use browser refresh

### File Upload
- ❌ **Upload progress indicator** - Use simple loading spinner instead
- ❌ **Pattern detection** - Always create new table (Lambda decides logic)
- ✅ **Data validation** - Lambda handles all validation (no frontend validation)

### Chatbot
- ❌ **Conversation history** - No session history, one-off queries only
- ❌ **Suggested queries** - Remove suggested query buttons
- ✅ **Instructions** - Must display instructions on how to use chatbot

### UI Components
- ❌ **Designed empty states** - Show nothing/blank when no data

## Features KEPT in MVP

### Admin Panel
- ✅ **KPI categories** - Organize KPIs into categories
- ✅ **Formula preview** - Show formula preview before saving

### Dashboard
- ✅ **All 3 chart types** - Line, Bar, Pie (depends on diagnostic data)
- ✅ **Filter by employee** - Individual employee filtering needed

### Error Handling
- ✅ **React error boundaries** - Proper error boundary implementation
- ✅ **Toast notifications** - User feedback via toast messages
- ✅ **Confirm dialogs** - "Are you sure?" dialogs for destructive actions

## Simplified Component List

### Components to REMOVE:
- `PasswordReset.tsx`
- `ProfileEdit.tsx`
- `AvatarUpload.tsx`
- `UploadProgress.tsx`
- `SuggestedQueries.tsx`
- `EmptyState.tsx`

### Components to SIMPLIFY:
- `FileUploader.tsx` - Remove progress bar, use LoadingSpinner
- `ColumnMapper.tsx` - Remove pattern detection logic
- `ChatbotWidget.tsx` - Remove history, add instructions text
- `NotificationRuleManager.tsx` - Remove history log section

## Updated Component Structure

```
src/
├── components/
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── RegisterForm.tsx
│   │   └── GoogleAuthButton.tsx
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   └── MainLayout.tsx
│   ├── admin/
│   │   ├── KPIManager.tsx
│   │   ├── KPIForm.tsx
│   │   ├── KPIList.tsx
│   │   ├── FormulaBuilder.tsx
│   │   ├── FormulaPreview.tsx
│   │   ├── NotificationRuleManager.tsx (simplified)
│   │   └── UserManagement.tsx
│   ├── dashboard/
│   │   ├── PerformanceDashboard.tsx
│   │   ├── DataTable.tsx
│   │   ├── LineChart.tsx
│   │   ├── BarChart.tsx
│   │   ├── PieChart.tsx
│   │   ├── FilterPanel.tsx
│   │   └── ExportButton.tsx
│   ├── upload/
│   │   ├── FileUploader.tsx (simplified)
│   │   ├── ColumnMapper.tsx (simplified)
│   │   └── DataValidator.tsx
│   ├── chatbot/
│   │   ├── ChatbotWidget.tsx (simplified)
│   │   ├── MessageList.tsx
│   │   ├── MessageInput.tsx
│   │   └── ChatbotInstructions.tsx (new)
│   ├── profile/
│   │   └── ProfileView.tsx (read-only)
│   └── common/
│       ├── Button.tsx
│       ├── Input.tsx
│       ├── Select.tsx
│       ├── Modal.tsx
│       ├── LoadingSpinner.tsx
│       ├── ErrorMessage.tsx
│       ├── Toast.tsx
│       ├── ConfirmDialog.tsx
│       └── ErrorBoundary.tsx
```

## API Endpoints to REMOVE

```
❌ POST /auth/forgot-password
❌ POST /auth/reset-password
❌ PUT /users/me (profile editing)
❌ GET /notifications/history
❌ GET /chatbot/session/:sessionId
❌ POST /tables/match (pattern detection)
```

## Estimated Time Savings

By removing these features, we save approximately:
- Password reset: 1-2 days
- Profile editing: 1 day
- Notification history: 1 day
- Pattern detection: 2 days
- Chat history: 1 day
- Progress indicators: 0.5 days

**Total savings: ~6.5-7.5 days** - Helps ensure 1-month timeline is achievable!

## Critical MVP Features (Must Have)

1. ✅ Authentication (email/password + Google OAuth)
2. ✅ KPI management with categories
3. ✅ Formula builder with preview
4. ✅ File upload (simplified)
5. ✅ Dashboard with 3 charts + filters
6. ✅ CSV export
7. ✅ Chatbot (data queries only)
8. ✅ User management (bulk + manual)
9. ✅ Notification rules (no history)
10. ✅ Backdoor admin account
