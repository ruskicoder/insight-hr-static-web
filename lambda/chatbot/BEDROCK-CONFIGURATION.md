# AWS Bedrock Configuration for InsightHR Chatbot

## Overview

This document describes the AWS Bedrock configuration for the InsightHR chatbot feature. Bedrock provides access to foundation models (LLMs) that power the natural language query interface for HR data.

## Configuration Status

✅ **Bedrock is configured and ready for use**

- **Region**: ap-southeast-1 (Singapore)
- **Status**: ACTIVE
- **Lambda Role**: insighthr-lambda-execution-role-dev
- **Permissions**: ✅ Configured (bedrock:InvokeModel, bedrock:InvokeModelWithResponseStream)
- **Verification Date**: 2025-11-28

## Available Models

### Recommended Model: Claude 3 Haiku

**Model ID**: `anthropic.claude-3-haiku-20240307-v1:0`

**Characteristics**:
- **Speed**: Fast response time (~1-2 seconds)
- **Cost**: Most cost-effective Claude 3 model
- **Capability**: Good for conversational queries and data retrieval
- **Context Window**: 200K tokens
- **Use Case**: Perfect for HR chatbot queries (employee lookup, performance stats, department info)

**Why Haiku?**
- Fast enough for real-time chat experience
- Cost-effective for MVP deployment
- Sufficient capability for structured data queries
- Good at following instructions and formatting responses

### Alternative Model: Claude 3.5 Sonnet v2

**Model ID**: `anthropic.claude-3-5-sonnet-20241022-v2:0`

**Characteristics**:
- **Speed**: Moderate response time (~2-4 seconds)
- **Cost**: Higher cost than Haiku
- **Capability**: More advanced reasoning and analysis
- **Context Window**: 200K tokens
- **Use Case**: Complex queries, trend analysis, recommendations

**When to use Sonnet?**
- Need more sophisticated analysis
- Complex multi-step reasoning required
- Budget allows for higher costs
- User feedback indicates Haiku responses are insufficient

## Lambda IAM Permissions

The Lambda execution role (`insighthr-lambda-execution-role-dev`) has the following Bedrock permissions:

```json
{
  "Sid": "BedrockAccess",
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "*"
}
```

**Permissions Explained**:
- `bedrock:InvokeModel`: Call Bedrock models synchronously (standard request/response)
- `bedrock:InvokeModelWithResponseStream`: Call Bedrock models with streaming responses (for real-time typing effect)

## Environment Variables for Chatbot Lambda

When creating the `chatbot-handler` Lambda function, set these environment variables:

```bash
BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0
BEDROCK_REGION=ap-southeast-1
EMPLOYEES_TABLE=insighthr-employees-dev
PERFORMANCE_SCORES_TABLE=insighthr-performance-scores-dev
USERS_TABLE=insighthr-users-dev
AWS_REGION=ap-southeast-1
```

## Bedrock API Usage

### Request Format (Claude 3 Models)

```python
import boto3
import json

bedrock_runtime = boto3.client('bedrock-runtime', region_name='ap-southeast-1')

# Prepare the request body
body = {
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 1000,
    "messages": [
        {
            "role": "user",
            "content": "What is the average performance score for the DEV department in Q1 2025?"
        }
    ],
    "temperature": 0.7,
    "top_p": 0.9
}

# Invoke the model
response = bedrock_runtime.invoke_model(
    modelId='anthropic.claude-3-haiku-20240307-v1:0',
    body=json.dumps(body)
)

# Parse the response
response_body = json.loads(response['body'].read())
assistant_message = response_body['content'][0]['text']
```

### Response Format

```json
{
  "id": "msg_01XYZ...",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "Based on the performance data, the average score for the DEV department in Q1 2025 is 78.5."
    }
  ],
  "model": "claude-3-haiku-20240307",
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 150,
    "output_tokens": 25
  }
}
```

## Chatbot Implementation Strategy

### 1. Query Understanding

The chatbot should understand these query types:

- **Employee Queries**: "List all employees in DEV department", "Who is employee DEV-001?"
- **Performance Queries**: "What's the average score for Q1 2025?", "Show top performers"
- **Department Queries**: "Compare DEV and QA performance", "Department statistics"
- **Trend Queries**: "Performance trends over quarters", "Which department improved most?"

### 2. Context Building

Before calling Bedrock, build context from DynamoDB:

```python
def build_context(user_query, user_role, user_department):
    context = {
        "user_role": user_role,
        "user_department": user_department if user_role == "Manager" else None,
        "available_data": {
            "employees": get_employee_count(),
            "departments": ["AI", "DAT", "DEV", "QA", "SEC"],
            "periods": ["2025-1", "2025-2", "2025-3"],
            "total_scores": get_score_count()
        }
    }
    return context
```

### 3. Prompt Engineering

Structure prompts to guide Bedrock responses:

```python
system_prompt = """You are an HR assistant for InsightHR. You help users query employee and performance data.

Available data:
- Employees: 300 employees across 5 departments (AI, DAT, DEV, QA, SEC)
- Performance Scores: Quarterly scores for 2025 (Q1, Q2, Q3)
- Departments: AI (56), DAT (54), DEV (99), QA (49), SEC (42)

Guidelines:
- Provide concise, accurate answers based on the data
- Format numbers clearly (e.g., "78.5" not "78.50000")
- Use tables for comparisons
- Suggest follow-up queries when relevant
- If data is not available, say so clearly

User role: {user_role}
{department_context}
"""

user_message = f"Data: {json.dumps(query_results)}\n\nUser query: {user_query}"
```

### 4. Response Formatting

Format Bedrock responses for the frontend:

```python
def format_response(bedrock_response, query_results):
    return {
        "message": bedrock_response['content'][0]['text'],
        "data": query_results,  # Include raw data for frontend rendering
        "suggestions": generate_suggestions(user_query),
        "timestamp": datetime.now().isoformat()
    }
```

## Cost Estimation

### Claude 3 Haiku Pricing (as of 2025)

- **Input**: $0.25 per million tokens
- **Output**: $1.25 per million tokens

### Example Cost Calculation

Assuming average chatbot interaction:
- Input: 500 tokens (context + user query)
- Output: 200 tokens (assistant response)

**Cost per interaction**:
- Input: 500 tokens × $0.25 / 1M = $0.000125
- Output: 200 tokens × $1.25 / 1M = $0.000250
- **Total**: ~$0.000375 per interaction

**Monthly cost estimate** (1000 queries/month):
- 1000 queries × $0.000375 = **$0.375/month**

Very cost-effective for MVP!

## Testing Bedrock Access

Run the test script to verify Bedrock configuration:

```powershell
# From project root
cd lambda/chatbot
./test-bedrock-access.ps1
```

Or test manually:

```bash
# List available models
aws bedrock list-foundation-models --region ap-southeast-1 --query 'modelSummaries[?contains(modelId, `claude`)].{ModelId:modelId, Status:modelLifecycle.status}' --output table

# Verify Lambda role has Bedrock permissions
aws iam get-policy-version --policy-arn arn:aws:iam::151507815244:policy/insighthr-lambda-custom-policy --version-id v3 --query 'PolicyVersion.Document.Statement[?Sid==`BedrockAccess`]'
```

## Next Steps

1. **Task 10.1**: Create chatbot UI components (ChatbotPage, MessageList, MessageInput)
2. **Task 10.2**: Create chatbot-handler Lambda function with Bedrock integration
3. **Task 10.3**: Deploy and test chatbot with real Bedrock responses

## References

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Claude 3 Model Documentation](https://docs.anthropic.com/claude/docs/models-overview)
- [Bedrock Runtime API Reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html)
- [InsightHR Spec: Requirements 7.1-7.5](../../.kiro/specs/static-ui-web-interface/requirements.md)

## Troubleshooting

### Issue: "AccessDeniedException" when invoking Bedrock

**Solution**: Verify Lambda execution role has `bedrock:InvokeModel` permission:

```bash
aws iam get-policy-version --policy-arn arn:aws:iam::151507815244:policy/insighthr-lambda-custom-policy --version-id v3
```

### Issue: "ModelNotFoundException"

**Solution**: Verify model ID is correct and model is available in ap-southeast-1:

```bash
aws bedrock list-foundation-models --region ap-southeast-1 --query 'modelSummaries[?modelId==`anthropic.claude-3-haiku-20240307-v1:0`]'
```

### Issue: Slow response times

**Solution**: 
1. Check if using correct model (Haiku is fastest)
2. Reduce context size (fewer tokens = faster response)
3. Consider using streaming responses for better UX

### Issue: High costs

**Solution**:
1. Switch from Sonnet to Haiku (5x cheaper)
2. Reduce max_tokens parameter
3. Cache common queries
4. Implement rate limiting

---

**Configuration verified**: 2025-11-28  
**Status**: ✅ Ready for chatbot implementation  
**Next task**: 10.1 - Frontend chatbot UI components
