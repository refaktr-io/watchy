# Configuration Guide

## CloudFormation Parameters

### Required Parameters

- **SaasAppName**: Display name for your monitoring service
- **ApiUrl**: Status API endpoint URL  
- **MonitoringSchedule**: CloudWatch Events schedule expression

### Optional Parameters

- **AlertEmail**: Email address for notifications
- **RetentionDays**: Log retention period (default: 7 days)
- **TimeoutSeconds**: Lambda timeout (default: 30 seconds)

## API Configuration

### Slack Status API
```
ApiUrl: https://status.slack.com/api/v2.0.0/current
```

### GitHub Status API  
```
ApiUrl: https://www.githubstatus.com/api/v2/status.json
```

### Zoom Status API
```
ApiUrl: https://status.zoom.us/api/v2/status.json
```

## Schedule Expressions

- Every 5 minutes: `rate(5 minutes)`
- Every hour: `rate(1 hour)` 
- Daily at 9 AM UTC: `cron(0 9 * * ? *)`
- Business hours only: `cron(0 9-17 ? * MON-FRI *)`
