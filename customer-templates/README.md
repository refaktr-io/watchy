# Watchy Cloud Monitoring - Customer Deployment Guide

## 🚀 **Quick Start for Customers**

Deploy Watchy monitoring templates directly from our hosted S3 templates - no downloads required!

## 📋 **Prerequisites**

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with your credentials
3. **CloudFormation** access to deploy stacks

## 🔧 **Available Monitoring Templates**

- **Slack Status Monitoring**: Monitor Slack service status and incidents
- **GitHub Status Monitoring**: Monitor GitHub's service status via Status API  
- **Zoom Status Monitoring**: Monitor Zoom service status and incidents
- **Custom SaaS Template**: Template for monitoring any SaaS service (requires customization)

## 🚀 **Deployment Steps**

Deploy monitoring templates directly from our hosted S3 URLs:

### **Slack Status Monitoring**

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name my-slack-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ApiUrl=https://status.slack.com/api/v2.0.0/current \
    MonitoringSchedule="rate(5 minutes)"
```

### **GitHub Status Monitoring**

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-github-monitoring.yaml \
  --stack-name my-github-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    MonitoringSchedule="rate(5 minutes)"
```

### **Zoom Status Monitoring**

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-zoom-monitoring.yaml \
  --stack-name my-zoom-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    MonitoringSchedule="rate(5 minutes)"
```

### **Custom SaaS Monitoring**

```bash
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-saas-template.yaml \
  --stack-name my-custom-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SaasAppName="MyService" \
    ApiUrl="https://status.myservice.com/api/v1/status" \
    MonitoringSchedule="rate(10 minutes)"
```

**💡 Benefits of S3 deployment:**

- ✅ Always uses the latest template version
- ✅ No downloads or setup required
- ✅ Direct CloudFormation deployment
- ✅ Faster deployment process
- ✅ Enterprise-ready and secure

## 🌐 **Available Template URLs**

For direct S3 deployment, use these URLs:

- **Slack Monitoring**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml`
- **GitHub Monitoring**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-github-monitoring.yaml`
- **Zoom Monitoring**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-zoom-monitoring.yaml`
- **SaaS Template**: `https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-saas-template.yaml`

## 🔧 **Configuration Options**

### **Common Parameters**

- `MonitoringSchedule`: How often to check (e.g., "rate(5 minutes)")
- `ApiUrl`: The status API endpoint to monitor
- `SaasAppName`: Display name for the service

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
