#!/bin/bash

# Quick deployment script for Watchy Platform
# Version: 1.0.0

set -e

echo "🚀 Watchy Cloud Platform - Quick Deploy"
echo "======================================="
echo ""

# Check if deployment script exists
DEPLOY_SCRIPT="platform/deploy/deploy-to-watchy-cloud.sh"

if [ ! -f "$DEPLOY_SCRIPT" ]; then
    echo "❌ Deployment script not found: $DEPLOY_SCRIPT"
    echo "Please run this script from the monitoring-templates root directory."
    exit 1
fi

# Make sure deployment script is executable
chmod +x "$DEPLOY_SCRIPT"

# Set version if not already set
export WATCHY_VERSION="${WATCHY_VERSION:-1.0.0}"

echo "📋 Using version: $WATCHY_VERSION"
echo "🎯 Target: watchy.cloud bucket"
echo "⚠️  Preserving existing index.html"
echo ""

# Run the deployment
"$DEPLOY_SCRIPT"

echo ""
echo "✨ Quick deployment complete!"
echo ""
echo "🔗 Test your platform:"
echo "curl https://watchy.cloud/platform/api/version.json"
