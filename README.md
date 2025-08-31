# Watchy Cloud Monitoring Templates

Advanced SaaS monitoring platform with maximum source code protection using Nuitka native binaries.

## Overview

This repository contains the complete Watchy Cloud platform for monitoring multiple SaaS applications including Slack, GitHub, and Zoom. The platform uses CloudFormation nested stacks, AWS Lambda with Nuitka-compiled native binaries, and centralized license management through LemonSqueezy.

## Architecture

- **Parent Stack**: `platform/watchy-platform.yaml` - Manages shared resources and SaaS app deployment
- **Nested Stacks**: Individual SaaS monitoring applications with conditional deployment
- **Native Binaries**: Nuitka-compiled Python code for maximum IP protection
- **License Management**: Centralized LemonSqueezy integration for commercial licensing
- **Deployment**: Automated deployment to existing watchy.cloud infrastructure

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

```bash
cd platform/deploy
./deploy-to-watchy-cloud.sh
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