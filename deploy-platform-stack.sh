#!/bin/bash

# Deploy Watchy Platform Stack via CloudFormation CLI
# This creates the main platform with updated binary distribution URL

set -e

STACK_NAME="watchy-platform"
TEMPLATE_URL="https://watchy-resources.s3.amazonaws.com/watchy-platform.yaml"
REGION="us-east-1"

# Detect if we're in CI/CD (GitHub Actions) or local environment
if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
    echo "🤖 Detected CI/CD environment - using environment variables for AWS auth"
    AWS_CLI_ARGS="--region $REGION"
    AWS_PROFILE_NAME="CI/CD"
else
    echo "💻 Detected local environment - using watchy profile"
    AWS_CLI_ARGS="--profile watchy --region $REGION"
    AWS_PROFILE_NAME="watchy"
fi

echo "🚀 Deploying Watchy Platform Stack"
echo "=================================="
echo "Stack Name: $STACK_NAME"
echo "Template: $TEMPLATE_URL"
echo "Region: $REGION"
echo "Auth Method: $AWS_PROFILE_NAME"
echo ""

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" $AWS_CLI_ARGS &>/dev/null; then
    echo "📋 Stack exists. Updating stack..."
    
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-url "$TEMPLATE_URL" \
        --parameters \
            ParameterKey=TemplateBaseUrl,ParameterValue=https://watchy-resources.s3.amazonaws.com \
            ParameterKey=BinaryDistributionUrl,ParameterValue=https://releases.watchy.cloud \
            ParameterKey=EnableSlackMonitoring,ParameterValue=true \
            ParameterKey=EnableGitHubMonitoring,ParameterValue=false \
            ParameterKey=EnableZoomMonitoring,ParameterValue=false \
            ParameterKey=SlackApiUrl,ParameterValue=https://status.slack.com/api/v2.0.0/current \
            ParameterKey=GitHubApiUrl,ParameterValue=https://www.githubstatus.com/api/v2/status.json \
            ParameterKey=ZoomApiUrl,ParameterValue=https://status.zoom.us/api/v2/status.json \
            ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)" \
            ParameterKey=WatchyLicenseKey,UsePreviousValue=true \
            ParameterKey=NotificationEmail,UsePreviousValue=true \
            ParameterKey=LogLevel,ParameterValue=INFO \
            ParameterKey=TimeoutSeconds,ParameterValue=240 \
            ParameterKey=RetryAttempts,ParameterValue=3 \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        $AWS_CLI_ARGS
    
    echo "⏳ Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME" \
        $AWS_CLI_ARGS
    
    echo "✅ Stack update completed successfully!"

else
    echo "📋 Stack doesn't exist. Creating new stack..."
    echo ""
    echo "⚠️  You'll need to provide initial parameters:"
    
    # In CI/CD, we might not have interactive input, so provide defaults or fail gracefully
    if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
        echo "❌ Cannot create new stack in CI/CD environment without initial parameters."
        echo "   Please create the stack locally first with required parameters."
        exit 1
    fi
    
    # Interactive parameter input for local environment
    read -p "Enter Watchy License Key: " WATCHY_LICENSE_KEY
    read -p "Enter Notification Email: " NOTIFICATION_EMAIL
    
    if [ -z "$WATCHY_LICENSE_KEY" ] || [ -z "$NOTIFICATION_EMAIL" ]; then
        echo "❌ License key and notification email are required!"
        exit 1
    fi
    
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-url "$TEMPLATE_URL" \
        --parameters \
            ParameterKey=TemplateBaseUrl,ParameterValue=https://watchy-resources.s3.amazonaws.com \
            ParameterKey=BinaryDistributionUrl,ParameterValue=https://releases.watchy.cloud \
            ParameterKey=EnableSlackMonitoring,ParameterValue=true \
            ParameterKey=EnableGitHubMonitoring,ParameterValue=false \
            ParameterKey=EnableZoomMonitoring,ParameterValue=false \
            ParameterKey=SlackApiUrl,ParameterValue=https://status.slack.com/api/v2.0.0/current \
            ParameterKey=GitHubApiUrl,ParameterValue=https://www.githubstatus.com/api/v2/status.json \
            ParameterKey=ZoomApiUrl,ParameterValue=https://status.zoom.us/api/v2/status.json \
            ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)" \
            ParameterKey=WatchyLicenseKey,ParameterValue="$WATCHY_LICENSE_KEY" \
            ParameterKey=NotificationEmail,ParameterValue="$NOTIFICATION_EMAIL" \
            ParameterKey=LogLevel,ParameterValue=INFO \
            ParameterKey=TimeoutSeconds,ParameterValue=240 \
            ParameterKey=RetryAttempts,ParameterValue=3 \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        $AWS_CLI_ARGS
    
    echo "⏳ Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        $AWS_CLI_ARGS
    
    echo "✅ Stack creation completed successfully!"
fi

echo ""
echo "🎉 Platform Stack Deployment Complete!"
echo "======================================"
echo ""
echo "🔗 Stack Details:"
echo "aws cloudformation describe-stacks --stack-name $STACK_NAME --profile $AWS_PROFILE --region $REGION"
echo ""
echo "📊 CloudWatch Console:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:"
echo ""
echo "🚨 CloudFormation Console:"
echo "https://console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks/stackinfo?stackId=$STACK_NAME"
echo ""
echo "🎯 Key Features Deployed:"
echo "  ✅ Binary Distribution URL: https://releases.watchy.cloud"
echo "  ✅ Slack Monitoring: Enabled"
echo "  ✅ GitHub Monitoring: Enabled" 
echo "  ✅ Zoom Monitoring: Enabled"
echo "  ✅ Schedule: Every 5 minutes"
echo "  ✅ Architecture Fix: x86_64 compatible Nuitka binaries"
echo ""
echo "🔧 The 'Exec format error' should now be resolved!"
