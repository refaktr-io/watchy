# AWS Profile Configuration for Watchy Cloud

This guide explains how to configure and use AWS profiles with the Watchy Cloud platform deployment.

## Overview

The Watchy Cloud deployment scripts have been updated to use the `watchy` AWS profile by default. This provides better security isolation and credential management.

## Setting Up the Watchy AWS Profile

### 1. Configure the Watchy Profile

```bash
# Configure the watchy profile with your credentials
aws configure --profile watchy

# You'll be prompted for:
# AWS Access Key ID: [Your Watchy Cloud Access Key]
# AWS Secret Access Key: [Your Watchy Cloud Secret Key]
# Default region name: us-east-1
# Default output format: json
```

### 2. Verify Profile Configuration

```bash
# Test the profile
aws sts get-caller-identity --profile watchy

# Check S3 access to the watchy.cloud bucket
aws s3 ls s3://watchy.cloud/ --profile watchy
```

## Using Different Profiles

### Deployment Script

The deployment script uses the `watchy` profile by default, but you can override it:

```bash
# Use default watchy profile
./deploy.sh

# Use a different profile
AWS_PROFILE=my-custom-profile ./deploy.sh

# Use default profile
AWS_PROFILE=default ./deploy.sh
```

### Customer Onboarding

Customers should also use the watchy profile when running the onboarding script:

```bash
# Use watchy profile (default)
./customer-onboard.sh

# Use a different profile if needed
AWS_PROFILE=production ./customer-onboard.sh
```

## Required Permissions

The AWS profile used for deployment needs the following permissions:

### S3 Permissions

- `s3:GetObject` on `s3://watchy.cloud/*`
- `s3:PutObject` on `s3://watchy.cloud/platform/*`
- `s3:DeleteObject` on `s3://watchy.cloud/platform/*`
- `s3:ListBucket` on `s3://watchy.cloud`

### CloudFront Permissions

- `cloudfront:ListDistributions`
- `cloudfront:CreateInvalidation`

### For Customer Deployments

- `cloudformation:CreateStack`
- `cloudformation:DescribeStacks`
- `cloudformation:DescribeStackEvents`
- `ssm:PutParameter`
- `ssm:GetParameter`
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `lambda:CreateFunction`
- `lambda:UpdateFunctionCode`
- `sns:CreateTopic`
- `sns:Subscribe`
- `events:PutRule`
- `events:PutTargets`

## Environment Variables

The following environment variables control AWS profile usage:

- `AWS_PROFILE`: The AWS profile to use (default: `watchy` for all operations)
- `AWS_REGION`: The AWS region to use (default: `us-east-1`)

## Examples

### Deploy Platform to Watchy Cloud

```bash
# Using watchy profile (default)
cd platform/deploy
./deploy-to-watchy-cloud.sh

# Using custom profile
AWS_PROFILE=watchy-prod ./deploy-to-watchy-cloud.sh
```

### Customer Deployment

```bash
# Customer uses watchy profile (default)
cd platform/scripts
./customer-onboard.sh

# Customer uses their own profile
AWS_PROFILE=customer-prod ./customer-onboard.sh
```

## Troubleshooting

### Profile Not Found

```bash
# Error: The config profile (watchy) could not be found
aws configure --profile watchy
```

### Access Denied

```bash
# Check profile credentials
aws sts get-caller-identity --profile watchy

# Check specific permissions
aws s3 ls s3://watchy.cloud/ --profile watchy
```

### Profile Override Not Working

Make sure to export the environment variable:

```bash
export AWS_PROFILE=watchy
./deploy.sh
```

Or set it inline:

```bash
AWS_PROFILE=watchy ./deploy.sh
```
