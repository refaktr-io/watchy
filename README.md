# Watchy - SaaS Application Monitoring on AWS

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml&stackName=Watchy)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub](https://img.shields.io/badge/GitHub-refaktr--io%2Fwatchy-blue?logo=github)](https://github.com/refaktr-io/watchy)

Monitor SaaS application status with Amazon CloudWatch. Get real-time alerts for service degradation and incidents - all running in your own AWS account.

## 🚀 Quick Start

Deploy the complete Watchy platform in 60 seconds:

1. Click the **Deploy to AWS** button above
2. Enter your notification email address
3. Review the CloudFormation parameters
4. Click **Create Stack**

That's it! Watchy will begin monitoring Slack's service status and sending alerts to your email.

### CloudFormation Templates

- **[watchy-platform.yaml](cloudformation/watchy-platform.yaml)** - Main platform stack with shared resources (SNS topic, IAM roles)
- **[watchy-slack-monitoring.yaml](cloudformation/watchy-slack-monitoring.yaml)** - Nested stack for Slack monitoring (Lambda, CloudWatch metrics/alarms)

## 📊 What Gets Deployed

- **Lambda Function**: Monitors Slack Status API every 5 minutes (configurable)
- **CloudWatch Metrics**: Tracks 11 Slack service health metrics
- **CloudWatch Alarms**: Alerts on incident and outage severity levels
- **CloudWatch Dashboard**: Visual monitoring interface with real-time service status
- **CloudWatch Logs**: Detailed incident history and monitoring data
- **SNS Topic**: Email notifications for service degradation
- **EventBridge Schedule**: Automated polling on your configured interval
- **IAM Roles**: Least-privilege permissions for Lambda execution

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

## 📈 CloudWatch Metrics

All metrics are published to the `Watchy/Slack` namespace:

| Metric Name | Description | Values |
|-------------|-------------|--------|
| `LoginSSO` | Login/SSO service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Messaging` | Messaging service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Notifications` | Notifications service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Search` | Search service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `WorkspaceOrgAdministration` | Admin service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Canvases` | Canvases service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Connectivity` | Connectivity service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Files` | Files service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Huddles` | Huddles service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `AppsIntegrationsAPIs` | Apps/Integrations service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `Workflows` | Workflows service status | 0=OK, 1=Notice, 2=Incident, 3=Outage |
| `ActiveIncidents` | Total number of active incidents | Count of active incidents |
| `APIResponse` | Slack Status API response code | HTTP status code |

## 🔔 CloudWatch Alarms

Each service has a dedicated alarm that triggers when severity reaches **Incident (2)** or **Outage (3)**:

- `Watchy-Slack-LoginSSO`
- `Watchy-Slack-Messaging`
- `Watchy-Slack-Notifications`
- `Watchy-Slack-Search`
- `Watchy-Slack-WorkspaceOrgAdministration`
- `Watchy-Slack-Canvases`
- `Watchy-Slack-Connectivity`
- `Watchy-Slack-Files`
- `Watchy-Slack-Huddles`
- `Watchy-Slack-AppsIntegrationsAPIs`
- `Watchy-Slack-Workflows`

Alarms send notifications to the SNS topic `Watchy-Alerts` when triggered.

## 📊 CloudWatch Dashboard

The deployment includes a comprehensive CloudWatch Dashboard with real-time visualization:

### Dashboard Widgets

1. **Service Health Timeline** - Time series chart showing all 11 Slack services with color-coded severity levels
2. **Active Incidents Counter** - Single value display of current active incidents
3. **API Response Status** - Real-time Slack Status API health indicator
4. **Recent Incident Updates** - CloudWatch Logs Insights widget showing the latest incident notes
5. **Lambda Performance** - Function invocations, errors, and execution duration
6. **Current Status Overview** - Single value display for each service (0=OK, 1=Notice, 2=Incident, 3=Outage)

The dashboard is automatically created as `{StackName}-Slack-Monitoring` and can be accessed from the CloudFormation stack outputs.

## ⚙️ Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `NotificationEmail` | Required | Email address for CloudWatch alarm notifications |
| `MonitoringSchedule` | `rate(5 minutes)` | How often to check Slack status |
| `TimeoutSeconds` | `240` | Lambda function timeout |
| `RetryAttempts` | `3` | Number of retry attempts for failed API calls |

## 💰 Cost Estimate

Typical monthly cost: **$2-5 USD**

- Lambda: ~8,640 invocations/month (5-min interval) = $0.18
- CloudWatch Logs: ~100 MB/month = $0.50
- CloudWatch Metrics: 13 custom metrics = $3.90
- SNS: Email notifications (minimal cost)

**Total**: Approximately $4.58/month (varies based on actual usage)

## 📋 CloudWatch Logs

Watchy creates detailed logs in `/watchy/slack`:

- **Log Group**: `/aws/lambda/Watchy-SlackMonitor` - Lambda execution logs
- **Incident Logs**: `/watchy/slack` - Log streams for incident history
  - Only creates log streams when incidents occur
  - Date-stamped streams: `slack-incidents-YYYY-MM-DD-timestamp`
  - Smart deduplication prevents duplicate entries

## 🔧 Architecture

```
EventBridge Schedule (5 min)
    ↓
Lambda Function (Python 3.13 + Nuitka Binary)
    ↓
Slack Status API (https://status.slack.com/api/v2.0.0/current)
    ↓
    ├─→ CloudWatch Metrics (13 metrics)
    ├─→ CloudWatch Logs (incident history)
    └─→ CloudWatch Alarms → SNS → Email
```

📋 **[View Complete Architecture Diagram](../docs/ARCHITECTURE.md)** - Detailed AWS resource topology, data flows, security layers, and cost breakdown.

## 🛡️ Security Features

- **Least Privilege IAM**: Lambda function has minimal required permissions
- **No API Keys**: Uses public Slack Status API (no authentication needed)
- **VPC Optional**: Can be deployed in VPC for additional isolation
- **Encrypted Logs**: CloudWatch logs encrypted at rest
- **SNS Encryption**: Email notifications support encryption in transit

## 🔄 Data Sources

Watchy uses the [Slack Status API v2.0.0](https://docs.slack.dev/reference/slack-status-api/):

- **Endpoint**: `https://status.slack.com/api/v2.0.0/current`
- **No Authentication Required**: Public API
- **Rate Limits**: Generous (Watchy respects reasonable polling intervals)
- **Data Format**: JSON with service status and incident details

## 📚 CloudFormation Template

The complete CloudFormation template is available in this repository:

- **Production**: [watchy-platform.yaml](./watchy-platform.yaml)

## 🆘 Troubleshooting

### No metrics appearing in CloudWatch

- Check Lambda execution logs in CloudWatch Logs
- Verify the Lambda function has internet access (or VPC NAT Gateway)
- Confirm the Slack Status API is accessible: `curl https://status.slack.com/api/v2.0.0/current`

### Not receiving email notifications

- Confirm your SNS subscription in your email (check spam folder)
- Verify CloudWatch alarms are in ALARM state (not just INSUFFICIENT_DATA)
- Check SNS topic has your email subscription confirmed

### Lambda function timing out

- Increase `TimeoutSeconds` parameter to 300 (5 minutes)
- Check CloudWatch Logs for specific error messages

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/refaktr-io/watchy/issues)
- **Custom Monitoring**: Contact us at [hello@refaktr.io](mailto:hello@refaktr.io?subject=Custom%20Monitoring%20Inquiry)
- **Documentation**: Visit [watchy.cloud](https://watchy.cloud)

## 📄 License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Copyright © 2025 [Refaktr LLC](https://refaktr.io).

## 🚀 Coming Soon

- GitHub Status Monitoring
- Zoom Status Monitoring
- Custom SaaS platform integrations
- Advanced dashboard templates
- Multi-region deployment support

---

**Built by [Refaktr LLC](https://refaktr.io)** | [Website](https://watchy.cloud) | [GitHub](https://github.com/refaktr-io/watchy)
