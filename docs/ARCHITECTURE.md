# Watchy Platform - Cloud Architecture

## AWS Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          AWS CloudFormation Stack: Watchy                       │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                        Amazon EventBridge (CloudWatch Events)               │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Rule: Watchy-SlackSchedule                                          │  │ │
│  │  │  Schedule: rate(5 minutes)                                           │  │ │
│  │  │  State: ENABLED                                                      │  │ │
│  │  └──────────────────────────┬───────────────────────────────────────────┘  │ │
│  └─────────────────────────────┼──────────────────────────────────────────────┘ │
│                                 │                                                │
│                                 │ Triggers every 5 minutes                       │
│                                 ▼                                                │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         AWS Lambda Function                                 │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Function: Watchy-SlackMonitor                                       │  │ │
│  │  │  Runtime: python3.13                                                 │  │ │
│  │  │  Memory: 512 MB                                                      │  │ │
│  │  │  Timeout: 300 seconds                                                │  │ │
│  │  │  Binary: watchy-slack-monitor (Nuitka compiled)                     │  │ │
│  │  │                                                                       │  │ │
│  │  │  Environment Variables:                                              │  │ │
│  │  │    • SAAS_APP_NAME: Slack                                           │  │ │
│  │  │    • API_URL: https://status.slack.com/api/v2.0.0/current          │  │ │
│  │  │    • CLOUDWATCH_NAMESPACE: Watchy/Slack                             │  │ │
│  │  │    • NOTIFICATION_TOPIC_ARN: (SNS Topic ARN)                        │  │ │
│  │  │    • WATCHY_BINARY_DISTRIBUTION_URL: releases.watchy.cloud          │  │ │
│  │  └──────────────────────────┬───────────────────────────────────────────┘  │ │
│  └─────────────────────────────┼──────────────────────────────────────────────┘ │
│                                 │                                                │
│                                 │ Executes monitoring                            │
│                                 ▼                                                │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         IAM Role & Policies                                 │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Role: Watchy-WatchyPlatformRole                                    │  │ │
│  │  │                                                                       │  │ │
│  │  │  Managed Policies:                                                   │  │ │
│  │  │    • AWSLambdaBasicExecutionRole                                    │  │ │
│  │  │                                                                       │  │ │
│  │  │  Inline Policies:                                                    │  │ │
│  │  │    • cloudwatch:PutMetricData (all resources)                       │  │ │
│  │  │    • logs:CreateLogGroup, CreateLogStream, PutLogEvents            │  │ │
│  │  │      (for /aws/lambda/*Watchy* and /watchy/slack/*)                │  │ │
│  │  │    • sns:Publish (for Watchy-Alerts topic)                          │  │ │
│  │  └──────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Lambda calls external API
                                      ▼
        ┌─────────────────────────────────────────────────────────┐
        │              Internet / Public API                       │
        │  ┌───────────────────────────────────────────────────┐  │
        │  │  Slack Status API                                 │  │
        │  │  https://status.slack.com/api/v2.0.0/current      │  │
        │  │                                                    │  │
        │  │  Returns JSON with:                               │  │
        │  │    • 11 service statuses                          │  │
        │  │    • Active incidents                             │  │
        │  │    • Incident details (type, status, services)    │  │
        │  └───────────────────────────────────────────────────┘  │
        └─────────────────────────────────────────────────────────┘
                                      │
                                      │ Lambda processes response
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS CloudWatch                                    │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CloudWatch Metrics                                  │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Namespace: Watchy/Slack                                             │  │ │
│  │  │                                                                       │  │ │
│  │  │  Service Status Metrics (0=OK, 1=Notice, 2=Incident, 3=Outage):    │  │ │
│  │  │    1. LoginSSO                                                       │  │ │
│  │  │    2. Messaging                                                      │  │ │
│  │  │    3. Notifications                                                  │  │ │
│  │  │    4. Search                                                         │  │ │
│  │  │    5. WorkspaceOrgAdministration                                    │  │ │
│  │  │    6. Canvases                                                       │  │ │
│  │  │    7. Connectivity                                                   │  │ │
│  │  │    8. Files                                                          │  │ │
│  │  │    9. Huddles                                                        │  │ │
│  │  │   10. AppsIntegrationsAPIs                                          │  │ │
│  │  │   11. Workflows                                                      │  │ │
│  │  │                                                                       │  │ │
│  │  │  Additional Metrics:                                                 │  │ │
│  │  │    • ActiveIncidents (count)                                        │  │ │
│  │  │    • APIResponse (HTTP status code)                                 │  │ │
│  │  └──────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CloudWatch Dashboard                                │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Dashboard: Watchy-Slack-Monitoring                                  │  │ │
│  │  │                                                                       │  │ │
│  │  │  Widgets (6 total):                                                  │  │ │
│  │  │    1. Service Health Timeline (time series)                          │  │ │
│  │  │       - All 11 Slack services with color-coded status               │  │ │
│  │  │    2. Active Incidents Counter (single value)                        │  │ │
│  │  │    3. API Response Status (single value)                             │  │ │
│  │  │    4. Recent Incident Updates (log insights)                         │  │ │
│  │  │    5. Lambda Performance Metrics (time series)                       │  │ │
│  │  │    6. Current Service Status (single value grid)                     │  │ │
│  │  └──────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CloudWatch Logs                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Log Group: /aws/lambda/Watchy-SlackMonitor                         │  │ │
│  │  │    • Lambda execution logs                                           │  │ │
│  │  │    • Retention: 30 days                                              │  │ │
│  │  │                                                                       │  │ │
│  │  │  Log Group: /watchy/slack                                            │  │ │
│  │  │    • Incident-specific logs                                          │  │ │
│  │  │    • Log Streams: slack-incidents-YYYY-MM-DD-timestamp              │  │ │
│  │  │    • Smart deduplication (only new incidents)                       │  │ │
│  │  │    • Includes incident details, affected services                   │  │ │
│  │  └──────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CloudWatch Alarms (11 Service Alarms)              │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  1. Watchy-Slack-LoginSSO                                           │  │ │
│  │  │     Threshold: ≥ 2 (Incident/Outage)                                │  │ │
│  │  │     Period: 300 seconds                                              │  │ │
│  │  │     Statistic: Average                                               │  │ │
│  │  │  ├─────────────────────────────────────────────────────────────────┤  │ │
│  │  │  2. Watchy-Slack-Messaging                    [Same configuration]  │  │ │
│  │  │  3. Watchy-Slack-Notifications                [Same configuration]  │  │ │
│  │  │  4. Watchy-Slack-Search                       [Same configuration]  │  │ │
│  │  │  5. Watchy-Slack-WorkspaceOrgAdministration   [Same configuration]  │  │ │
│  │  │  6. Watchy-Slack-Canvases                     [Same configuration]  │  │ │
│  │  │  7. Watchy-Slack-Connectivity                 [Same configuration]  │  │ │
│  │  │  8. Watchy-Slack-Files                        [Same configuration]  │  │ │
│  │  │  9. Watchy-Slack-Huddles                      [Same configuration]  │  │ │
│  │  │ 10. Watchy-Slack-AppsIntegrationsAPIs         [Same configuration]  │  │ │
│  │  │ 11. Watchy-Slack-Workflows                    [Same configuration]  │  │ │
│  │  │                                                                       │  │ │
│  │  │ Additional Alarms:                                                   │  │ │
│  │  │  • Watchy-Slack-APIResponse (threshold > 200)                       │  │ │
│  │  │    Monitors API availability                                         │  │ │
│  │  └──────────────────────────┬───────────────────────────────────────────┘  │ │
│  └─────────────────────────────┼──────────────────────────────────────────────┘ │
└────────────────────────────────┼─────────────────────────────────────────────────┘
                                  │
                                  │ Alarm triggers
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Amazon SNS                                          │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         SNS Topic                                           │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Topic: Watchy-Alerts                                                │  │ │
│  │  │  Display Name: Watchy Platform Alerts                                │  │ │
│  │  │                                                                       │  │ │
│  │  │  Subscriptions:                                                      │  │ │
│  │  │    • Protocol: email                                                 │  │ │
│  │  │    • Endpoint: user@example.com (from parameter)                    │  │ │
│  │  │    • Status: Confirmed (requires email confirmation)                │  │ │
│  │  └──────────────────────────┬───────────────────────────────────────────┘  │ │
│  └─────────────────────────────┼──────────────────────────────────────────────┘ │
└────────────────────────────────┼─────────────────────────────────────────────────┘
                                  │
                                  │ Email notification sent
                                  ▼
                        ┌──────────────────────┐
                        │   Email Recipient    │
                        │  user@example.com    │
                        │                      │
                        │  Receives alerts:    │
                        │  • Alarm name        │
                        │  • Service affected  │
                        │  • Severity level    │
                        │  • Timestamp         │
                        │  • AWS Console link  │
                        └──────────────────────┘
```

## Data Flow

### 1. Scheduled Monitoring (Every 5 Minutes)

```
EventBridge Rule (rate(5 minutes))
    │
    └──> Triggers Lambda Function
            │
            └──> Downloads/Caches Nuitka Binary from releases.watchy.cloud
                    │
                    └──> Executes Binary with Environment Variables
```

### 2. Status Check & Data Collection

```
Lambda Function (Python 3.13 + Nuitka Binary)
    │
    ├──> Calls Slack Status API
    │    └──> GET https://status.slack.com/api/v2.0.0/current
    │         Returns: JSON with 11 services + incidents
    │
    ├──> Parses Response
    │    ├──> Extracts service statuses (OK, Notice, Incident, Outage)
    │    ├──> Maps to severity levels (0, 1, 2, 3)
    │    └──> Identifies active incidents
    │
    └──> Publishes Data to AWS Services
```

### 3. Data Publishing

```
Lambda Function
    │
    ├──> CloudWatch Metrics
    │    └──> Batch publish 13 metrics to Watchy/Slack namespace
    │         • 11 service status metrics (0-3 severity)
    │         • ActiveIncidents (count)
    │         • APIResponse (HTTP status code)
    │
    ├──> CloudWatch Logs
    │    ├──> Lambda execution logs → /aws/lambda/Watchy-SlackMonitor
    │    └──> Incident logs → /watchy/slack/slack-incidents-YYYY-MM-DD-*
    │         (only created when incidents occur, with deduplication)
    │
    └──> CloudWatch Alarms Evaluate Metrics
```

### 4. Alerting & Notifications

```
CloudWatch Alarms (12 alarms)
    │
    ├──> Evaluate metrics every 5 minutes
    │    └──> Check if severity ≥ 2 (Incident or Outage)
    │
    ├──> State Transitions
    │    ├──> OK → ALARM (service degraded)
    │    └──> ALARM → OK (service recovered)
    │
    └──> Alarm State = ALARM
         │
         └──> Publish to SNS Topic (Watchy-Alerts)
              │
              └──> Send Email Notification
                   ├──> Subject: ALARM: "Watchy-Slack-{Service}"
                   ├──> Body: Alarm details, metric value, timestamp
                   └──> Links: AWS Console links for investigation
```

## Resource Summary

### AWS Services Used

| Service | Resources | Purpose |
|---------|-----------|---------|
| **CloudFormation** | 1 Stack (Watchy) | Infrastructure as Code deployment |
| **Lambda** | 1 Function | Execute monitoring logic with Nuitka binary |
| **EventBridge** | 1 Rule | Scheduled trigger (every 5 minutes) |
| **IAM** | 1 Role, 1 Policy | Least-privilege Lambda execution permissions |
| **CloudWatch Metrics** | 13 Custom Metrics | Track service health and API status |
| **CloudWatch Logs** | 2 Log Groups | Lambda execution and incident history |
| **CloudWatch Alarms** | 12 Alarms | Alert on service degradation |
| **CloudWatch Dashboard** | 1 Dashboard | Real-time visual monitoring interface |
| **SNS** | 1 Topic, 1 Subscription | Email notifications for alerts |

### Resource Naming Conventions

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| CloudFormation Stack | `Watchy` (recommended) | `Watchy` |
| Lambda Function | `{StackName}-SlackMonitor` | `Watchy-SlackMonitor` |
| IAM Role | `{StackName}-WatchyPlatformRole` | `Watchy-WatchyPlatformRole` |
| EventBridge Rule | `{StackName}-SlackSchedule` | `Watchy-SlackSchedule` |
| SNS Topic | `Watchy-Alerts` | `Watchy-Alerts` |
| CloudWatch Alarms | `Watchy-Slack-{Service}` | `Watchy-Slack-Messaging` |
| Log Groups | `/aws/lambda/{Function}` | `/aws/lambda/Watchy-SlackMonitor` |
|  | `/watchy/slack` | `/watchy/slack` |

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Security Layers                                │
│                                                                   │
│  1. IAM Role (Least Privilege)                                   │
│     ├─ Lambda execution role with minimal permissions            │
│     ├─ CloudWatch metrics: PutMetricData only                    │
│     ├─ CloudWatch logs: Restricted to Watchy namespaces          │
│     └─ SNS: Publish to Watchy-Alerts topic only                  │
│                                                                   │
│  2. Network Security                                              │
│     ├─ Lambda runs in AWS managed VPC (no VPC config needed)     │
│     ├─ Outbound HTTPS only to status.slack.com                   │
│     └─ No inbound connections required                           │
│                                                                   │
│  3. Data Security                                                 │
│     ├─ CloudWatch Logs: Encrypted at rest (AWS managed keys)     │
│     ├─ SNS: Email encryption in transit (TLS)                    │
│     └─ No sensitive data stored (public API only)                │
│                                                                   │
│  4. Binary Security                                               │
│     ├─ Nuitka compiled binary (source code protected)            │
│     ├─ SHA256 checksum verification                              │
│     ├─ Downloaded from releases.watchy.cloud (HTTPS)             │
│     └─ Cached in Lambda /tmp with integrity checks               │
│                                                                   │
│  5. Access Control                                                │
│     ├─ No API keys or credentials required (public API)          │
│     ├─ CloudFormation template requires email confirmation       │
│     └─ SNS subscription requires user email verification         │
└──────────────────────────────────────────────────────────────────┘
```

## Cost Breakdown

### Monthly Cost Estimate (5-minute monitoring interval)

| AWS Service | Usage | Cost |
|-------------|-------|------|
| **Lambda Invocations** | 8,640/month (5-min interval) | ~$0.18 |
| **Lambda Duration** | ~30 seconds/invocation | Included in invocations |
| **Lambda Compute** | 512 MB memory | ~$0.00 |
| **CloudWatch Metrics** | 13 custom metrics | $0.30/metric = $3.90 |
| **CloudWatch Logs** | ~100 MB/month | $0.50 |
| **CloudWatch Alarms** | 12 alarms (free tier) | $0.00 (first 10 free) |
|  | 2 alarms beyond free tier | $0.20 |
| **CloudWatch Dashboard** | 1 dashboard | $3.00/month |
| **SNS Notifications** | ~10 emails/month | $0.00 (first 1,000 free) |
| **EventBridge Rules** | 1 rule | $0.00 (free) |
| **Data Transfer** | Minimal (API calls) | ~$0.00 |
| **Total** |  | **~$7.78/month** |

*Costs may vary based on actual usage and AWS pricing changes.*

## Monitoring & Observability

### CloudWatch Dashboard (Automatically Created)

The stack automatically creates a comprehensive CloudWatch Dashboard:

```
Dashboard: Watchy-Slack-Monitoring
  ├─ Service Health Timeline (Time Series)
  │  └─ All 11 Slack services with color-coded severity levels
  │     • Green: Healthy (0)
  │     • Yellow: Notice (1)
  │     • Orange: Incident (2)
  │     • Red: Outage (3)
  ├─ Active Incidents Counter (Single Value)
  │  └─ Real-time count of current active incidents
  ├─ API Response Status (Single Value)
  │  └─ Slack Status API health (HTTP status code)
  ├─ Recent Incident Updates (Log Insights)
  │  └─ Latest 20 incident notes from CloudWatch Logs
  ├─ Lambda Performance Metrics (Time Series)
  │  └─ Invocations, errors, and execution duration
  └─ Current Service Status (Single Value Grid)
     └─ Status for all 11 services (0-3 scale)
```

**Access**: The dashboard URL is available in the CloudFormation stack outputs.

### Key Metrics to Monitor

1. **Service Status Metrics** (0-3 scale)
   - 0 = OK (green)
   - 1 = Notice (yellow)
   - 2 = Incident (orange)
   - 3 = Outage (red)

2. **ActiveIncidents** (count)
   - Total number of active Slack incidents

3. **APIResponse** (HTTP code)
   - 200 = API healthy
   - 4xx/5xx = API issues

### Log Analysis

Query CloudWatch Logs Insights:

```sql
-- Find all incidents in the last 24 hours
fields @timestamp, incident_title, affected_services, incident_type
| filter incident_type in ["incident", "outage"]
| sort @timestamp desc

-- Service incident frequency
fields @timestamp, service_name
| stats count() by service_name
| sort count() desc
```

## High Availability & Reliability

### Built-in Resilience

- **Lambda**: Automatic failover and retries (3 attempts configured)
- **EventBridge**: Managed service with 99.99% availability SLA
- **CloudWatch**: Regional service with built-in redundancy
- **SNS**: Multi-AZ deployment for notifications

### Monitoring the Monitor

CloudWatch alarms alert when:
- Lambda function fails (captured in logs)
- API returns non-200 status (APIResponse alarm)
- Service severity reaches incident/outage levels

## Scalability

The architecture scales automatically:

- **Lambda**: Auto-scales to handle invocations (1 invocation every 5 minutes)
- **CloudWatch**: No limits on metrics or log volume
- **SNS**: Handles unlimited email subscribers

To monitor additional SaaS platforms, deploy additional nested stacks (coming soon: GitHub, Zoom).

---

**Architecture Version**: 5.2.0  
**Last Updated**: October 18, 2025  
**CloudFormation Template**: [watchy-platform.yaml](../watchy-platform.yaml)
