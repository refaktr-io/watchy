# Watchy - Open Source SaaS Monitoring Platform

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://s3.amazonaws.com/watchy-resources/watchy-platform.yaml&stackName=Watchy-Platform)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-Open%20Source-green?logo=github)](https://github.com/your-org/watchy-core)

Monitor SaaS application status with Amazon CloudWatch using **nested stack architecture**. Get real-time alerts for service degradation and incidents - all running transparently in your own AWS account.

## 🏗️ Repository Structure

```
watchy-core/
├── cloudformation/
│   ├── watchy-platform.yaml          # Parent stack (shared resources)
│   ├── watchy-monitoring-slack.yaml  # Slack monitoring nested stack
│   └── watchy-monitoring-github.yaml # GitHub monitoring nested stack
├── lambda/
│   ├── slack_monitor/                # Slack monitoring Lambda function
│   │   └── lambda_function.py        # Main handler code (no external dependencies)
│   ├── github_monitor/               # GitHub monitoring Lambda function
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
4. Enable desired monitoring services (Slack and GitHub enabled by default)
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
    EnableSlackMonitoring=true \
    EnableGitHubMonitoring=true
```

## 📊 What Gets Deployed

### Parent Stack (`watchy-platform.yaml`)
- **SNS Topic**: Shared notification topic for all monitoring alerts
- **IAM Role**: Shared Lambda execution role with least-privilege permissions
- **CloudWatch Log Groups**: Platform-level logging infrastructure
- **Email Subscription**: Automatic SNS email subscription setup

### Slack Monitoring Nested Stack (`watchy-monitoring-slack.yaml`)
- **Lambda Function**: Python 3.14 monitoring Slack Status API
- **CloudWatch Metrics**: Tracks 11 Slack service health metrics
- **CloudWatch Alarms**: Service-specific alerts for incidents and outages
- **CloudWatch Dashboard**: Visual monitoring interface with real-time status
- **EventBridge Schedule**: Automated polling on configured interval

### GitHub Monitoring Nested Stack (`watchy-monitoring-github.yaml`)
- **Lambda Function**: Python 3.14 monitoring GitHub Status API for unresolved incidents
- **CloudWatch Metrics**: Tracks incidents by impact level (none, minor, major, critical)
- **CloudWatch Alarms**: Impact-specific alerts for major and critical incidents
- **CloudWatch Dashboard**: Visual monitoring interface with incident tracking
- **EventBridge Schedule**: Automated polling on configured interval

## 🔍 Monitored Services

### Slack Services
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

### GitHub Incidents
Watchy monitors GitHub unresolved incidents by impact level:

- **None** - No impact incidents (informational)
- **Minor** - Minor impact incidents (yellow)
- **Major** - Major impact incidents (orange) 
- **Critical** - Critical impact incidents (red)

**Incident Statuses Monitored:**
- **Investigating** - GitHub is investigating the issue
- **Identified** - The issue has been identified
- **Monitoring** - Fix has been applied and GitHub is monitoring

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
| `EnableGitHubMonitoring` | `true` | Enable/disable GitHub monitoring nested stack |

### Slack Status API Configuration

The Slack monitoring uses the public Slack Status API:
```
https://status.slack.com/api/v2.0.0/current
```

### GitHub Status API Configuration

The GitHub monitoring uses the public GitHub Status API:
```
https://www.githubstatus.com/api/v2/incidents/unresolved.json
```

### CloudWatch Metrics

#### Slack Metrics
Metrics are published to the `Watchy/Slack` namespace:

##### Service Status Metrics
Each service has its own metric with values:
- **0**: Operational (healthy)
- **1**: Notice (minor issues)
- **2**: Incident (service degraded)
- **3**: Outage (service unavailable)

##### Additional Metrics
- **ActiveIncidents**: Total number of active incidents
- **APIResponse**: HTTP response code from Slack Status API

#### GitHub Metrics
Metrics are published to the `Watchy/GitHub` namespace:

##### Incident Count Metrics
- **IncidentsNone**: Count of incidents with no impact
- **IncidentsMinor**: Count of incidents with minor impact
- **IncidentsMajor**: Count of incidents with major impact
- **IncidentsCritical**: Count of incidents with critical impact
- **TotalUnresolvedIncidents**: Total count of all unresolved incidents
- **HighestImpactLevel**: Highest impact level (0=none, 1=minor, 2=major, 3=critical)
- **APIResponse**: HTTP response code from GitHub Status API

### Monitoring Schedule Options
- `rate(1 minute)` - Every minute (high frequency, higher cost)
- `rate(5 minutes)` - Every 5 minutes (recommended)
- `rate(15 minutes)` - Every 15 minutes (low frequency)
- `cron(0 */4 * * ? *)` - Every 4 hours (very low frequency)

### Alternative: Standalone Deployment
```bash
# Deploy Slack monitoring standalone
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

# Deploy GitHub monitoring standalone
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources/watchy-monitoring-github.yaml \
  --stack-name watchy-github-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SaasAppName=GitHub \
    ApiUrl=https://www.githubstatus.com/api/v2/incidents/unresolved.json \
    MonitoringSchedule="rate(5 minutes)" \
    SharedLambdaRoleArn=arn:aws:iam::account:role/your-role \
    NotificationTopicArn=arn:aws:sns:region:account:your-topic \
    ParentStackName=your-parent-stack
```

### Log Configuration
- **Platform Logs**: `/watchy/platform/{StackName}`
- **Slack Incident Logs**: `/watchy/services/slack`
- **GitHub Incident Logs**: `/watchy/services/github`
- **Lambda Execution Logs**: `/aws/lambda/{ParentStackName}-SlackMonitor`, `/aws/lambda/{ParentStackName}-GitHubMonitor`

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

### Complete Platform Cost Breakdown

**Monthly AWS Costs (us-east-1):**

```
Core Platform:                 $0.50
Slack Monitoring:              $9.90
GitHub Monitoring:             $7.10
S3 Storage:                    $0.002
                              ------
Total Monthly Cost:           $17.50

Key Components:
- CloudWatch Dashboards:       $6.00 (2 dashboards)
- CloudWatch Metrics:          $6.90 (23 custom metrics)
- CloudWatch Alarms:           $1.70 (17 alarms)
- CloudWatch Logs:             $2.50 (log retention)
- Lambda Functions:            $0.40 (ARM64, 256MB)
```

### Detailed Service Costs

**Slack Monitoring Stack ($9.90/month):**
- Lambda Function (ARM64, 256MB): $0.20
  - 8,640 invocations/month (5-min polling)
- CloudWatch Logs (2 groups): $1.00
- CloudWatch Metrics (15 custom): $4.50
- CloudWatch Alarms (12 alarms): $1.20
- CloudWatch Dashboard: $3.00

**GitHub Monitoring Stack ($7.10/month):**
- Lambda Function (ARM64, 256MB): $0.20
  - 8,640 invocations/month (5-min polling)
- CloudWatch Logs (2 groups): $1.00
- CloudWatch Metrics (8 custom): $2.40
- CloudWatch Alarms (5 alarms): $0.50
- CloudWatch Dashboard: $3.00

### Cost Scaling Options

| Polling Interval | Lambda Invocations | Monthly Cost |
|------------------|-------------------|-------------|
| **1 minute** | 43,200/month | $22.00 |
| **5 minutes** (default) | 8,640/month | $17.50 |
| **15 minutes** | 2,880/month | $15.00 |
| **1 hour** | 720/month | $13.50 |

### Cost Optimization

**Optimized Configuration (29% savings):**
- 10-minute polling: -$1.50/month
- 3-day log retention: -$0.50/month
- Combined dashboard: -$3.00/month
- **Optimized Total: $12.50/month**

### Comparison with SaaS Alternatives

| Solution | Monthly Cost | Features |
|----------|-------------|----------|
| **Watchy** | $17.50 | Full monitoring, custom dashboards |
| **StatusGator** | $40-72 | Hosted solution, 3,600+ services |
| **DataDog** | $45+ | More features, 3x cost |
| **New Relic** | $25+ | Similar features, higher cost |
| **PagerDuty** | $21+ | Alerting focus, less monitoring |

**Watchy Savings:**
- vs StatusGator: $22.50-54.50/month (56-76% savings)
- vs DataDog: $27.50+/month (61% savings)
- Annual savings: $270-654/year

## 🔧 Implementation

Watchy uses **AWS Lambda Python 3.14** runtime with ARM64 architecture for optimal price-performance:

- **All monitoring logic visible** in CloudFormation templates
- **Standard Python implementation** for maximum transparency
- **No binary dependencies** or compilation required
- **Easy to modify, extend, and contribute to**
- **ARM64 architecture** for better price-performance and lower costs
- **Faster cold starts** and reduced memory usage (256MB)
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
aws cloudformation delete-stack --stack-name watchy-platform
```

### Testing and Validation

#### Manual Testing
```bash
# Test Slack Status API directly
curl -s https://status.slack.com/api/v2.0.0/current | jq '.'

# Test GitHub Status API directly
curl -s https://www.githubstatus.com/api/v2/incidents/unresolved.json | jq '.'

# Invoke Lambda function manually
aws lambda invoke \
  --function-name Watchy-Platform-SlackMonitor \
  --payload '{}' \
  response.json && cat response.json

aws lambda invoke \
  --function-name Watchy-Platform-GitHubMonitor \
  --payload '{}' \
  response.json && cat response.json
```

#### Validation Checklist
- [ ] SNS email subscription confirmed
- [ ] CloudWatch alarms created for all Slack services and GitHub incidents
- [ ] Lambda functions executing on schedule
- [ ] Metrics appearing in CloudWatch (Watchy/Slack and Watchy/GitHub namespaces)
- [ ] Incident logs being created during incidents
- [ ] CloudWatch dashboards showing service status

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

## 🚀 Roadmap

### Planned Nested Stacks
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