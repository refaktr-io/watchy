# Watchy Lambda Functions

This directory contains the source code for all Lambda functions used in the Watchy monitoring platform.

## Structure

```
lambda/
├── slack_monitor/          # Slack status monitoring function
│   ├── lambda_function.py  # Main handler
│   └── requirements.txt    # Python dependencies
└── README.md              # This file
```

## Development

### Local Building

Lambda functions are built automatically by the CI/CD pipeline. For local development and testing, you can work directly with the Python files:

```bash
# Test Lambda function locally
cd lambda/slack_monitor
python3 -c "
import lambda_function
import json

# Mock event and context
event = {}
class MockContext:
    def __init__(self):
        self.function_name = 'test'
        self.aws_request_id = 'test-request-id'

result = lambda_function.lambda_handler(event, MockContext())
print(json.dumps(result, indent=2))
"
```

### Testing Locally

You can test Lambda functions locally using the AWS SAM CLI or by running them directly:

```bash
cd lambda/slack_monitor
python3 -c "
import lambda_function
import json

# Mock event and context
event = {}
class MockContext:
    def __init__(self):
        self.function_name = 'test'
        self.aws_request_id = 'test-request-id'

result = lambda_function.lambda_handler(event, MockContext())
print(json.dumps(result, indent=2))
"
```

## Deployment

### Automated (CI/CD Pipeline)

Lambda functions are automatically built and deployed when changes are pushed to the `main` branch or when files in the `lambda/` directory are modified.

The integrated CI/CD pipeline:
1. **Detects changes** to Lambda functions, CloudFormation templates, or workflows
2. **Validates** Python syntax and CloudFormation templates
3. **Builds** Lambda deployment packages with proper versioning
4. **Uploads** to the `watchy-resources` S3 bucket
5. **Deploys** CloudFormation templates with updated Lambda references
6. **Tests** accessibility of all deployed artifacts

**Triggers:**
- Push to `main` branch with changes to `lambda/` or `cloudformation/`
- Manual workflow dispatch
- Pull requests (validation only)

### Manual Deployment

If you need to manually build and deploy a Lambda function:

1. Create the deployment package:
   ```bash
   cd lambda/slack_monitor
   mkdir -p build
   cp lambda_function.py build/
   
   # Install dependencies if any exist in requirements.txt
   if grep -v '^#' requirements.txt | grep -v '^$' > /dev/null 2>&1; then
     pip install -r requirements.txt -t build/
   fi
   
   # Create zip package
   cd build
   zip -r ../slack-monitor.zip .
   cd ..
   ```

2. Upload to S3:
   ```bash
   aws s3 cp slack-monitor.zip s3://watchy-resources/lambda/slack-monitor.zip
   ```

3. Deploy CloudFormation stack:
   ```bash
   aws cloudformation deploy \
     --template-file cloudformation/watchy-monitoring-slack.yaml \
     --stack-name watchy-slack-monitor \
     --parameter-overrides \
       SharedLambdaRoleArn=arn:aws:iam::ACCOUNT:role/WatchyLambdaRole \
       NotificationTopicArn=arn:aws:sns:REGION:ACCOUNT:watchy-notifications \
       ParentStackName=watchy
   ```

## Function Details

### slack_monitor

Monitors Slack service status and publishes metrics to CloudWatch.

**Features:**
- Fetches status from Slack Status API
- Publishes service health metrics to CloudWatch
- Logs incident details to CloudWatch Logs
- Supports smart deduplication of incident notes
- Pure Python implementation (no external dependencies)

**Environment Variables:**
- `API_URL`: Slack Status API endpoint
- `CLOUDWATCH_NAMESPACE`: CloudWatch namespace for metrics
- `CLOUDWATCH_LOG_GROUP`: Log group for incident logs
- `POLLING_INTERVAL_MINUTES`: Polling frequency for deduplication
- `LAMBDA_VERSION`: Function version (set during build)
- `BUILD_DATE`: Build timestamp (set during build)

**Metrics Published:**
- Service health status (0=healthy, 1=notice, 2=incident, 3=outage)
- Active incident count
- API response status

## Adding New Functions

1. Create a new directory under `lambda/`
2. Add your Python code and `requirements.txt`
3. Update the CI/CD workflow to build the new function
4. Create corresponding CloudFormation resources
5. Update this README

## Best Practices

- Keep functions small and focused
- Use environment variables for configuration
- Include proper error handling and logging
- Follow AWS Lambda best practices for performance
- Test locally before pushing to git
- Use structured logging (JSON format)
- Keep deployment packages under 50MB