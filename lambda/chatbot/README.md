# InsightHR Chatbot Lambda Functions

## Overview

This directory contains Lambda functions and configuration for the InsightHR chatbot feature, which uses AWS Bedrock (Claude 3 models) to provide natural language query interface for HR data.

## Status

✅ **Bedrock Configuration Complete** (Task 10)
- Bedrock verified and accessible in ap-southeast-1
- Lambda execution role has required permissions
- Model selected: Claude 3 Haiku (anthropic.claude-3-haiku-20240307-v1:0)
- Ready for Lambda function implementation

✅ **Frontend Chatbot UI Complete** (Task 10.1)
- ChatbotPage component with full-page chat interface
- MessageList component with conversation history display
- MessageInput component with send functionality
- ChatbotInstructions component with usage guide
- Test page at /test/chatbot with mock responses
- Styled with Apple theme (teal/green gradient)

✅ **Chatbot Lambda Handler Complete** (Task 10.2)
- chatbot-handler Lambda function deployed
- API Gateway integration configured
- Bedrock integration working
- Role-based data filtering implemented
- Enhanced behavior for underperformers implemented

⏳ **Pending Implementation** (Task 10.3)
- Frontend integration with chatbot service
- End-to-end testing with real Bedrock

## Files

- `BEDROCK-CONFIGURATION.md` - Comprehensive Bedrock setup documentation
- `test-bedrock-access.ps1` - PowerShell script to verify Bedrock access
- `chatbot_handler.py` - (To be created) Main Lambda function for chatbot
- `requirements.txt` - (To be created) Python dependencies

## Architecture

```
User → React Chatbot UI → API Gateway → chatbot-handler Lambda
                                              ↓
                                        AWS Bedrock (Claude 3 Haiku)
                                              ↓
                                        DynamoDB (Employees, PerformanceScores)
                                              ↓
                                        Formatted Response → User
```

## Environment Variables

The chatbot-handler Lambda will use these environment variables:

```bash
BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0
BEDROCK_REGION=ap-southeast-1
EMPLOYEES_TABLE=insighthr-employees-dev
PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev
USERS_TABLE=insighthr-users-dev
AWS_REGION=ap-southeast-1
```

## Chatbot Capabilities

The chatbot will support these query types:

1. **Employee Information**
   - "List all employees in DEV department"
   - "Who is employee DEV-001?"
   - "How many employees are in QA?"

2. **Performance Queries**
   - "What's the average score for Q1 2025?"
   - "Show top performers in DEV department"
   - "Who has the highest score?"

3. **Department Statistics**
   - "Compare DEV and QA performance"
   - "Department performance breakdown"
   - "Which department has the most employees?"

4. **Trend Analysis**
   - "Performance trends over quarters"
   - "Which department improved most?"
   - "Show score distribution"

## Scope Limitations

The chatbot is designed ONLY for HR data queries. It will:

- ✅ Answer questions about employees, performance scores, departments, and trends
- ❌ Reject unrelated questions (weather, sports, general knowledge, etc.)
- ❌ Not provide navigation help ("How do I access the dashboard?")
- ❌ Not engage in general conversation

**Example rejection response:**
"I'm an HR assistant focused on employee and performance data. I can help you with questions about employees, performance scores, departments, and trends. Please ask an HR-related question."

## Role-Based Access

The chatbot respects role-based access control according to company policy:

- **Admin**: Can query all employees and all performance data across all departments
- **Manager**: Can query employees and performance data for their department only
- **Employee**: Can query only their own performance data, no access to employee list

**Important**: The chatbot will politely inform users when they request data they don't have permission to access based on their role.

## Testing

### Verify Bedrock Access

```powershell
# Run test script
./test-bedrock-access.ps1
```

### Manual Testing

```bash
# List available Bedrock models
aws bedrock list-foundation-models --region ap-southeast-1 --query 'modelSummaries[?contains(modelId, `claude`)].{ModelId:modelId, Status:modelLifecycle.status}' --output table

# Verify Lambda role permissions
aws iam get-policy-version --policy-arn arn:aws:iam::151507815244:policy/insighthr-lambda-custom-policy --version-id v3 --query 'PolicyVersion.Document.Statement[?Sid==`BedrockAccess`]'
```

## Cost Estimation

**Claude 3 Haiku Pricing**:
- Input: $0.25 per million tokens
- Output: $1.25 per million tokens

**Estimated cost per query**: ~$0.000375  
**Estimated monthly cost** (1000 queries): ~$0.375

Very cost-effective for MVP!

## Next Steps

1. **Task 10.1**: Create frontend chatbot UI components
   - ChatbotPage with message history
   - MessageInput with send button
   - MessageList with conversation display

2. **Task 10.2**: Create chatbot-handler Lambda function
   - Implement Bedrock integration
   - Build context from DynamoDB
   - Format responses for frontend

3. **Task 10.3**: Deploy and test
   - Deploy Lambda to ap-southeast-1
   - Create API Gateway endpoint
   - Test end-to-end chatbot flow

## References

- [Bedrock Configuration Documentation](./BEDROCK-CONFIGURATION.md)
- [InsightHR Spec Requirements 7.1-7.5](../../.kiro/specs/static-ui-web-interface/requirements.md)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Claude 3 Models](https://docs.anthropic.com/claude/docs/models-overview)

---

**Last Updated**: 2025-11-28  
**Status**: Bedrock configured, ready for implementation
