# Watchy - Open Source SaaS Monitoring Platform

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://s3.amazonaws.com/watchy-resources-prod/templates/watchy-platform.yaml&stackName=Watchy-Platform)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-Open%20Source-green?logo=github)](https://github.com/your-org/watchy-core)

Monitor SaaS application status with Amazon CloudWatch using **nested stack architecture** and pure Python implementation. Get real-time alerts for service degradation and incidents - all running transparently in your own AWS account.

## 🏗️ Repository Structure

```
watchy-core/
├── templates/
│   ├── watchy-platform.yaml          # Parent stack (shared resources)
│   └── watchy-slack-monitoring.yaml  # Slack monitoring nested stack
├── docs/
│   ├── configuration.md       # Configuration guide
│   └── troubleshooting.md     # Troubleshooting guide
├── scripts/
│   └── get-template-urls.sh   # Helper script for deployment URLs
└── README.md                  # This file
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
  --template-url https://s3.amazonaws.com/watchy-resources-prod/templates/watchy-platform.yaml \
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

### Slack Monitoring Nested Stack (`watchy-slack-monitoring.yaml`)
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

## ⚙️ Configuration Parameters

### Parent Stack Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `NotificationEmail` | Required | Email address for CloudWatch alarm notifications |
| `MonitoringSchedule` | `rate(5 minutes)` | How often to check SaaS service status |
| `TimeoutSeconds` | `240` | Lambda function timeout for all monitoring services |
| `RetryAttempts` | `3` | Number of retry attempts for failed API calls |
| `LogLevel` | `INFO` | Log level for all monitoring functions |
| `EnableSlackMonitoring` | `true` | Enable/disable Slack monitoring nested stack |

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

## 📚 Documentation

- **[Configuration Guide](docs/configuration.md)** - Detailed setup instructions
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions
- **[Template URLs Script](scripts/get-template-urls.sh)** - Helper for deployment URLs

## 🤝 Contributing

We welcome contributions! The open source architecture makes it easy to:

- Add new SaaS monitoring integrations
- Improve alerting logic
- Enhance dashboard visualizations
- Fix bugs and add features

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make changes to the CloudFormation templates in `templates/`
4. Test with your AWS account
5. Submit a pull request

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