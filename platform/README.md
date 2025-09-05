# Watchy Cloud - Multi-SaaS Monitoring Platform

A comprehensive SaaS monitoring platform built on AWS with native Nuitka binaries for maximum source code protection. Monitors Slack, GitHub, Zoom, and other SaaS applications with centralized license management and alerting.

## 🏗️ Architecture Overview

```text
watchy-platform.yaml (Parent Stack)
├── Shared Resources
│   ├── SNS Topics & Subscriptions
│   ├── IAM Roles & Policies
│   └── Parameter Store (License Keys)
└── Platform Infrastructure
    ├── CloudFormation Templates
    ├── Lambda Functions (Nuitka)
    ├── CloudWatch Resources
    ├── SNS Topics & Subscriptions
    ├── IAM Roles & Policies
    └── Parameter Store (License Keys)
```

## 🔒 Security Features

- **Nuitka Native Binaries**: Python source compiled to x86_64 native executables
- **LemonSqueezy License Validation**: Commercial license validation embedded in binaries
- **Parameter Store Encryption**: API keys stored with KMS encryption
- **IAM Least Privilege**: Minimal permissions per service
- **Binary Integrity**: SHA256 verification for all distributed binaries

## 📦 Platform Components

### Parent Stack (`platform/watchy-platform.yaml`)

- **Purpose**: Manages shared resources and deploys SaaS-specific monitoring
- **Resources**: SNS topics, IAM roles, Parameter Store, nested stack deployment
- **Parameters**: License key, customer ID, SaaS app selection

### Binary Monitors

#### Slack Monitor (`platform/binaries/slack-monitor/`)

- **Source**: `watchy_slack_monitor.py`
- **Build**: `build.sh` (Nuitka compilation)
- **Services**: Slack API, messaging, file sharing, calls
- **Binary**: `watchy-slack-monitor`

#### GitHub Monitor (`platform/binaries/github-monitor/`)

- **Source**: `watchy_github_monitor.py`
- **Build**: `build.sh` (Nuitka compilation)
- **Services**: GitHub API, Git operations, Actions, Pages
- **Binary**: `watchy-github-monitor`

#### Zoom Monitor (`platform/binaries/zoom-monitor/`)

- **Source**: `watchy_zoom_monitor.py`
- **Build**: `build.sh` (Nuitka compilation)
- **Services**: Meetings, webinars, recordings, chat, phone
- **Binary**: `watchy-zoom-monitor`

## 🚀 Deployment Guide

### Prerequisites

1. **AWS Account** with CloudFormation permissions
2. **LemonSqueezy License Key** for commercial usage
3. **SaaS API Keys** (Slack, GitHub, Zoom tokens)
4. **Binary Distribution Server** to host compiled binaries

### Step 1: Build Native Binaries

```bash
# Build Slack monitor
cd platform/binaries/slack-monitor
./build.sh

# Build GitHub monitor
cd ../github-monitor
./build.sh

# Build Zoom monitor
cd ../zoom-monitor
./build.sh
```

### Step 2: Upload Binaries to Distribution Server

Upload the compressed binaries to your distribution server:

- `watchy-slack-monitor-1.0.0.gz`
- `watchy-github-monitor-1.0.0.gz`
- `watchy-zoom-monitor-1.0.0.gz`

### Step 3: Configure Parameters

Set the required parameters for CloudFormation deployment:

```yaml
# Required Parameters
WatchyLicenseKey: "lemon_sq_12345678..."  # Your LemonSqueezy license
CustomerID: "customer-123"                  # Unique customer identifier
SlackEnabled: true                         # Enable Slack monitoring
GitHubEnabled: true                        # Enable GitHub monitoring
ZoomEnabled: true                          # Enable Zoom monitoring

# Binary Distribution URLs
SlackBinaryURL: "https://releases.watchy.cloud/binaries/slack-monitor/latest.gz"
GitHubBinaryURL: "https://releases.watchy.cloud/binaries/github-monitor/latest.gz"
ZoomBinaryURL: "https://releases.watchy.cloud/binaries/zoom-monitor/latest.gz"

# API Keys (stored in Parameter Store)
SlackToken: "xoxb-your-slack-token"
GitHubToken: "ghp_your-github-token"
ZoomToken: "your-zoom-jwt-token"
```

### Step 4: Deploy Platform

```bash
# Deploy the main platform stack
aws cloudformation deploy \
  --template-file platform/watchy-platform.yaml \
  --stack-name watchy-monitoring-platform \
  --parameter-overrides \
    WatchyLicenseKey="lemon_sq_12345678..." \
    CustomerID="customer-123" \
    SlackEnabled=true \
    GitHubEnabled=true \
    ZoomEnabled=true \
    NotificationEmail="alerts@yourcompany.com" \
  --capabilities CAPABILITY_IAM
```

## 📊 Monitoring & Alerting

### CloudWatch Metrics

All monitors publish metrics to CloudWatch under namespace `Watchy/{SaaSApp}`:

- **ServiceAvailability**: Percentage of services available (0-100%)
- **ResponseTime**: API response times in milliseconds
- **ErrorRate**: Failed requests per minute

### SNS Notifications

Critical service outages trigger SNS alerts containing:

- Affected SaaS application
- Failed services list
- Response times and error details
- Customer ID and timestamp

### CloudWatch Alarms

Automatic alarms are created for:

- **Critical Service Outages**: Availability < 100% for critical services
- **High Response Times**: Response time > 5 seconds
- **License Validation Failures**: Monitor execution errors

## 🔧 Configuration

### Environment Variables

Each Lambda function uses these environment variables:

```bash
WATCHY_LICENSE_KEY="lemon_sq_..."      # LemonSqueezy license key
WATCHY_CUSTOMER_ID="customer-123"      # Customer identifier
WATCHY_SNS_TOPIC_ARN="arn:aws:sns:..." # SNS topic for alerts
WATCHY_BINARY_URL="https://..."        # Binary download URL
```

### Parameter Store Schema

API keys are stored in Parameter Store with encryption:

```json
{
  "slack_token": "xoxb-your-slack-token",
  "github_token": "ghp_your-github-token",
  "zoom_token": "your-zoom-jwt-token"
}
```

Parameter name: `/watchy/api-keys/{CustomerID}`

## 🧪 Testing

### Binary Testing

Each build script includes binary execution tests:

```bash
# Test individual monitors
cd platform/binaries/slack-monitor
export WATCHY_LICENSE_KEY="test_key"
./build/watchy-slack-monitor

# Expected output: JSON monitoring results
```

### Local Development

For development without Nuitka compilation:

```bash
# Set environment variables
export WATCHY_LICENSE_KEY="lemon_sq_..."
export WATCHY_CUSTOMER_ID="test-customer"

# Run Python source directly
python3 platform/binaries/slack-monitor/watchy_slack_monitor.py
```

## 🔍 Troubleshooting

### Common Issues

1. **License Validation Failure**
   - Verify LemonSqueezy license key is valid
   - Check internet connectivity for license validation
   - Ensure customer ID matches license

2. **Binary Download Failure**
   - Verify binary distribution URL is accessible
   - Check Lambda function has internet access
   - Validate binary SHA256 hash

3. **API Authentication Errors**
   - Verify API tokens in Parameter Store
   - Check token permissions for required API endpoints
   - Ensure tokens haven't expired

4. **CloudWatch Metrics Missing**
   - Verify IAM permissions for CloudWatch
   - Check Lambda function execution logs
   - Ensure metrics namespace is correct

### Debug Commands

```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks --stack-name watchy-monitoring-platform

# View Lambda function logs
aws logs tail /aws/lambda/watchy-slack-monitor --follow

# Test Parameter Store access
aws ssm get-parameter --name "/watchy/api-keys/customer-123" --with-decryption
```

## 📈 Scaling & Customization

### Adding New SaaS Apps

1. Create binary monitor source (follow existing patterns)
2. Create build script for Nuitka compilation
3. Add SaaS-specific CloudFormation template
4. Update parent template with new nested stack
5. Add conditional parameters for enabling/disabling

### Custom Monitoring Logic

Each monitor can be customized by:

- Modifying service endpoints in the source
- Adding new service checks
- Adjusting alert thresholds
- Implementing custom metrics

### Multi-Region Deployment

Deploy the platform across multiple regions:

```bash
# Deploy to us-east-1
aws cloudformation deploy --region us-east-1 ...

# Deploy to eu-west-1
aws cloudformation deploy --region eu-west-1 ...
```

## 📄 License

This is a commercial monitoring platform requiring a valid LemonSqueezy license. The platform includes:

- **Source Code Protection**: Nuitka native compilation
- **License Validation**: Embedded LemonSqueezy validation
- **Commercial Support**: Priority support for licensed users
- **Updates**: Automatic binary updates through distribution server

For licensing questions, contact: <support@watchy.cloud>

## 🤝 Support

- **Documentation**: [docs.watchy.cloud](https://docs.watchy.cloud)
- **Support Portal**: [support.watchy.cloud](https://support.watchy.cloud)
- **Status Page**: [status.watchy.cloud](https://status.watchy.cloud)
- **Community**: [community.watchy.cloud](https://community.watchy.cloud)

## 📚 Additional Documentation

- **Intelligent Binary Caching**: [intelligent-binary-caching.md](intelligent-binary-caching.md)
- **CloudFront Cache Invalidation**: [cloudfront-cache-invalidation.md](cloudfront-cache-invalidation.md)

---

**Watchy Cloud** - Enterprise SaaS Monitoring with Maximum IP Protection
