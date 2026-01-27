# Watchy - Open Source SaaS Monitoring Platform

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://s3.amazonaws.com/watchy-resources/watchy-platform.yaml&stackName=Watchy-Platform)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-Open%20Source-green?logo=github)](https://github.com/your-org/watchy-core)

Monitor SaaS application status with Amazon CloudWatch using **nested stack architecture** and pure Python implementation. Get real-time alerts for service degradation and incidents - all running transparently in your own AWS account.

## 🏗️ Repository Structure

```
watchy-core/
├── cloudformation/
│   ├── watchy-platform.yaml          # Parent stack (shared resources)
│   └── watchy-monitoring-slack.yaml  # Slack monitoring nested stack
├── lambda/
│   ├── slack_monitor/                # Slack monitoring Lambda function
│   │   └── lambda_function.py        # Main handler code (no external dependencies)
│   └── README.md                     # Lambda development guide
├── .github/workflows/
│   └── ci-cd.yaml                    # Integrated CI/CD pipeline
└── README.md                         # This file
```

## 🚀 Quick Start

Deploy the complete Watchy platform with nested stack architecture:

1. Click the **Deploy to AWS** button above
2. Enter your notification email address
3. Configure monitoring settings (schedule, log level, etc.)
4. Enable desired monitoring services (Slack enabled by default)
5. Click **Create Stack**

### Manual Deployment

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-platform.yaml \
  --stack-name Watchy-Platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    MonitoringSchedule="rate(5 minutes)" \
    EnableSlackMonitoring=true
```

## 📊 What Gets Deployed

### Parent Stack (`watchy-platform.yaml`)
- **SNS Topic**: Shared notification topic for all monitoring alerts
- **IAM Role**: Shared Lambda execution role with least-privilege permissions
- **CloudWatch Log Groups**: Platform-level logging infrastructure
- **Email Subscription**: Automatic SNS email subscription setup

### Slack Monitoring Nested Stack (`watchy-monitoring-slack.yaml`)
- **Lambda Function**: Pure Python 3.13 monitoring Slack Status API
- **CloudWatch Metrics**: Tracks 11 Slack service health metrics
- **CloudWatch Alarms**: Service-specific alerts for incidents and outages
- **CloudWatch Dashboard**: Visual monitoring interface with real-time status
- **EventBridge Schedule**: Automated polling on configured interval

## 🔍 Monitored Slack Services

Watchy monitors all 11 Slack services:

1. **Login/SSO** - Authentication and single sign-on
2. **Messaging** - Message sending and receiving
3. **Notifications** - Push and email notifications
4. **Search** - Message and file search
5. **Workspace/Org Administration** - Admin functions
6. **Canvases** - Canvas creation and editing
7. **Connectivity** - WebSocket and API connectivity
8. **Files** - File uploads and downloads
9. **Huddles** - Audio huddles
10. **Apps/Integrations/APIs** - Third-party integrations
11. **Workflows** - Workflow Builder functionality

## 🌟 Nested Stack Architecture Benefits

- **Resource Sharing**: SNS topics, IAM roles, and CloudWatch resources shared across all monitoring services
- **Cost Optimization**: Shared resources reduce duplicate infrastructure costs
- **Centralized Management**: Single parent stack manages all monitoring services
- **Consistent Configuration**: Global settings applied across all monitoring services
- **Easy Scaling**: Simple to add new SaaS monitoring services as additional nested stacks
- **Simplified Updates**: Update parent stack to propagate changes to all nested stacks

## ⚙️ Configuration

### Parent Stack Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `NotificationEmail` | Required | Email address for CloudWatch alarm notifications |
| `MonitoringSchedule` | `rate(5 minutes)` | How often to check SaaS service status |
| `TimeoutSeconds` | `240` | Lambda function timeout for all monitoring services |
| `RetryAttempts` | `3` | Number of retry attempts for failed API calls |
| `LogLevel` | `INFO` | Log level for all monitoring functions |
| `EnableSlackMonitoring` | `true` | Enable/disable Slack monitoring nested stack |

### Slack Status API Configuration

The Slack monitoring uses the public Slack Status API:
```
https://status.slack.com/api/v2.0.0/current
```

### CloudWatch Metrics

Metrics are published to the `Watchy/Slack` namespace:

#### Service Status Metrics
Each service has its own metric with values:
- **0**: Operational (healthy)
- **1**: Notice (minor issues)
- **2**: Incident (service degraded)
- **3**: Outage (service unavailable)

#### Additional Metrics
- **ActiveIncidents**: Total number of active incidents
- **APIResponse**: HTTP response code from Slack Status API

### Monitoring Schedule Options
- `rate(1 minute)` - Every minute (high frequency, higher cost)
- `rate(5 minutes)` - Every 5 minutes (recommended)
- `rate(15 minutes)` - Every 15 minutes (low frequency)
- `cron(0 */4 * * ? *)` - Every 4 hours (very low frequency)

### Alternative: Standalone Deployment
```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-monitoring-slack.yaml \
  --stack-name watchy-slack-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SaasAppName=Slack \
    ApiUrl=https://status.slack.com/api/v2.0.0/current \
    MonitoringSchedule="rate(5 minutes)" \
    SharedLambdaRoleArn=arn:aws:iam::account:role/your-role \
    NotificationTopicArn=arn:aws:sns:region:account:your-topic \
    ParentStackName=your-parent-stack
```

### Log Configuration
- **Platform Logs**: `/watchy/platform/{StackName}`
- **Slack Incident Logs**: `/watchy/slack`
- **Lambda Execution Logs**: `/aws/lambda/{ParentStackName}-SlackMonitor`

### Environment Variables

The Lambda function receives these environment variables:
- `API_URL`: Slack Status API endpoint
- `CLOUDWATCH_NAMESPACE`: Metrics namespace (Watchy/Slack)
- `CLOUDWATCH_LOG_GROUP`: Log group for incident logs
- `POLLING_INTERVAL_MINUTES`: Polling interval for smart deduplication
- `NOTIFICATION_TOPIC_ARN`: SNS topic for notifications
- `WATCHY_LOG_LEVEL`: Logging level
- `WATCHY_TIMEOUT_SECONDS`: Function timeout
- `WATCHY_RETRY_ATTEMPTS`: Retry attempts
- `WATCHY_STACK_NAME`: Parent stack name

## 💰 Cost Estimate

Typical monthly cost for complete platform: **$2-5 USD**

### Parent Stack Resources
- SNS Topic: $0.50/month (email notifications)
- CloudWatch Log Groups: $0.50/month (platform logs)

### Per SaaS Service (e.g., Slack)
- Lambda: ~8,640 invocations/month (5-min interval) = $0.18
- CloudWatch Logs: ~500 MB/month = $0.25
- CloudWatch Metrics: ~12 custom metrics = $0.36
- CloudWatch Alarms: ~11 alarms = $1.10
- CloudWatch Dashboard: 1 dashboard = $3.00

**Total for Platform + Slack**: Approximately $5.89/month

## 🔧 Pure Python Implementation

Watchy uses **AWS Lambda Python 3.13** runtime with a completely open source architecture:

- **All monitoring logic visible** in CloudFormation templates
- **Pure Python implementation** for maximum transparency
- **No binary dependencies** or compilation required
- **Easy to modify, extend, and contribute to**
- **Faster cold starts** and reduced memory usage (256MB vs 512MB)
- **Community-friendly development** and debugging

## 🛡️ Security Features

- **Least Privilege IAM**: Lambda functions have minimal required permissions
- **No API Keys**: Uses public SaaS Status APIs (no authentication needed)
- **VPC Optional**: Can be deployed in VPC for additional isolation
- **Encrypted Logs**: CloudWatch logs encrypted at rest
- **SNS Encryption**: Email notifications support encryption in transit
- **Open Source Security**: All code visible for security auditing

## 🔧 Troubleshooting

### Common Issues

#### Deployment Failures

**Issue**: CloudFormation stack creation fails
**Solutions**: 
- Check AWS permissions (need CAPABILITY_NAMED_IAM)
- Verify parameter values (especially NotificationEmail format)
- Review CloudFormation events tab for specific error messages
- Ensure S3 template URLs are accessible

**Issue**: Nested stack deployment fails
**Solutions**:
- Check parent stack has successfully created shared resources
- Verify nested stack template URL is accessible
- Review nested stack events in CloudFormation console
- Ensure IAM permissions allow nested stack creation

**Issue**: Lambda function timeouts
**Solutions**:
- Increase TimeoutSeconds parameter (default: 240)
- Check Slack Status API endpoint availability
- Review CloudWatch logs for specific timeout causes
- Verify Lambda has internet access (check VPC/NAT configuration if applicable)

#### Monitoring Issues

**Issue**: No alerts being triggered during known Slack incidents
**Solutions**:
- Verify SNS email subscription is confirmed (check email for confirmation)
- Check CloudWatch alarms are in ALARM state (not just INSUFFICIENT_DATA)
- Test Slack Status API manually: `curl https://status.slack.com/api/v2.0.0/current`
- Review monitoring schedule frequency
- Check Lambda execution logs for errors

**Issue**: False positive alerts
**Solutions**:
- Review CloudWatch alarm thresholds (currently set to alert on severity >= 2)
- Check if API response format has changed
- Verify incident deduplication logic is working (check polling interval)
- Review Lambda logs for parsing errors

**Issue**: Missing CloudWatch metrics
**Solutions**:
- Check Lambda execution logs for metric publishing errors
- Verify IAM role has cloudwatch:PutMetricData permission
- Confirm metrics namespace is correct (Watchy/Slack)
- Test Lambda function manually via AWS console

### Log Analysis

#### CloudWatch Log Groups
The nested stack architecture creates several log groups:

```bash
# Platform logs
/watchy/platform/{StackName}

# Slack incident logs (with smart deduplication)
/watchy/slack

# Lambda execution logs
/aws/lambda/{ParentStackName}-SlackMonitor
```

#### Viewing Logs
```bash
# List all Watchy-related log groups
aws logs describe-log-groups --log-group-name-prefix "/watchy"

# Get recent Lambda execution logs
aws logs get-log-events \
  --log-group-name "/aws/lambda/Watchy-Platform-SlackMonitor" \
  --log-stream-name "$(aws logs describe-log-streams \
    --log-group-name "/aws/lambda/Watchy-Platform-SlackMonitor" \
    --order-by LastEventTime --descending \
    --max-items 1 --query 'logStreams[0].logStreamName' --output text)"

# Get incident logs
aws logs describe-log-streams \
  --log-group-name "/watchy/slack" \
  --order-by LastEventTime --descending
```

#### Log Analysis Tips
- **Structured JSON logs**: All logs use JSON format for easy parsing
- **Smart deduplication**: Incident logs only show new notes within polling interval
- **Error tracking**: All errors include context and stack traces
- **Performance metrics**: Execution time and API response times logged

### Stack Management

#### Updating Stacks
```bash
# Update parent stack (will update nested stacks automatically)
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-platform.yaml \
  --stack-name Watchy-Platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    MonitoringSchedule="rate(10 minutes)"
```

#### Deleting Stacks
```bash
# Delete parent stack (will delete nested stacks automatically)
aws cloudformation delete-stack --stack-name Watchy-Platform
```

### Testing and Validation

#### Manual Testing
```bash
# Test Slack Status API directly
curl -s https://status.slack.com/api/v2.0.0/current | jq '.'

# Invoke Lambda function manually
aws lambda invoke \
  --function-name Watchy-Platform-SlackMonitor \
  --payload '{}' \
  response.json && cat response.json
```

#### Validation Checklist
- [ ] SNS email subscription confirmed
- [ ] CloudWatch alarms created for all 11 Slack services
- [ ] Lambda function executing on schedule
- [ ] Metrics appearing in CloudWatch (Watchy/Slack namespace)
- [ ] Incident logs being created during Slack incidents
- [ ] CloudWatch dashboard showing service status

### Debug Mode

Enable debug mode by setting environment variable:
```bash
DEBUG_DISABLE_TIME_FILTER=true
```

This will log ALL incident notes (not just recent ones) for troubleshooting deduplication issues.

### Getting Help

1. **Check CloudWatch logs** for detailed error messages and execution traces
2. **Review CloudFormation events** for deployment issues
3. **Verify API endpoints** are accessible from your AWS region
4. **Test with minimal configuration** first, then add complexity
5. **Use CloudWatch Insights** to query logs across multiple log groups
6. **Monitor CloudWatch metrics** to ensure data is being collected

## 🤝 Contributing

We welcome contributions! The open source architecture makes it easy to:

- Add new SaaS monitoring integrations
- Improve alerting logic
- Enhance dashboard visualizations
- Fix bugs and add features

### Development Workflow

#### Local Development
1. Fork the repository
2. Create a feature branch
3. Make changes to Lambda functions in `lambda/`
4. Test locally by running the Python code directly
5. Update CloudFormation templates in `cloudformation/`
6. Test with your AWS account

#### Automated Deployment
The repository includes an integrated CI/CD pipeline for automated building and deployment:

- **Triggers**: Changes to `lambda/`, `cloudformation/`, or workflow files
- **Process**: 
  1. Detects what changed (templates, Lambda code, workflows)
  2. Validates Python syntax and CloudFormation templates
  3. Builds Lambda deployment packages with versioning
  4. Uploads Lambda packages to `watchy-resources` S3 bucket
  5. Deploys CloudFormation templates to S3
  6. Tests accessibility of all deployed artifacts
  7. Publishes to public GitHub repository (if configured)

**Pipeline Jobs:**
- `detect-changes`: Determines what files changed
- `validate`: Validates syntax and templates
- `security-scan`: Scans for security issues
- `build-lambda`: Builds and uploads Lambda packages
- `deploy-templates`: Deploys CloudFormation templates
- `test-deployment`: Validates deployed artifacts

#### Adding New Lambda Functions
1. Create new directory under `lambda/`
2. Add `lambda_function.py` with handler
3. Add `requirements.txt` for dependencies
4. Update GitHub Actions workflow if needed
5. Create corresponding CloudFormation resources

#### Testing
- **Local testing**: Use the build script and test functions locally
- **AWS testing**: Deploy to your own AWS account first
- **Validation**: GitHub Actions validates all templates automatically

## 🚀 Roadmap

### Planned Nested Stacks
- **GitHub Status Monitoring**: Monitor GitHub service status and incidents
- **Zoom Status Monitoring**: Monitor Zoom service availability
- **Custom SaaS Integrations**: Template for adding new SaaS monitoring services

### Platform Enhancements
- **Multi-region Deployment**: Deploy monitoring across multiple AWS regions
- **Advanced Dashboard Templates**: Enhanced CloudWatch dashboard configurations
- **Webhook Notifications**: Support for Slack, Teams, and custom webhook alerts
- **Cost Optimization**: Further resource sharing and cost reduction features

## 📄 License

Licensed under the MIT License. See LICENSE file for details.

---

**Watchy Cloud** - Open source, transparent SaaS monitoring with nested stack architecture for the modern enterprise.