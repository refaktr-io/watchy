# Technology Stack

## Infrastructure as Code
- **CloudFormation**: All infrastructure defined in YAML templates
- **Nested Stacks**: Parent stack manages shared resources, child stacks handle specific SaaS monitoring
- **S3**: Template and Lambda package storage in `watchy-resources` bucket

## Runtime Environment
- **AWS Lambda**: Python 3.14 runtime for monitoring functions
- **Architecture**: ARM64 for optimal price-performance
- **No External Dependencies**: Uses only Python standard library + boto3
- **Memory**: 256MB (optimized for fast cold starts)
- **Timeout**: 240 seconds default (configurable)

## AWS Services Used
- **CloudWatch**: Metrics, alarms, dashboards, and logs
- **SNS**: Email notifications for incidents
- **EventBridge**: Scheduled monitoring (default: every 5 minutes)
- **IAM**: Least-privilege roles and policies
- **Lambda**: Serverless monitoring functions

## Development Stack
- **Python 3.14**: Lambda runtime language
- **GitHub Actions**: CI/CD pipeline for automated deployment
- **JSON**: Configuration and data exchange format

## Common Commands

### Deployment
```bash
# Deploy complete platform
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-platform.yaml \
  --stack-name Watchy-Platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides NotificationEmail=your-email@domain.com

# Deploy standalone Slack monitoring
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-monitoring-slack.yaml \
  --stack-name watchy-slack-monitoring \
  --capabilities CAPABILITY_NAMED_IAM
```

### Testing and Debugging
```bash
# Test Slack Status API directly
curl -s https://status.slack.com/api/v2.0.0/current | jq '.'

# Invoke Lambda function manually
aws lambda invoke \
  --function-name Watchy-Platform-SlackMonitor \
  --payload '{}' response.json

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/watchy"
```

### Stack Management
```bash
# Update stack
aws cloudformation deploy --template-url <url> --stack-name <name>

# Delete stack (will delete nested stacks automatically)
aws cloudformation delete-stack --stack-name Watchy-Platform
```

## Build System
- **GitHub Actions**: Automated CI/CD pipeline
- **Lambda Packaging**: Automatic zip creation and S3 upload
- **Template Validation**: CloudFormation syntax checking
- **Security Scanning**: Automated security validation