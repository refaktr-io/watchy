# Watchy Deployment Guide

## Prerequisites

Before deploying Watchy, ensure you have:

1. **AWS CLI configured** with appropriate permissions
2. **S3 bucket created** to store CloudFormation templates and Lambda packages
3. **Lambda packages uploaded** to the S3 bucket

## Step 1: Create S3 Bucket and Upload Resources

```bash
# Create S3 bucket (replace with your preferred bucket name)
aws s3 mb s3://your-watchy-resources-bucket --region us-east-1

# Upload CloudFormation templates
aws s3 cp cloudformation/watchy-monitoring-slack.yaml s3://your-watchy-resources-bucket/
aws s3 cp cloudformation/watchy-monitoring-github.yaml s3://your-watchy-resources-bucket/

# Create placeholder Lambda packages (these will be replaced by CI/CD)
cd lambda/slack_monitor
zip -r ../../slack-monitor.zip lambda_function.py
cd ../github_monitor  
zip -r ../../github-monitor.zip lambda_function.py
cd ../..

# Upload Lambda packages
aws s3 cp slack-monitor.zip s3://your-watchy-resources-bucket/
aws s3 cp github-monitor.zip s3://your-watchy-resources-bucket/
```

## Step 2: Deploy the Parent Stack

```bash
# Deploy with your email and S3 bucket name
aws cloudformation deploy \
  --template-file cloudformation/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    S3BucketName=your-watchy-resources-bucket
```

## Step 3: Verify Deployment

1. **Check stack status:**
   ```bash
   aws cloudformation describe-stacks --stack-name watchy-platform
   ```

2. **Confirm SNS subscription:**
   - Check your email for SNS subscription confirmation
   - Click the confirmation link

3. **View CloudWatch dashboards:**
   - Navigate to CloudWatch in AWS Console
   - Look for dashboards named `watchy-slack` and `watchy-github`

## Troubleshooting Common Issues

### Issue: "CloudWatch Dashboard creation failed"
- **Cause:** Invalid JSON in dashboard configuration or missing Lambda function references
- **Solution:** The templates have been updated to fix JSON formatting and Lambda function references

### Issue: "Template format error"
- **Cause:** S3 bucket doesn't exist or templates not uploaded
- **Solution:** Ensure S3 bucket exists and templates are uploaded

### Issue: "Role already exists"
- **Cause:** Previous deployment with same stack name
- **Solution:** Use a different stack name or delete the existing stack

### Issue: "Lambda package not found"
- **Cause:** Lambda zip files not uploaded to S3
- **Solution:** Upload the Lambda packages to your S3 bucket

### Issue: "Access denied"
- **Cause:** Insufficient IAM permissions
- **Solution:** Ensure your AWS credentials have CloudFormation, IAM, Lambda, SNS, and CloudWatch permissions

## Configuration Options

### Disable Specific Monitoring
```bash
# Deploy with only Slack monitoring
aws cloudformation deploy \
  --template-file cloudformation/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    S3BucketName=your-watchy-resources-bucket \
    EnableGitHubMonitoring=false
```

### Custom Monitoring Schedule
```bash
# Monitor every 10 minutes instead of 5
aws cloudformation deploy \
  --template-file cloudformation/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    S3BucketName=your-watchy-resources-bucket \
    MonitoringSchedule="rate(10 minutes)"
```

## Clean Up

To remove all resources:

```bash
# Delete the main stack (this will delete nested stacks automatically)
aws cloudformation delete-stack --stack-name watchy-platform

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name watchy-platform

# Clean up S3 bucket (optional)
aws s3 rm s3://your-watchy-resources-bucket --recursive
aws s3 rb s3://your-watchy-resources-bucket
```