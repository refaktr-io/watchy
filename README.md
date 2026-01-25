# Watchy Cloud - Open Source SaaS Monitoring Platform

**Enterprise-grade SaaS monitoring for AWS with complete transparency**

Watchy Cloud provides comprehensive monitoring for critical SaaS applications using AWS serverless infrastructure. The platform is now completely open source with pure Python implementations for maximum transparency and community contribution.

## 🚀 Quick Start

Deploy the complete monitoring platform in under 2 minutes:

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail="alerts@yourcompany.com"
```

## 📊 Architecture

**Pure Python Serverless Architecture:**
- **AWS Lambda**: Pure Python 3.13 runtime (no binaries)
- **CloudWatch**: Metrics, alarms, and incident logging
- **SNS**: Email and webhook notifications
- **EventBridge**: Scheduled monitoring execution
- **CloudFormation**: Infrastructure as Code deployment

## 🎯 Currently Monitored Services

### Slack Status Monitoring
- **11 Service Components**: Login/SSO, Messaging, Notifications, Search, Workspace/Org Administration, Canvases, Connectivity, Files, Huddles, Apps/Integrations/APIs, Workflows
- **Real-time Incident Tracking**: Automatic detection and logging
- **Smart Deduplication**: Prevents duplicate incident notifications
- **Severity Levels**: Notice (1), Incident (2), Outage (3)

## 🏗️ Repository Structure

```
watchy-core/
├── customer-templates/          # Customer deployment templates
│   ├── templates/
│   │   └── watchy-slack-monitoring.yaml  # Complete Slack monitoring stack
│   └── docs/                   # Customer documentation
├── platform/
│   ├── README.md              # Platform documentation
│   └── watchy-platform.yaml   # Main platform template
└── README.md                  # This file
```

## 🔧 Development Setup

### Prerequisites
- AWS CLI v2 configured
- Python 3.13+
- CloudFormation permissions

### Local Development
```bash
# Clone repository
git clone https://github.com/your-org/watchy-core.git
cd watchy-core

# Deploy to your AWS account
aws cloudformation deploy \
  --template-file customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name my-watchy-test \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    MonitoringSchedule="rate(5 minutes)" \
    NotificationTopicArn="arn:aws:sns:us-east-1:123456789012:my-alerts"
```

## 🌟 Key Features

### Open Source Transparency
- **Pure Python**: All monitoring logic visible in CloudFormation templates
- **No Binaries**: Eliminated Nuitka compilation complexity
- **Community Friendly**: Easy to contribute and modify
- **Reduced Overhead**: Faster cold starts, lower memory usage

### Enterprise Monitoring
- **Multi-Service Support**: Extensible architecture for additional SaaS platforms
- **Intelligent Alerting**: Context-aware notifications with incident details
- **Cost Effective**: Typical cost $1-3/month per monitored service
- **Scalable**: Serverless architecture handles any load

### Security & Compliance
- **IAM Least Privilege**: Minimal required permissions
- **No API Keys**: Uses public status APIs only
- **VPC Optional**: Can run in isolated network environments
- **Audit Trail**: Complete CloudWatch logging

## 📈 Monitoring Capabilities

### CloudWatch Metrics (13 total)
- 11 Slack service health metrics (0=OK, 1=Notice, 2=Incident, 3=Outage)
- Active incident count
- API response status

### CloudWatch Alarms (12 total)
- Individual service alarms for each Slack component
- API response monitoring
- Automatic SNS notifications

### CloudWatch Dashboard
- Real-time service health visualization
- Historical incident trends
- Lambda performance metrics
- Recent incident log insights

## 🚀 Deployment Options

### Option 1: Complete Platform
Deploy everything including shared resources:
```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM
```

### Option 2: Slack Monitoring Only
Deploy just Slack monitoring (requires existing SNS topic):
```bash
aws cloudformation deploy \
  --template-file customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name watchy-slack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationTopicArn="arn:aws:sns:region:account:topic-name"
```

## 🔄 Migration from Binary Version

If upgrading from a previous Nuitka binary version:

1. **Backup Configuration**: Export your current stack parameters
2. **Deploy New Version**: Use the same stack name to update in place
3. **Verify Functionality**: Check CloudWatch metrics and alarms
4. **Clean Up**: Old binary distribution resources are no longer needed

The new pure Python version is fully compatible and will maintain all existing metrics and alarm history.

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

- **Documentation**: See `platform/README.md` for detailed technical docs
- **Issues**: GitHub Issues for bug reports and feature requests
- **Community**: Discussions for questions and ideas

## 📄 License

Open source under MIT License. See LICENSE file for details.

---

**Watchy Cloud** - Transparent, reliable SaaS monitoring for the modern enterprise.
