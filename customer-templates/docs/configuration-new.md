# Configuration Guide

## Slack Status API  

### API Endpoint
```yaml
ApiUrl: https://status.slack.com/api/v2.0.0/current
```

### Required Parameters
- **SaasAppName**: Set to 'Slack'
- **ApiUrl**: Slack status API endpoint
- **MonitoringSchedule**: How often to check (e.g., 'rate(5 minutes)')
- **ParentStackName**: Your stack name for resource naming

### Optional Parameters
- **LogLevel**: DEBUG, INFO, WARN, or ERROR (default: INFO)
- **TimeoutSeconds**: Lambda timeout (default: 240)
- **RetryAttempts**: Retry count for failures (default: 3)

## Parameter Store Integration

The template automatically creates a parameter store entry for API keys:
```
/${ParentStackName}/watchy/api-keys
```

Store any required API keys as JSON:
```json
{
  "slack_webhook": "https://hooks.slack.com/...",
  "custom_auth": "your-token-here"
}
```

## CloudWatch Metrics

Metrics are published to the `Watchy/Slack` namespace:
- **ServiceStatus**: 0=operational, 1=degraded, 2=partial_outage, 3=major_outage
- **APIResponse**: HTTP response code from status API

## Customization

### Monitoring Schedule
- `rate(1 minute)` - Every minute (high frequency)
- `rate(5 minutes)` - Every 5 minutes (recommended)
- `rate(15 minutes)` - Every 15 minutes (low frequency)
- `cron(0 */4 * * ? *)` - Every 4 hours

### Notification Configuration
The template creates an SNS topic for alerts. Subscribe your email/SMS/webhook endpoints to receive notifications when Slack incidents occur.
