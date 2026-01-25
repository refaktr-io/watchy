#!/bin/bash

# Watchy Cloud Template URL Generator
# This script helps customers get the S3 URLs for CloudFormation templates
# Open source SaaS monitoring with nested stack architecture

set -e

# Configuration - customers always use production templates
TEMPLATE_BUCKET="watchy-resources-prod"
PLATFORM_URL="https://s3.amazonaws.com/${TEMPLATE_BUCKET}/templates/watchy-platform.yaml"
SLACK_URL="https://s3.amazonaws.com/${TEMPLATE_BUCKET}/templates/watchy-slack-monitoring.yaml"

echo "🚀 Watchy Cloud Template URLs - Nested Stack Architecture"
echo "========================================================"
echo

echo "📋 Available Templates:"
echo
echo "🔸 Platform Stack (Parent - Recommended):"
echo "   ${PLATFORM_URL}"
echo
echo "🔸 Slack Monitoring (Nested Stack):"
echo "   ${SLACK_URL}"
echo

echo "💡 Recommended Deployment (Nested Stack):"
echo "aws cloudformation deploy \\"
echo "  --template-url ${PLATFORM_URL} \\"
echo "  --stack-name Watchy-Platform \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    NotificationEmail=your-email@domain.com \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\" \\"
echo "    EnableSlackMonitoring=true"
echo

echo "💡 Alternative: Standalone Slack Monitoring:"
echo "aws cloudformation deploy \\"
echo "  --template-url ${SLACK_URL} \\"
echo "  --stack-name watchy-slack-monitoring \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    SaasAppName=Slack \\"
echo "    ApiUrl=https://status.slack.com/api/v2.0.0/current \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\" \\"
echo "    SharedLambdaRoleArn=arn:aws:iam::account:role/your-role \\"
echo "    NotificationTopicArn=arn:aws:sns:region:account:your-topic \\"
echo "    ParentStackName=your-parent-stack"
echo

echo "🌟 Nested Stack Architecture Benefits:"
echo "  • Shared resources reduce costs and complexity"
echo "  • Centralized management and configuration"
echo "  • Easy to add new SaaS monitoring services"
echo "  • Pure Python implementation - no binaries"
echo "  • All monitoring logic visible in CloudFormation"
echo "  • Community-friendly development"
echo

echo "🚀 Future Nested Stacks:"
echo "  • GitHub Status Monitoring"
echo "  • Zoom Status Monitoring"
echo "  • Custom SaaS integrations"
echo

echo "📚 For more information:"
echo "  • Documentation: See README.md files"
echo "  • Repository: GitHub repository for issues and contributions"
echo "  • Community: GitHub Discussions for questions"
