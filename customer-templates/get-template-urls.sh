#!/bin/bash

# Watchy Cloud Template URL Generator
# This script helps customers get the S3 URLs for CloudFormation templates

set -e

# Configuration - customers always use production templates
TEMPLATE_BUCKET="watchy-resources-prod"
BASE_URL="https://s3.amazonaws.com/${TEMPLATE_BUCKET}/customer-templates/templates"

echo "🚀 Watchy Cloud Template URLs"
echo "=============================================="
echo

echo "📋 Available Template:"
echo
echo "🔸 Slack Monitoring:"
echo "   ${BASE_URL}/watchy-slack-monitoring.yaml"
echo

echo "💡 Usage Example:"
echo "aws cloudformation deploy \\"
echo "  --template-url ${BASE_URL}/watchy-slack-monitoring.yaml \\"
echo "  --stack-name my-slack-monitoring \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --parameter-overrides \\"
echo "    MonitoringSchedule=\"rate(5 minutes)\" \\"
echo "  --profile watchy"
echo

echo "📚 For more deployment examples, see the customer documentation."
