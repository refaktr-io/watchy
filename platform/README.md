# Watchy - Open Source SaaS Monitoring Platform

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml&stackName=Watchy)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-Open%20Source-green?logo=github)](https://github.com/your-org/watchy-core)

Monitor SaaS application status with Amazon CloudWatch using pure Python implementation. Get real-time alerts for service degradation and incidents - all running transparently in your own AWS account.

## 🚀 Quick Start

Deploy the complete Watchy platform in 2 minutes:

1. Click the **Deploy to AWS** button above
2. Enter your notification email address
3. Review the CloudFormation parameters
4. Click **Create Stack**

That's it! Watchy will begin monitoring Slack's service status and sending alerts to your email.

### CloudFormation Templates

- **[watchy-platform.yaml](watchy-platform.yaml)** - Main platform stack with shared resources (SNS topic, IAM roles)
- **[watchy-slack-monitoring.yaml](../customer-templates/templates/watchy-slack-monitoring.yaml)** - Slack monitoring stack (Lambda, CloudWatch metrics/alarms)

## 📊 What Gets Deployed

- **Lambda Function**: Pure Python 3.13 monitoring Slack Status API every 5 minutes (configurable)
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

Typical monthly cost: **$1-3 USD**

- Lambda: ~8,640 invocations/month (5-min interval) = $0.18
- CloudWatch Logs: ~500 MB/month = $0.25
- CloudWatch Metrics: ~10 custom metrics = $0.30
- CloudWatch Alarms: 2 alarms = $0.20
- SNS: Email notifications (minimal cost) = $0.01

**Total**: Approximately $0.95-$1.50/month for standard usage (varies based on polling frequency and alert volume)

## 📋 CloudWatch Logs

Watchy automatically creates two CloudWatch Log Groups:

- **Lambda Execution Logs**: `/aws/lambda/Watchy-SlackMonitor`
  - Retention: 7 days
  - Contains Lambda function execution details
- **Incident History**: `/watchy/slack`
  - Retention: 30 days
  - Log streams created when incidents occur
  - Date-stamped streams: `slack-incidents-YYYY-MM-DD-timestamp`
  - Smart deduplication prevents duplicate entries
  - Queryable via CloudWatch Logs Insights in the dashboard

## 🔧 Architecture

Watchy uses AWS serverless architecture to monitor SaaS applications with complete transparency.

### Pure Python Lambda Implementation

Watchy runs on **AWS Lambda Python 3.13** runtime with a completely open source architecture:

**Open Source Implementation**:
- All monitoring logic visible in CloudFormation templates
- Pure Python implementation for maximum transparency
- No binary dependencies or compilation required
- Easy to modify, extend, and contribute to
- Faster cold starts and reduced memory usage (256MB vs 512MB)
- Community-friendly development and debugging

### Simplified Architecture

The Lambda function uses a **single-tier pure Python architecture**:

1. **Direct Execution**: All monitoring logic runs directly in the Lambda Python runtime
2. **No Downloads**: No binary downloads or caching complexity
3. **Transparent Logic**: All SaaS monitoring algorithms visible in the CloudFormation template
4. **Easy Debugging**: Standard Python debugging and logging
5. **Community Contributions**: Easy for developers to understand and contribute

## 🛡️ Security Features

- **Least Privilege IAM**: Lambda function has minimal required permissions
- **No API Keys**: Uses public Slack Status API (no authentication needed)
- **VPC Optional**: Can be deployed in VPC for additional isolation
- **Encrypted Logs**: CloudWatch logs encrypted at rest
- **SNS Encryption**: Email notifications support encryption in transit
- **Open Source Security**: All code visible for security auditing

## 🔄 Data Sources

Watchy uses the [Slack Status API v2.0.0](https://docs.slack.dev/reference/slack-status-api/):

- **Endpoint**: `https://status.slack.com/api/v2.0.0/current`
- **No Authentication Required**: Public API
- **Rate Limits**: Generous (Watchy respects reasonable polling intervals)
- **Data Format**: JSON with service status and incident details

## 📚 CloudFormation Template

The complete CloudFormation template is available in this repository:

- **Production**: [watchy-slack-monitoring.yaml](../customer-templates/templates/watchy-slack-monitoring.yaml)

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

## 🤝 Contributing

We welcome contributions! The open source architecture makes it easy to:

- Add new SaaS monitoring integrations
- Improve alerting logic
- Enhance dashboard visualizations
- Fix bugs and add features

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make changes to the CloudFormation templates
4. Test with your AWS account
5. Submit a pull request

## 📞 Support

- **Documentation**: This README and inline CloudFormation documentation
- **Issues**: GitHub Issues for bug reports and feature requests
- **Community**: GitHub Discussions for questions and ideas

## 📄 License

Licensed under the MIT License. See LICENSE file for details.

## 🚀 Roadmap

- GitHub Status Monitoring
- Zoom Status Monitoring
- Custom SaaS platform integrations
- Advanced dashboard templates
- Multi-region deployment support
- Webhook notifications
- Slack integration for alerts

---

**Watchy Cloud** - Open source, transparent SaaS monitoring for the modern enterprise.
