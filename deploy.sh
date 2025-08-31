#!/bin/bash

# Quick deployment script for Watchy Platform - DEPRECATED
# All deployments now happen via GitHub Actions

echo "⚠️  DEPRECATED: Local deployment is disabled for security and consistency"
echo ""
echo "🚀 All deployments now happen automatically via GitHub Actions!"
echo ""
echo "📋 To deploy your changes:"
echo "  1. Commit your changes:"
echo "     git add ."
echo "     git commit -m 'Your commit message'"
echo ""
echo "  2. Push to trigger automatic deployment:"
echo "     git push origin main"
echo ""
echo "  3. OR trigger manual deployment:"
echo "     • Go to GitHub → Actions → 'Complete CI/CD Pipeline'"
echo "     • Click 'Run workflow'"
echo "     • Choose environment and version"
echo ""
echo "� Monitor deployment:"
echo "   https://github.com/cloudbennett/watchy.cloud/actions"
echo ""
echo "✨ Benefits of GitHub Actions deployment:"
echo "  • Automatic validation and testing"
echo "  • Consistent deployment environment"
echo "  • Complete audit trail"
echo "  • Security scanning"
echo "  • Rollback capabilities"

exit 1
