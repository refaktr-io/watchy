#!/bin/bash

# Upload the fixed templates to S3
echo "Uploading fixed CloudFormation templates..."
aws s3 cp cloudformation/watchy-monitoring-slack.yaml s3://watchy-resources/ --profile watchy
aws s3 cp cloudformation/watchy-monitoring-github.yaml s3://watchy-resources/ --profile watchy

echo "Templates uploaded successfully!"

# Deploy the stack with the fixed templates
echo "Deploying Watchy platform..."
aws cloudformation deploy \
  --template-file cloudformation/watchy-platform.yaml \
  --stack-name watchy-platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    S3BucketName=watchy-resources \
  --profile watchy \
  --region us-east-1

echo "Deployment complete!"