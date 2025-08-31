#!/bin/bash

# Watchy Cloud Template URL Generator
# This script helps customers get the S3 URLs for CloudFormation templates

set -e

# Configuration - customers always use production templates
TEMPLATE_BUCKET="watchy-resources-prod"
PLATFORM_URL="https://releases.watchy.cloud/platform/watchy-platform.yaml"
SLACK_URL="https://s3.amazonaws.com/${TEMPLATE_BUCKET}/customer-templates/templates/watchy-slack-monitoring.yaml"

echo "🚀 Watchy Cloud Template URLs"
echo "=============================================="
echo

echo "📋 Recommended Deployment (Platform):"
echo
echo "🔸 Watchy Platform (Includes Slack Monitoring):"
echo "   ${PLATFORM_URL}"
echo

echo "📋 Individual Component (Advanced Users):"
echo
echo "🔸 Slack Monitoring Only:"
echo "   ${SLACK_URL}"
echo

echo "💡 Platform Deployment (Recommended):"
echo "aws cloudformation deploy \\"
echo "  --template-url ${PLATFORM_URL} \\"
echo "  --stack-name watchy-platform \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    NotificationEmail=your-email@domain.com \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\" \\"
echo "  --profile your-aws-profile"
echo

echo "💡 Individual Component Deployment:"
echo "aws cloudformation deploy \\"
echo "  --template-url ${SLACK_URL} \\"
echo "  --stack-name my-slack-monitoring \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\" \\"
echo "  --profile your-aws-profile"
echo

echo "📚 For more deployment examples, see the customer documentation."
