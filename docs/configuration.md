# Configuration Guide

## Nested Stack Architecture

Watchy uses a nested stack architecture with two main templates:

### Parent Stack (`watchy-platform.yaml`)
Contains shared resources and manages nested stacks.

**Required Parameters:**
- **NotificationEmail**: Email address for CloudWatch alarm notifications
- **MonitoringSchedule**: How often to check SaaS service status (e.g., 'rate(5 minutes)')
- **EnableSlackMonitoring**: Enable/disable Slack monitoring nested stack (default: true)

**Optional Parameters:**
- **LogLevel**: DEBUG, INFO, WARNING, or ERROR (default: INFO)
- **TimeoutSeconds**: Lambda timeout for all monitoring functions (default: 240)
- **RetryAttempts**: Retry count for failed API calls (default: 3)

### Nested Stack (`watchy-slack-monitoring.yaml`)
Contains Slack-specific monitoring resources. Parameters are automatically passed from the parent stack.

## Slack Status API Configuration

### API Endpoint
The Slack monitoring uses the public Slack Status API:
```
https://status.slack.com/api/v2.0.0/current
```

### Monitored Services
Watchy monitors all 11 Slack services:
1. Login/SSO
2. Messaging  
3. Notifications
4. Search
5. Workspace/Org Administration
6. Canvases
7. Connectivity
8. Files
9. Huddles
10. Apps/Integrations/APIs
11. Workflows

## CloudWatch Metrics

Metrics are published to the `Watchy/Slack` namespace:

### Service Status Metrics
Each service has its own metric with values:
- **0**: Operational (healthy)
- **1**: Notice (minor issues)
- **2**: Incident (service degraded)
- **3**: Outage (service unavailable)

### Additional Metrics
- **ActiveIncidents**: Total number of active incidents
- **APIResponse**: HTTP response code from Slack Status API

## Deployment Options

### Recommended: Nested Stack Deployment
```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/templates/watchy-platform.yaml \
  --stack-name Watchy-Platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    MonitoringSchedule="rate(5 minutes)" \
    EnableSlackMonitoring=true
```

### Alternative: Standalone Deployment
```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/templates/watchy-slack-monitoring.yaml \
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

## Customization

### Monitoring Schedule Options
- `rate(1 minute)` - Every minute (high frequency, higher cost)
- `rate(5 minutes)` - Every 5 minutes (recommended)
- `rate(15 minutes)` - Every 15 minutes (low frequency)
- `cron(0 */4 * * ? *)` - Every 4 hours (very low frequency)

### Notification Configuration
The parent stack creates a shared SNS topic for all monitoring alerts. The nested stack creates service-specific CloudWatch alarms that publish to this topic.

### Log Configuration
- **Platform Logs**: `/watchy/platform/{StackName}`
- **Slack Incident Logs**: `/watchy/slack`
- **Lambda Execution Logs**: `/aws/lambda/{ParentStackName}-SlackMonitor`

## Environment Variables

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
