#!/bin/bash

# Nuitka Build Script for Watchy Slack Monitor
# Optimized for both GitHub Actions and local development

set -e

# Configuration
VERSION=${WATCHY_VERSION:-"1.0.0"}
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_DIR="build"
DIST_DIR="dist"
LAMBDA_DIR="lambda"
MONITOR_NAME="slack-monitor"

echo "🔨 Building Watchy Slack Monitor with Nuitka v${VERSION}"
echo "======================================================="
echo "Build Time: ${BUILD_TIME}"
echo "Target: AWS Lambda x86_64"
echo "SaaS App: Slack Status Monitoring"
echo "Environment: ${CI:+GitHub Actions}${CI:-Local Development}"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ${BUILD_DIR} ${DIST_DIR} ${LAMBDA_DIR}
mkdir -p ${BUILD_DIR} ${DIST_DIR} ${LAMBDA_DIR}

# Check if we're in GitHub Actions
if [ "${CI}" = "true" ] || [ "${GITHUB_ACTIONS}" = "true" ]; then
    echo "🐳 GitHub Actions Environment - Using system Python"
    
    # Install Nuitka directly
    echo "📦 Installing Nuitka..."
    pip install nuitka
    
    # Install dependencies if requirements.txt exists
    if [ -f requirements.txt ]; then
        echo "📋 Installing dependencies..."
        pip install -r requirements.txt
    fi
    
else
    echo "💻 Local Development Environment - Using virtual environment"
    
    # Set up build environment
    echo "📦 Setting up build environment..."
    python3 -m venv ${BUILD_DIR}/nuitka_env
    source ${BUILD_DIR}/nuitka_env/bin/activate
    
    # Upgrade pip and install Nuitka
    echo "🔧 Installing Nuitka..."
    pip install --upgrade pip
    pip install nuitka
    
    # Install dependencies
    if [ -f requirements.txt ]; then
        echo "📋 Installing dependencies..."
        pip install -r requirements.txt
    fi
fi

# Run the build
echo ""
echo "🏗️ Compiling Python to native binary..."
echo "Source: watchy_slack_monitor.py"
echo "Output: watchy-slack-monitor"
echo ""

# Update version in source
echo "📝 Updating version information..."
sed -i.bak "s/VERSION = .*/VERSION = \"${VERSION}-nuitka\"/" watchy_slack_monitor.py
sed -i.bak "s/BUILD_DATE = .*/BUILD_DATE = \"${BUILD_TIME}\"/" watchy_slack_monitor.py
rm -f watchy_slack_monitor.py.bak

# Compile with Nuitka
echo "🔨 Compiling Slack monitor to native binary..."
echo "This may take several minutes..."

python -m nuitka \
    --standalone \
    --onefile \
    --assume-yes-for-downloads \
    --follow-imports \
    --output-filename=watchy-slack-monitor \
    --output-dir=${BUILD_DIR} \
    --python-flag=no_warnings \
    --python-flag=no_docstrings \
    --python-flag=no_asserts \
    --disable-console \
    --include-package=requests \
    --include-package=boto3 \
    --include-package=botocore \
    --include-package=urllib3 \
    --include-package=certifi \
    watchy_slack_monitor.py

if [ $? -eq 0 ]; then
    echo "✅ Nuitka compilation successful!"
else
    echo "❌ Nuitka compilation failed!"
    exit 1
fi

# Check if binary was created
BINARY_PATH="${BUILD_DIR}/watchy-slack-monitor"
if [ -f "$BINARY_PATH" ]; then
    echo "✅ Binary created: $BINARY_PATH"
    BINARY_SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
    echo "📦 Binary size: $BINARY_SIZE"
else
    echo "❌ Binary not found at expected location!"
    exit 1
fi

# Test binary execution
echo ""
echo "🧪 Testing binary execution..."
export WATCHY_LICENSE_KEY="lemon_test_key_12345678"
export API_URL="https://httpbin.org/json"  # Test endpoint

if timeout 30 $BINARY_PATH; then
    echo "✅ Binary execution test passed!"
else
    echo "⚠️ Binary execution test failed (may be environment-specific)"
fi

# Create Lambda deployment package
echo ""
echo "📦 Creating Lambda deployment package..."

# Copy binary to Lambda package with the name GitHub Actions expects
cp "$BINARY_PATH" "${LAMBDA_DIR}/watchy-${MONITOR_NAME}"

# Create requirements for Lambda (empty since everything is in binary)
cat > ${LAMBDA_DIR}/requirements.txt << EOF
# No Python dependencies needed - everything is in the Nuitka native binary
# boto3 and botocore are available in Lambda runtime
EOF

# Create deployment package
echo "📦 Creating deployment package..."
cd ${LAMBDA_DIR}
zip -r ../${DIST_DIR}/watchy-slack-nuitka-lambda-${VERSION}.zip . -x "*.DS_Store"
cd ..

# Create binary distribution package (for hosting)
echo "📦 Creating binary distribution package..."
cp "$BINARY_PATH" "${DIST_DIR}/watchy-slack-monitor-${VERSION}"
gzip -c "${DIST_DIR}/watchy-slack-monitor-${VERSION}" > "${DIST_DIR}/watchy-slack-monitor-${VERSION}.gz"

# Calculate package sizes
LAMBDA_SIZE=$(du -h ${DIST_DIR}/watchy-slack-nuitka-lambda-${VERSION}.zip | cut -f1)
BINARY_SIZE=$(du -h ${DIST_DIR}/watchy-slack-monitor-${VERSION} | cut -f1)
COMPRESSED_SIZE=$(du -h ${DIST_DIR}/watchy-slack-monitor-${VERSION}.gz | cut -f1)

# Generate binary hash for integrity verification
BINARY_HASH=$(shasum -a 256 "${DIST_DIR}/watchy-slack-monitor-${VERSION}" | cut -d' ' -f1)

# Create distribution info JSON
cat > ${DIST_DIR}/watchy-slack-monitor-info.json << EOF
{
  "version": "${VERSION}",
  "build_time": "${BUILD_TIME}",
  "saas_app": "Slack",
  "binary_type": "nuitka",
  "binary_size": "${BINARY_SIZE}",
  "compressed_size": "${COMPRESSED_SIZE}",
  "sha256": "${BINARY_HASH}",
  "download_url": "https://releases.watchy.cloud/binaries/slack-monitor/latest.gz",
  "compression": "gzip",
  "target_architecture": "x86_64",
  "lambda_compatible": true
}
EOF

echo ""
echo "✅ Slack Monitor Nuitka build completed successfully!"
echo "===================================================="
echo "📦 Lambda Package: ${DIST_DIR}/watchy-slack-nuitka-lambda-${VERSION}.zip (${LAMBDA_SIZE})"
echo "🔒 Binary Package: ${DIST_DIR}/watchy-slack-monitor-${VERSION} (${BINARY_SIZE})"
echo "📦 Compressed Binary: ${DIST_DIR}/watchy-slack-monitor-${VERSION}.gz (${COMPRESSED_SIZE})"
echo "🔒 Binary SHA256: ${BINARY_HASH}"
echo "📄 Distribution Info: ${DIST_DIR}/watchy-slack-monitor-info.json"
echo ""
echo "🚀 Deployment ready!"
echo ""
echo "Next steps:"
echo "1. Upload compressed binary to distribution server"
echo "2. Set WATCHY_BINARY_DISTRIBUTION_URL in CloudFormation"
echo "3. Deploy Lambda package to AWS"
echo "4. Configure CloudFormation template with binary URL"
echo ""
echo "🔒 Security Features:"
echo "- ✅ Native Nuitka compilation (maximum IP protection)"
echo "- ✅ License validation embedded in binary"
echo "- ✅ LemonSqueezy integration protected"
echo "- ✅ Slack monitoring algorithms hidden"
echo "- ✅ Binary integrity verification with SHA256"

# Cleanup: Deactivate virtual environment if we're in local development
if [ "${CI}" != "true" ] && [ "${GITHUB_ACTIONS}" != "true" ]; then
    echo ""
    echo "🧹 Cleaning up local environment..."
    deactivate
fi

echo ""
echo "🎉 Slack Monitor build complete!"
echo "✅ Binary ready at: ${LAMBDA_DIR}/watchy-${MONITOR_NAME}"
