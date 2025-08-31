# Watchy Cloud Platform

Advanced SaaS monitoring platform with secure native binaries and clear separation between platform infrastructure and customer deliverables.

## 🔒 **Security Features**

This repository implements comprehensive security scanning and monitoring:

- **🔍 Automated Security Scanning**: Dependency vulnerabilities, Python security analysis, secret detection
- **🤖 Automated Updates**: Dependabot for weekly dependency updates and security patches  
- **🛡️ Security Workflow**: Security scans on every main branch push with CI/CD integration
- **📊 Continuous Monitoring**: GitHub Security tab integration and deployment notifications

See [SECURITY.md](SECURITY.md) for complete security policy and procedures.

## 🏗️ **Repository Structure**

```
watchy.cloud/
├── 🌐 platform/                   # PLATFORM INFRASTRUCTURE
│   ├── infrastructure/            # CloudFormation for watchy.cloud
│   ├── binaries/                  # Monitor source code & builds
│   ├── deploy/                    # Platform deployment scripts
│   └── watchy-platform.yaml      # Main platform template
│
├── 📦 customer-templates/         # CUSTOMER DELIVERABLES
│   ├── templates/                 # CloudFormation templates
│   ├── scripts/                   # Customer setup scripts
│   └── docs/                      # Customer documentation
│
├── 🔧 development/                # DEVELOPMENT RESOURCES  
│   ├── tests/                     # Testing framework
│   └── docs/                      # Development documentation
│
├── 🌐 website/                    # watchy.cloud website
└── 📋 [root files]                # README, LICENSE, etc.
```

## 🎯 **Clear Separation of Concerns**

### **For Platform Developers**
- Work in `platform/` for infrastructure
- Use `development/` for CI/CD and testing
- Deploy via GitHub Actions

### **For Customers**  
- Download `customer-templates/` folder
- Follow `customer-templates/README.md`
- Deploy monitoring in their AWS accounts

## Quick Start

### 1. Configure AWS Profile

```bash
# Set up the watchy AWS profile
aws configure --profile watchy

# Verify access
aws sts get-caller-identity --profile watchy
aws s3 ls s3://watchy.cloud/ --profile watchy
```

### 2. Deploy Platform

🚀 **Deployment is now handled by GitHub Actions**

```bash
# Push to main branch for automatic deployment
git add .
git commit -m "Deploy platform updates"
git push origin main

# OR trigger manual deployment via GitHub Actions
# Go to: https://github.com/cloudbennett/watchy.cloud/actions
```

### 3. Customer Onboarding

```bash
cd platform/scripts
./customer-onboard.sh
```

## Platform Components

### SaaS Monitors

- **Slack Monitor**: Real-time Slack API monitoring with team health checks
- **GitHub Monitor**: Repository and API availability monitoring
- **Zoom Monitor**: Meeting services and API endpoint monitoring

### Infrastructure

- **Binary Distribution**: CloudFront CDN serving Nuitka binaries
- **License Management**: Centralized LemonSqueezy validation
- **Monitoring**: CloudWatch integration with custom metrics

### Configuration

Environment variables for platform operation:

- `WATCHY_VERSION`: Platform version (auto-generated)
- `WATCHY_BINARY_DISTRIBUTION_URL`: Binary CDN endpoint
- `WATCHY_LICENSE_PARAMETER`: SSM parameter for license key

## Security Features

### Source Code Protection

- **Nuitka Compilation**: Python source compiled to native x86_64 binaries
- **No Reverse Engineering**: Compiled code provides maximum IP protection
- **License Validation**: Runtime license checking through LemonSqueezy API

### AWS Security

- **IAM Roles**: Least privilege access for Lambda functions
- **Parameter Store**: Encrypted API key storage
- **VPC Support**: Optional VPC deployment for enhanced security

## Development

### Building Binaries (Local Development)

```bash
# Build individual monitors for local testing
cd platform/binaries/slack-monitor
./build.sh

cd ../github-monitor
./build.sh

cd ../zoom-monitor
./build.sh
```

**Note**: Production binaries are built automatically via GitHub Actions.

### Testing Deployment

🚀 **All deployment now happens via GitHub Actions**

```bash
# Local testing only (no deployment)
python3 platform/binaries/slack-monitor/watchy_slack_monitor.py

# For deployment: Push to GitHub
git push origin main
```

## GitHub Actions Deployment

### Automatic Triggers
- **Push to `main`** → Deploy to production
- **Pull Requests** → Validate and test
- **Manual trigger** → Deploy specific version/environment

### Required Secrets
Set these in GitHub repository settings:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SSL_CERTIFICATE_ARN` (for `*.watchy.cloud`)

See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete deployment guide.

## Requirements

### System Requirements (for local development)

- Python 3.11+
- Nuitka compiler (for local binary building)
- AWS CLI v2.x (for local testing)

### AWS Permissions

See [AWS_PROFILE_SETUP.md](./AWS_PROFILE_SETUP.md) for detailed permission requirements.

**Note**: GitHub Actions handles all production deployment with minimal required permissions.

## Support

For support and licensing inquiries, visit [watchy.cloud](https://watchy.cloud).

## License

Commercial license required. Contact us for licensing information.

## Platform Components

### SaaS Monitors

- **Slack Monitor**: Real-time Slack API monitoring with team health checks
- **GitHub Monitor**: Repository and API availability monitoring
- **Zoom Monitor**: Meeting services and API endpoint monitoring

### Deployment Structure

```text
platform/
├── watchy-platform.yaml          # Parent CloudFormation template
├── binaries/                     # Nuitka source files
│   ├── slack-monitor/
│   ├── github-monitor/
│   └── zoom-monitor/
├── saas-apps/                    # Nested stack templates
├── deploy/                       # Deployment scripts
└── scripts/                      # Customer onboarding
```

### Distribution

- **S3 Bucket**: `s3://watchy.cloud/platform/`
- **CloudFront**: Global CDN distribution
- **Domain**: `https://watchy.cloud/platform/`

## AWS Profile Configuration

The platform uses the `watchy` AWS profile by default. See [AWS_PROFILE_SETUP.md](./AWS_PROFILE_SETUP.md) for detailed configuration instructions.

### Environment Variables

- `AWS_PROFILE`: AWS profile to use (default: `watchy`)
- `AWS_REGION`: AWS region (default: `us-east-1`)
- `WATCHY_VERSION`: Platform version (default: `1.0.0`)

## Security Features

### Source Code Protection

- **Nuitka Compilation**: Python source compiled to native x86_64 binaries
- **No Reverse Engineering**: Compiled code provides maximum IP protection
- **License Validation**: Runtime license checking through LemonSqueezy API

### AWS Security

- **IAM Roles**: Least privilege access for Lambda functions
- **Parameter Store**: Encrypted API key storage
- **VPC Support**: Optional VPC deployment for enhanced security

## Development

### Building Binaries

```bash
cd platform/binaries/slack-monitor
./build.sh

cd ../github-monitor
./build.sh

cd ../zoom-monitor
./build.sh
```

### Testing Deployment

```bash
# Test with different profile
AWS_PROFILE=dev ./deploy-to-watchy-cloud.sh

# Test customer onboarding
AWS_PROFILE=customer ./customer-onboard.sh
```

## Requirements

### System Requirements

- AWS CLI v2.x
- Python 3.11+
- Nuitka compiler
- curl, jq (for scripts)

### AWS Permissions

See [AWS_PROFILE_SETUP.md](./AWS_PROFILE_SETUP.md) for detailed permission requirements.

## Support

For support and licensing inquiries, visit [watchy.cloud](https://watchy.cloud).

## License

Commercial license required. Contact us for licensing information.
