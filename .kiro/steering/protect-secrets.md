# Secret and Credential Protection Rules

## CRITICAL: Never Delete Secret Files

You MUST NEVER delete any files containing secrets, credentials, API keys, or sensitive configuration without EXPLICIT user confirmation.

### Protected File Patterns

NEVER delete files matching these patterns:
- `*.env` (environment files)
- `*.env.*` (environment variants like .env.local, .env.production)
- `*secret*` (any file with "secret" in the name)
- `*credential*` (any file with "credential" in the name)
- `*key*` (any file with "key" in the name)
- `*token*` (any file with "token" in the name)
- `*password*` (any file with "password" in the name)
- `*auth*` (any file with "auth" in the name that might contain credentials)
- `*.pem` (private key files)
- `*.key` (key files)
- `*.p12` (certificate files)
- `*.pfx` (certificate files)
- `*.json` files that might contain OAuth credentials (e.g., `client_secret*.json`, `*-credentials.json`)
- Any file listed in `.gitignore` that contains configuration or secrets

### Required Behavior

1. **Before deleting ANY file**, check if it matches the protected patterns above
2. **If it matches**, you MUST ask the user: "This file appears to contain secrets or credentials. Are you absolutely sure you want to delete [filename]?"
3. **Wait for explicit confirmation** before proceeding
4. **If user says "clean up files"** or similar vague requests, NEVER assume they want secrets deleted
5. **When in doubt**, ask for clarification

### Examples of What NOT to Do

❌ User: "clean up the files"
❌ You: *deletes .env, google-oauth-client-secret.json, aws-secret.md*

✅ User: "clean up the files"
✅ You: "I can clean up temporary and build files. I see some files that might contain secrets (.env, google-oauth-client-secret.json, aws-secret.md). Should I delete those too, or keep them?"

### Why This Matters

Deleting secret files causes:
- Loss of irretrievable credentials
- Broken authentication flows
- Hours of recovery work
- Frustrated users
- Security risks if secrets need to be regenerated

## This Rule Applies to ALL Sessions

This steering file ensures these rules persist across all future sessions. You will see this instruction every time you start a new conversation in this workspace.
