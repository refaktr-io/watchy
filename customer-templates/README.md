# Watchy Cloud Monitoring - Customer Deployment Guide

## 🚀 **Quick Start for Customers**

This guide helps you deploy Watchy monitoring templates in your AWS environment.

## 📋 **Prerequisites**

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with your credentials
3. **CloudFormation** access to deploy stacks

## 🔧 **Available Monitoring Templates**

### **Slack Status Monitoring**
- **Template**: `templates/watchy-slack-monitoring.yaml`
- **Purpose**: Monitor Slack service status and incidents
- **Requirements**: Slack API access

### **GitHub Status Monitoring**  
- **Template**: `templates/watchy-github-monitoring.yaml`
- **Purpose**: Monitor GitHub service status and incidents
- **Requirements**: GitHub API access

### **Zoom Status Monitoring**
- **Template**: `templates/watchy-zoom-monitoring.yaml`
- **Purpose**: Monitor Zoom service status and incidents
- **Requirements**: Zoom API access

### **Custom SaaS Template**
- **Template**: `templates/watchy-saas-template.yaml` 
- **Purpose**: Template for monitoring any SaaS service
- **Requirements**: Customization for your specific service

## 🚀 **Deployment Steps**

### **1. Download Templates**
```bash
# Clone or download the customer templates
git clone https://github.com/cloudbennett/watchy.cloud.git
cd watchy.cloud/customer-templates
```

### **2. Configure Environment** 
```bash
# Run the customer onboarding script
./scripts/customer-onboard.sh
```

### **3. Deploy Monitoring**
```bash
# Deploy a specific monitoring template
aws cloudformation deploy \
  --template-file templates/watchy-slack-monitoring.yaml \
  --stack-name my-slack-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ApiUrl=https://status.slack.com/api/v2.0.0/current \
    MonitoringSchedule="rate(5 minutes)"
```

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

- **Documentation**: See `docs/` folder for detailed guides
- **Troubleshooting**: Check `docs/troubleshooting.md`
- **Configuration**: See `docs/configuration.md`

## 📝 **License**

These templates are provided under the Watchy Cloud license. See the main repository for license details.
