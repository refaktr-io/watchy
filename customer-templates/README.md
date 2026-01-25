# Watchy Customer Templates

This directory contains CloudFormation templates for deploying Watchy open source SaaS monitoring infrastructure to your AWS account. Templates provide transparent Slack monitoring with pure Python implementation for maximum community contribution and transparency.

## Quick Start

### Deploy Slack Monitoring (Recommended)

```bash
aws cloudformation create-stack \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name watchy-slack-monitoring \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@domain.com \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)"
```

### Deploy with Existing SNS Topic

If you already have an SNS topic for notifications:

```bash
aws cloudformation create-stack \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name watchy-slack-monitoring \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=NotificationTopicArn,ParameterValue=arn:aws:sns:region:account:your-topic \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)"
```

## Architecture Benefits

- **CloudFormation IaC**: Infrastructure as code for consistent deployments
- **Pure Python Implementation**: All monitoring logic visible and transparent
- **Lambda Functions**: Event-driven monitoring with fast cold starts
- **CloudWatch Integration**: Comprehensive metrics, logs, and alarms
- **SNS Notifications**: Real-time incident alerts with customizable endpoints
- **Open Source**: Easy to modify, extend, and contribute to
- **No Binary Dependencies**: Simplified deployment and debugging

## Template URLs

Direct S3 URL for CloudFormation deployment:

- **Slack Monitoring Template**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml`

> **Note**: Additional SaaS integrations (GitHub, Zoom) are planned for future releases and will follow the same open source approach.

## Configuration

### Required Parameters

- **NotificationEmail**: Email address for alert notifications (if creating new SNS topic)
- **MonitoringSchedule**: Frequency of checks (e.g., "rate(5 minutes)")

### Optional Parameters

- **NotificationTopicArn**: ARN of existing SNS topic (if not creating new one)
- **LogLevel**: Logging level (default: INFO)
- **TimeoutSeconds**: Function timeout (default: 240)
- **RetryAttempts**: Number of retry attempts (default: 3)

### No API Keys Required

Watchy uses public status APIs that don't require authentication:

- **Slack Status API**: `https://status.slack.com/api/v2.0.0/current`
- No tokens, keys, or credentials needed
- Completely transparent and auditable

For detailed setup instructions, see [Configuration Guide](docs/configuration.md).

## Monitoring Features

After deployment, your monitoring will:

- ✅ Check Slack service status at configurable intervals
- ✅ Send real-time alerts when incidents are detected
- ✅ Log all incident details with smart deduplication
- ✅ Provide CloudWatch dashboards and metrics for all 11 Slack services
- ✅ Scale automatically based on demand
- ✅ Maintain high availability with serverless architecture
- ✅ Provide complete transparency with open source implementation

## Open Source Benefits

- **Full Transparency**: All monitoring logic visible in CloudFormation templates
- **Easy Debugging**: Standard Python debugging and logging
- **Community Contributions**: Easy for developers to understand and contribute
- **No Vendor Lock-in**: Pure AWS services with open source code
- **Customizable**: Modify alerting logic, add new services, enhance dashboards
- **Educational**: Learn AWS serverless patterns and SaaS monitoring techniques

## Support & Documentation

- **Configuration Guide**: [docs/configuration.md](docs/configuration.md)
- **Troubleshooting**: [docs/troubleshooting.md](docs/troubleshooting.md)
- **Repository**: [GitHub Repository](https://github.com/your-org/watchy-core)
- **Platform Documentation**: [Platform README](../platform/README.md)
- **Community**: GitHub Issues and Discussions

## Benefits of S3 Deployment

- ✅ Always uses the latest template version
- ✅ No downloads or local setup required
- ✅ Direct CloudFormation integration
- ✅ Faster deployment process
- ✅ Enterprise-ready and secure
- ✅ Automatic template validation

## Contributing

We welcome contributions to improve the monitoring templates:

1. Fork the repository
2. Create a feature branch
3. Make your changes to the CloudFormation templates
4. Test with your AWS account
5. Submit a pull request

Common contribution areas:
- Adding new SaaS monitoring integrations
- Improving dashboard visualizations
- Enhancing alerting logic
- Adding new deployment options

## License

These templates are provided under the MIT License. See LICENSE file for details.

---

**Watchy Cloud** - Open Source SaaS Monitoring for Transparent Enterprise Operations
