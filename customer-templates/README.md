# Watchy Customer Templates

This directory contains CloudFormation templates for deploying Watchy SaaS monitoring infrastructure to your AWS account. Templates support Slack, GitHub, and Zoom monitoring with intelligent binary caching and enterprise-grade security.

## Quick Start

### Deploy the Complete Platform (Recommended)

```bash
aws cloudformation create-stack \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@domain.com \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)" \
    ParameterKey=SlackEnabled,ParameterValue=true \
    ParameterKey=GitHubEnabled,ParameterValue=true \
    ParameterKey=ZoomEnabled,ParameterValue=true
```

### Deploy Individual Components (Advanced)

For advanced users who want granular control:

```bash

> **Note**: The Watchy platform currently focuses on **Slack monitoring**. Additional SaaS integrations (GitHub, Zoom) are planned for future releases.

#### GitHub Monitoring Only

```bash
aws cloudformation create-stack \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-github-monitoring.yaml \
  --stack-name watchy-github-monitoring \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)"
```

#### Zoom Monitoring Only

```bash
aws cloudformation create-stack \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-zoom-monitoring.yaml \
  --stack-name watchy-zoom-monitoring \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)"
```

## Architecture Benefits

- **CloudFormation IaC**: Infrastructure as code for consistent deployments
- **Nuitka Binary Compilation**: Native Python binaries for 60-70% performance improvement
- **Lambda Functions**: Event-driven monitoring with intelligent binary caching
- **CloudWatch Integration**: Comprehensive metrics, logs, and alarms
- **SNS Notifications**: Real-time incident alerts with customizable endpoints
- **Parameter Store Security**: Encrypted API key storage with KMS
- **Multi-SaaS Support**: Monitor multiple services from a single platform

## Template URLs

Direct S3 URL for CloudFormation deployment:

- **Platform Template**: `https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml`

> **Note**: Individual service templates will be available in future releases.

## Configuration

### Required Parameters

- **NotificationEmail**: Email address for alert notifications
- **MonitoringSchedule**: Frequency of checks (e.g., "rate(5 minutes)")

### Optional Parameters

- **SlackEnabled**: Enable Slack monitoring (default: true)
- **GitHubEnabled**: Enable GitHub monitoring (default: true)
- **ZoomEnabled**: Enable Zoom monitoring (default: true)
- **LogLevel**: Logging level (default: INFO)
- **TimeoutSeconds**: Function timeout (default: 240)

### API Configuration

API keys are securely stored in AWS Parameter Store:

```json
{
  "slack_token": "xoxb-your-slack-bot-token",
  "github_token": "ghp_your-github-token", 
  "zoom_token": "your-zoom-jwt-token"
}
```

For detailed API setup instructions, see [Configuration Guide](docs/configuration.md).

## Monitoring Features

After deployment, your monitoring will:

- ✅ Check service status at configurable intervals
- ✅ Send real-time alerts when issues are detected
- ✅ Log all status changes and performance metrics
- ✅ Provide CloudWatch dashboards and metrics
- ✅ Scale automatically based on demand
- ✅ Maintain high availability across regions

## Support & Documentation

- **Configuration Guide**: [docs/configuration.md](docs/configuration.md)
- **Troubleshooting**: [docs/troubleshooting.md](docs/troubleshooting.md)
- **Repository**: [GitHub Repository](https://github.com/cloudbennett/watchy.cloud)
- **Platform Documentation**: [Platform README](../platform/README.md)

## Benefits of S3 Deployment

- ✅ Always uses the latest template version
- ✅ No downloads or local setup required
- ✅ Direct CloudFormation integration
- ✅ Faster deployment process
- ✅ Enterprise-ready and secure
- ✅ Automatic template validation

## License

These templates are provided under the Watchy Cloud commercial license. For licensing questions, contact <support@watchy.cloud>.

---

**Watchy Cloud** - Enterprise SaaS Monitoring with Maximum IP Protection
