# Watchy Customer Templates

**Simplified Slack Monitoring Platform**

This directory contains CloudFormation templates for deploying Watchy Slack status monitoring infrastructure to your AWS account.

## Available Template

**Slack Status Monitoring**: Monitor Slack's service status and incidents via Status API with intelligent binary caching and enhanced performance

## Architecture

Watchy uses a simplified Slack-only architecture with:
- **CloudFormation IaC**: Infrastructure as code for consistent deployments
- **Nuitka Binary Compilation**: Native Python binaries for 60-70% performance improvement
- **Lambda Functions**: Event-driven monitoring with intelligent binary caching
- **CloudWatch Integration**: Metrics, logs, and alarms
- **SNS Notifications**: Real-time incident alerts

## Quick Deployment

### **Slack Status Monitoring**

```bash
aws cloudformation create-stack 
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml 
  --stack-name my-slack-monitoring 
  --capabilities CAPABILITY_IAM 
  --parameters 
    ParameterKey=ParentStackName,ParameterValue=my-slack-monitoring 
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)"
```

**💡 Benefits of S3 deployment:**

- ✅ Always uses the latest template version
- ✅ No downloads or setup required
- ✅ Direct CloudFormation deployment
- ✅ Faster deployment process
- ✅ Enterprise-ready and secure

## Template URLs

**Direct S3 URLs for CloudFormation:**

- **Slack Monitoring**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml`

## Configuration

See the [configuration guide](docs/configuration.md) for detailed parameter documentation and API setup instructions.

## Support

- **Documentation**: [Troubleshooting Guide](docs/troubleshooting.md)
- **Repository**: [GitHub Repository](https://github.com/cloudbennett/watchy.cloud)
- **Issues**: Submit issues via GitHub

## Simplified Architecture Benefits

- **Focused Solution**: Dedicated Slack monitoring without unnecessary complexity
- **Enhanced Performance**: 60-70% improvement with intelligent binary caching
- **Cost Optimized**: Single-service architecture reduces resource overhead
- **Simplified Management**: Easier deployment and maintenance

## 🔧 **Configuration Options**

### **Common Parameters**

- `MonitoringSchedule`: How often to check (e.g., "rate(5 minutes)")
- `ApiUrl`: The status API endpoint to monitor

### **Alert Configuration**

- Configure SNS topics for notifications
- Set up email/SMS alerts
- Customize alert thresholds

## 📊 **Monitoring Dashboard**

After deployment, your monitoring will:

- ✅ Check service status regularly
- ✅ Send alerts when issues are detected
- ✅ Log all status changes
- ✅ Provide CloudWatch metrics

## 🆘 **Support**

- **Email**: [contact@watchy.cloud](mailto:contact@watchy.cloud)
- **Issues**: Contact our support team for troubleshooting
- **Documentation**: This README contains all deployment information

## 📝 **License**

These templates are provided under the Watchy Cloud license terms.
