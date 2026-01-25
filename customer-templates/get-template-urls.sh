#!/bin/bash

# Watchy Cloud Template URL Generator
# This script helps customers get the S3 URLs for CloudFormation templates
# Open source SaaS monitoring with pure Python implementation

set -e

# Configuration - customers always use production templates
TEMPLATE_BUCKET="watchy-resources-prod"
SLACK_URL="https://s3.amazonaws.com/${TEMPLATE_BUCKET}/customer-templates/templates/watchy-slack-monitoring.yaml"

echo "🚀 Watchy Cloud Template URLs - Open Source Edition"
echo "=============================================="
echo

echo "📋 Available Templates:"
echo
echo "🔸 Slack Monitoring (Pure Python Implementation):"
echo "   ${SLACK_URL}"
echo

echo "💡 Quick Deployment:"
echo "aws cloudformation deploy \\"
echo "  --template-url ${SLACK_URL} \\"
echo "  --stack-name watchy-slack-monitoring \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    NotificationEmail=your-email@domain.com \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\""
echo

echo "💡 Deploy with Existing SNS Topic:"
echo "aws cloudformation deploy \\"
echo "  --template-url ${SLACK_URL} \\"
echo "  --stack-name watchy-slack-monitoring \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    NotificationTopicArn=arn:aws:sns:region:account:your-topic \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\""
echo

echo "🌟 Open Source Benefits:"
echo "  • Pure Python implementation - no binaries"
echo "  • All monitoring logic visible in CloudFormation"
echo "  • Easy to modify and contribute to"
echo "  • Faster cold starts and lower memory usage"
echo "  • Community-friendly development"
echo

echo "🚀 Coming Soon:"
echo "  • GitHub Status Monitoring"
echo "  • Zoom Status Monitoring"
echo "  • Additional SaaS integrations"
echo

echo "📚 For more information:"
echo "  • Documentation: See README.md files"
echo "  • Repository: GitHub repository for issues and contributions"
echo "  • Community: GitHub Discussions for questions"
