#!/bin/bash

# Watchy Cloud Customer Package Generator
# Creates a customer-ready package with templates and documentation

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CUSTOMER_PACKAGE_DIR="${SCRIPT_DIR}/customer-package"

echo "🚀 Creating Watchy Cloud Customer Package..."

# Create customer package directory
rm -rf "${CUSTOMER_PACKAGE_DIR}"
mkdir -p "${CUSTOMER_PACKAGE_DIR}"

# Copy customer-facing files only
cp "${SCRIPT_DIR}/customer-templates/README.md" "${CUSTOMER_PACKAGE_DIR}/"
cp "${SCRIPT_DIR}/customer-templates/get-template-urls.sh" "${CUSTOMER_PACKAGE_DIR}/"

# Create a simple index file
cat > "${CUSTOMER_PACKAGE_DIR}/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Watchy Cloud - Customer Templates</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
        pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .template-url { word-break: break-all; }
    </style>
</head>
<body>
    <h1>🚀 Watchy Cloud Monitoring Templates</h1>
    
    <h2>Quick Start</h2>
    <p>Deploy monitoring templates directly from our hosted S3 URLs - no downloads required!</p>
    
    <h2>Template URL</h2>
    <ul>
        <li><strong>Watchy Platform (includes Slack monitoring):</strong><br>
            <code class="template-url">https://s3.amazonaws.com/watchy-resources-prod/platform/watchy-platform.yaml</code></li>
    </ul>
    
    <p><em>Additional SaaS integrations (GitHub, Zoom) will be available in future releases.</em></p>
    
    <h2>Example Deployment</h2>
    <pre><code>aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/customer-templates/templates/watchy-slack-monitoring.yaml \
  --stack-name my-slack-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    MonitoringSchedule="rate(5 minutes)"</code></pre>
    
    <p>See <code>README.md</code> for complete documentation.</p>
    
    <hr>
    <p><strong>Support:</strong> <a href="mailto:contact@watchy.cloud">contact@watchy.cloud</a></p>
</body>
</html>
EOF

# Make scripts executable
chmod +x "${CUSTOMER_PACKAGE_DIR}/get-template-urls.sh"

echo "✅ Customer package created at: ${CUSTOMER_PACKAGE_DIR}"
echo
echo "📦 Package contents:"
ls -la "${CUSTOMER_PACKAGE_DIR}"
echo
echo "📧 You can now distribute this package to customers via:"
echo "   • Email attachment (zip the customer-package folder)"
echo "   • Internal file sharing"
echo "   • Customer portal"
echo
echo "🌐 Templates are hosted at S3 URLs - customers don't need source code access"
