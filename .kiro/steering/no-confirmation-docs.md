# No Confirmation or Summary Documents

## Rule: Never Create Unnecessary Documentation Files

You MUST NOT create markdown files for the following purposes:
- Confirmation of completed work
- Summary of changes made
- Status updates
- Progress reports
- "What we did" documents
- "Next steps" documents
- Deployment confirmations
- Test result summaries (unless explicitly requested)

## Exceptions (Only create when explicitly requested)

You MAY create documentation files ONLY when:
- The user explicitly asks for documentation
- It's part of the project requirements (e.g., README.md, API documentation)
- It's a technical specification or design document
- It's part of the spec workflow (requirements.md, design.md, tasks.md)

## Examples of BANNED Files

❌ DO NOT CREATE:
- `DEPLOYMENT-SUMMARY.md`
- `CHANGES-MADE.md`
- `TASK-COMPLETION.md`
- `FIX-CONFIRMATION.md`
- `UPDATE-NOTES.md`
- `WORK-SUMMARY.md`
- `STATUS-UPDATE.md`

## What to Do Instead

Instead of creating confirmation documents:
- ✅ Update existing documentation if needed
- ✅ Add comments to code explaining changes
- ✅ Update the spec's design.md or tasks.md if architecture changed
- ✅ Provide a brief verbal summary in your response
- ✅ Mark tasks as complete in tasks.md

## Rationale

Creating unnecessary documentation files:
- Clutters the repository
- Creates noise in version control
- Wastes time
- Provides no long-term value
- Annoys users who have to clean them up

Keep the repository clean and focused on actual project files.
