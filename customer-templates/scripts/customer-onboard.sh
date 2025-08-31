#!/bin/bash

# Watchy Cloud Customer Onboarding Script
# Helps customers deploy Watchy monitoring templates in their AWS environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"
DOCS_DIR="$(dirname "$SCRIPT_DIR")/docs"

AWS_PROFILE=${AWS_PROFILE:-"default"}

echo "🎯 Watchy Cloud - Customer Onboarding"
echo "====================================="
echo "AWS Profile: $AWS_PROFILE"
echo "Templates Directory: $TEMPLATES_DIR"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
    echo "❌ AWS credentials not configured for profile '$AWS_PROFILE'. Please run:"
    echo "   aws configure --profile $AWS_PROFILE"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "❌ curl not found. Please install curl."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Get platform information
echo ""
echo "📊 Getting platform information..."

platform_info=$(curl -s "$PLATFORM_API/version.json" 2>/dev/null || echo '{}')

if echo "$platform_info" | jq -e '.version' > /dev/null 2>&1; then
    platform_version=$(echo "$platform_info" | jq -r '.version')
    platform_date=$(echo "$platform_info" | jq -r '.release_date')
    
    echo "✅ Platform accessible"
    echo "   Version: $platform_version"
    echo "   Release Date: $(date -d "$platform_date" "+%Y-%m-%d" 2>/dev/null || echo "$platform_date")"
else
    echo "⚠️  Platform API not accessible. Continuing with defaults..."
    platform_version="latest"
fi

# Collect deployment information
echo ""
echo "📝 Deployment Configuration"
echo "=========================="

read -p "Enter your Watchy license key: " LICENSE_KEY
if [ -z "$LICENSE_KEY" ]; then
    echo "❌ License key is required"
    exit 1
fi

read -p "Enter your notification email: " NOTIFICATION_EMAIL
if [ -z "$NOTIFICATION_EMAIL" ]; then
    echo "❌ Notification email is required"
    exit 1
fi

read -p "Enter a name for your CloudFormation stack (default: watchy-platform): " STACK_NAME
STACK_NAME=${STACK_NAME:-watchy-platform}

read -p "Enter your customer ID (default: ${STACK_NAME}): " CUSTOMER_ID
CUSTOMER_ID=${CUSTOMER_ID:-$STACK_NAME}

echo ""
echo "🎛️  SaaS Application Selection"
echo "============================="

read -p "Enable Slack monitoring? (y/N): " ENABLE_SLACK
read -p "Enable GitHub monitoring? (y/N): " ENABLE_GITHUB
read -p "Enable Zoom monitoring? (y/N): " ENABLE_ZOOM

# Convert to CloudFormation boolean values
ENABLE_SLACK=$([ "${ENABLE_SLACK,,}" = "y" ] && echo "true" || echo "false")
ENABLE_GITHUB=$([ "${ENABLE_GITHUB,,}" = "y" ] && echo "true" || echo "false")
ENABLE_ZOOM=$([ "${ENABLE_ZOOM,,}" = "y" ] && echo "true" || echo "false")

# Ask about API keys if services are enabled
declare -A API_KEYS

if [ "$ENABLE_SLACK" = "true" ]; then
    echo ""
    read -p "Enter your Slack Bot Token (xoxb-...): " SLACK_TOKEN
    API_KEYS["slack_token"]="$SLACK_TOKEN"
fi

if [ "$ENABLE_GITHUB" = "true" ]; then
    echo ""
    read -p "Enter your GitHub Personal Access Token (ghp_...): " GITHUB_TOKEN
    API_KEYS["github_token"]="$GITHUB_TOKEN"
fi

if [ "$ENABLE_ZOOM" = "true" ]; then
    echo ""
    read -p "Enter your Zoom JWT Token: " ZOOM_TOKEN
    API_KEYS["zoom_token"]="$ZOOM_TOKEN"
fi

# Display configuration summary
echo ""
echo "📋 Deployment Summary"
echo "===================="
echo "Stack name: $STACK_NAME"
echo "Customer ID: $CUSTOMER_ID"
echo "Platform version: $platform_version"
echo "Notification email: $NOTIFICATION_EMAIL"
echo "Slack monitoring: $ENABLE_SLACK"
echo "GitHub monitoring: $ENABLE_GITHUB"
echo "Zoom monitoring: $ENABLE_ZOOM"

echo ""
read -p "Proceed with deployment? (y/N): " PROCEED
if [ "${PROCEED,,}" != "y" ]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

# Create API keys in Parameter Store if any services are enabled
if [ ${#API_KEYS[@]} -gt 0 ]; then
    echo ""
    echo "🔐 Storing API keys in Parameter Store..."
    
    # Convert API_KEYS associative array to JSON
    api_keys_json="{"
    first=true
    for key in "${!API_KEYS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            api_keys_json="${api_keys_json},"
        fi
        api_keys_json="${api_keys_json}\"${key}\":\"${API_KEYS[$key]}\""
    done
    api_keys_json="${api_keys_json}}"
    
    # Store in Parameter Store
    parameter_name="/watchy/api-keys/$CUSTOMER_ID"
    
    aws ssm put-parameter \
        --profile "$AWS_PROFILE" \
        --name "$parameter_name" \
        --value "$api_keys_json" \
        --type "SecureString" \
        --overwrite \
        --description "Watchy API keys for customer $CUSTOMER_ID"
    
    echo "✅ API keys stored in Parameter Store: $parameter_name"
fi

# Deploy the CloudFormation stack
echo ""
echo "🚀 Deploying Watchy Cloud platform..."

template_url="https://$DOMAIN/platform/templates/watchy-platform.yaml"

aws cloudformation create-stack \
    --profile "$AWS_PROFILE" \
    --stack-name "$STACK_NAME" \
    --template-url "$template_url" \
    --parameters \
        ParameterKey=WatchyLicenseKey,ParameterValue="$LICENSE_KEY" \
        ParameterKey=CustomerID,ParameterValue="$CUSTOMER_ID" \
        ParameterKey=NotificationEmail,ParameterValue="$NOTIFICATION_EMAIL" \
        ParameterKey=EnableSlackMonitoring,ParameterValue="$ENABLE_SLACK" \
        ParameterKey=EnableGitHubMonitoring,ParameterValue="$ENABLE_GITHUB" \
        ParameterKey=EnableZoomMonitoring,ParameterValue="$ENABLE_ZOOM" \
    --capabilities CAPABILITY_NAMED_IAM \
    --tags \
        Key=Platform,Value=WatchyCloud \
        Key=CustomerID,Value="$CUSTOMER_ID" \
        Key=Version,Value="$platform_version"

echo ""
echo "✅ CloudFormation stack deployment initiated!"
echo ""
echo "🔍 Monitor deployment progress:"
echo "aws cloudformation describe-stack-events --stack-name $STACK_NAME"
echo ""
echo "📊 Check deployment status:"
echo "aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus'"
echo ""
echo "🌐 AWS Console link:"
echo "https://console.aws.amazon.com/cloudformation/home#/stacks/stackinfo?stackId=$STACK_NAME"
echo ""
echo "📧 Email confirmation:"
echo "Check your email ($NOTIFICATION_EMAIL) to confirm SNS subscription for alerts"
echo ""
echo "⏱️  Deployment typically takes 5-10 minutes to complete"

# Wait for user confirmation to check status
echo ""
read -p "Would you like to wait and check the deployment status? (y/N): " CHECK_STATUS

if [ "${CHECK_STATUS,,}" = "y" ]; then
    echo ""
    echo "⏳ Waiting for stack deployment..."
    
    # Wait for stack to complete (with timeout)
    timeout=600  # 10 minutes
    elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        status=$(aws cloudformation describe-stacks \
            --profile "$AWS_PROFILE" \
            --stack-name "$STACK_NAME" \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null || echo "UNKNOWN")
        
        case $status in
            "CREATE_COMPLETE")
                echo ""
                echo "🎉 Stack deployment completed successfully!"
                break
                ;;
            "CREATE_FAILED"|"ROLLBACK_COMPLETE"|"ROLLBACK_FAILED")
                echo ""
                echo "❌ Stack deployment failed with status: $status"
                echo ""
                echo "📋 Check stack events for details:"
                echo "aws cloudformation describe-stack-events --stack-name $STACK_NAME"
                exit 1
                ;;
            "CREATE_IN_PROGRESS")
                echo -n "."
                ;;
            *)
                echo ""
                echo "📊 Current status: $status"
                ;;
        esac
        
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo ""
        echo "⏰ Timeout waiting for deployment. Check AWS Console for current status."
    fi
fi

echo ""
echo "🎉 Watchy Cloud Onboarding Complete!"
echo "===================================="
echo ""
echo "📊 Your monitoring platform is being deployed with:"
echo "  - Platform version: $platform_version"
echo "  - Stack name: $STACK_NAME"
echo "  - Customer ID: $CUSTOMER_ID"
echo "  - Slack monitoring: $ENABLE_SLACK"
echo "  - GitHub monitoring: $ENABLE_GITHUB"  
echo "  - Zoom monitoring: $ENABLE_ZOOM"
echo ""
echo "🔗 Useful links:"
echo "  - Platform: https://$DOMAIN/platform/"
echo "  - Documentation: https://$DOMAIN/platform/docs/"
echo "  - Support: support@watchy.cloud"
echo ""
echo "📧 Remember to confirm your SNS subscription via email!"
echo ""
echo "Thank you for choosing Watchy Cloud! 🚀"
