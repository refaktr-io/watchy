#!/bin/bash

# Complete Watchy Platform Deployment Script
# Deploys to existing watchy.cloud S3 bucket without overwriting main index.html

set -e

# Configuration
BUCKET_NAME="watchy.cloud"                    # Web hosting bucket (via CloudFront)
TEMPLATES_BUCKET="watchy-resources"           # CloudFormation templates bucket (direct S3)
DOMAIN_NAME="watchy.cloud"
VERSION=${WATCHY_VERSION:-"1.0.0"}
REGION=${AWS_REGION:-"us-east-1"}
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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

echo "🚀 Watchy Platform Deployment to watchy.cloud"
echo "============================================="
echo "Version: $VERSION"
echo "Build Time: $BUILD_TIME"
echo "Bucket: $BUCKET_NAME"
echo "Templates Bucket: $TEMPLATES_BUCKET"
echo "Domain: $DOMAIN_NAME"
echo "Region: $REGION"
echo "Auth Method: $AWS_PROFILE_NAME"
echo ""
echo "⚠️  IMPORTANT: Preserving existing index.html"
echo "📁 Deploying to /platform/ subfolder only"
echo ""

# Validate environment
echo "🔍 Validating environment..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity $AWS_CLI_ARGS &> /dev/null; then
    echo "❌ AWS credentials not configured."
    if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
        echo "   Please configure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets in GitHub."
    else
        echo "   Please run 'aws configure --profile watchy'."
    fi
    exit 1
fi

# Check bucket exists
if ! aws s3 ls "s3://$BUCKET_NAME" $AWS_CLI_ARGS &> /dev/null; then
    echo "❌ Bucket $BUCKET_NAME not accessible or doesn't exist."
    exit 1
fi

# Check templates bucket exists
if ! aws s3 ls "s3://$TEMPLATES_BUCKET" $AWS_CLI_ARGS &> /dev/null; then
    echo "❌ Templates bucket $TEMPLATES_BUCKET not accessible or doesn't exist."
    exit 1
fi

echo "✅ Environment validation passed"

# Cleanup and prepare
echo ""
echo "📁 Preparing build directory..."
rm -rf dist/
mkdir -p dist/platform/{templates,binaries,docs,api}

# Process CloudFormation templates
echo "📋 Processing CloudFormation templates..."
cp platform/watchy-platform.yaml dist/platform/templates/
cp platform/saas-apps/watchy-saas-template.yaml dist/platform/templates/
cp platform/saas-apps/watchy-slack-monitoring.yaml dist/platform/templates/
cp platform/saas-apps/watchy-github-monitoring.yaml dist/platform/templates/
cp platform/saas-apps/watchy-zoom-monitoring.yaml dist/platform/templates/

# Update template URLs to use subfolder structure
echo "🔗 Updating template URLs for platform subfolder..."
for template in dist/platform/templates/*.yaml; do
    # Update nested template URLs to use templates bucket
    sed -i.bak "s|https://watchy-resources.s3.us-west-2.amazonaws.com|https://$TEMPLATES_BUCKET.s3.amazonaws.com/platform/templates|g" "$template"
    # Update binary distribution URLs to use web hosting bucket
    sed -i.bak "s|https://releases.watchy.cloud/binaries|https://$DOMAIN_NAME/platform/binaries|g" "$template"
    rm -f "$template.bak"
done

# Build Nuitka binaries
echo ""
echo "🔨 Building Nuitka binaries..."

# Clean previous builds for fresh compilation
echo "🧹 Cleaning previous builds..."
rm -rf platform/binaries/*/build/
rm -rf dist/platform/binaries/*

# Check if Nuitka is available, install if needed
if ! command -v nuitka3 &> /dev/null && ! python3 -c "import nuitka" &> /dev/null 2>&1; then
    echo "📦 Installing Nuitka..."
    
    # Try different installation methods to handle externally-managed-environment
    if command -v pip3 &> /dev/null; then
        # First try regular pip install
        if pip3 install nuitka &> /dev/null; then
            echo "✅ Nuitka installed with pip3"
        # If that fails due to externally-managed-environment, try with --break-system-packages
        elif pip3 install nuitka --break-system-packages &> /dev/null; then
            echo "✅ Nuitka installed with --break-system-packages"
        # If pip3 fails, try creating a virtual environment
        else
            echo "📦 Creating virtual environment for Nuitka..."
            python3 -m venv .nuitka_env
            source .nuitka_env/bin/activate
            pip install nuitka
            echo "✅ Nuitka installed in virtual environment"
            # Note: We'll need to activate this env for each build
        fi
    elif command -v pip &> /dev/null; then
        # Try with regular pip
        if pip install nuitka &> /dev/null; then
            echo "✅ Nuitka installed with pip"
        elif pip install nuitka --break-system-packages &> /dev/null; then
            echo "✅ Nuitka installed with --break-system-packages"
        else
            echo "❌ Failed to install Nuitka with pip"
            exit 1
        fi
    else
        echo "❌ pip not found. Please install pip or Nuitka manually."
        echo "You can install Nuitka with: pip3 install nuitka --break-system-packages"
        exit 1
    fi
    
    # Verify installation
    if [ -f ".nuitka_env/bin/activate" ]; then
        source .nuitka_env/bin/activate
        if ! python3 -c "import nuitka" &> /dev/null 2>&1; then
            echo "❌ Nuitka installation failed in virtual environment"
            exit 1
        fi
        deactivate
    else
        if ! python3 -c "import nuitka" &> /dev/null 2>&1; then
            echo "❌ Nuitka installation failed"
            exit 1
        fi
    fi
    echo "✅ Nuitka installed successfully"
else
    echo "✅ Nuitka already available"
fi

echo "  Building Slack monitor..."
cd platform/binaries/slack-monitor/
chmod +x build.sh

# Activate virtual environment if it exists
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    source ../../../.nuitka_env/bin/activate
fi

WATCHY_VERSION=$VERSION ./build.sh

# Deactivate virtual environment if it was activated
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    deactivate
fi

if [ -f "build/watchy-slack-monitor" ]; then
    cp build/watchy-slack-monitor ../../../dist/platform/binaries/
    echo "  ✅ Slack monitor built successfully"
else
    echo "  ❌ Slack monitor build failed"
    exit 1
fi
cd ../../../

echo "  Building GitHub monitor..."
cd platform/binaries/github-monitor/
chmod +x build.sh

# Activate virtual environment if it exists
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    source ../../../.nuitka_env/bin/activate
fi

WATCHY_VERSION=$VERSION ./build.sh

# Deactivate virtual environment if it was activated
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    deactivate
fi

if [ -f "build/watchy-github-monitor" ]; then
    cp build/watchy-github-monitor ../../../dist/platform/binaries/
    echo "  ✅ GitHub monitor built successfully"
else
    echo "  ❌ GitHub monitor build failed"
    exit 1
fi
cd ../../../

echo "  Building Zoom monitor..."
cd platform/binaries/zoom-monitor/
chmod +x build.sh

# Activate virtual environment if it exists
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    source ../../../.nuitka_env/bin/activate
fi

WATCHY_VERSION=$VERSION ./build.sh

# Deactivate virtual environment if it was activated
if [ -f "../../../.nuitka_env/bin/activate" ]; then
    deactivate
fi

if [ -f "build/watchy-zoom-monitor" ]; then
    cp build/watchy-zoom-monitor ../../../dist/platform/binaries/
    echo "  ✅ Zoom monitor built successfully"
else
    echo "  ❌ Zoom monitor build failed"
    exit 1
fi
cd ../../../

# Create binary manifests with checksums
echo ""
echo "📊 Creating binary manifests..."
for binary in dist/platform/binaries/watchy-*-monitor; do
    if [ -f "$binary" ]; then
        binary_name=$(basename "$binary")
        saas_name=$(echo "$binary_name" | sed 's/watchy-\(.*\)-monitor/\1/')
        
        # Calculate checksums and file info
        if command -v sha256sum &> /dev/null; then
            sha256_hash=$(sha256sum "$binary" | cut -d' ' -f1)
        else
            sha256_hash=$(shasum -a 256 "$binary" | cut -d' ' -f1)
        fi
        
        if command -v stat &> /dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                file_size=$(stat -f%z "$binary")
            else
                file_size=$(stat -c%s "$binary")
            fi
        else
            file_size=$(wc -c < "$binary")
        fi
        
        # Create manifest
        cat > "dist/platform/binaries/${binary_name}.json" << EOF
{
    "name": "$binary_name",
    "saas_app": "$saas_name",
    "version": "$VERSION",
    "architecture": "x86_64",
    "build_date": "$BUILD_TIME",
    "binary_type": "nuitka",
    "file_size": $file_size,
    "sha256": "$sha256_hash",
    "download_url": "https://$DOMAIN_NAME/platform/binaries/$binary_name",
    "manifest_url": "https://$DOMAIN_NAME/platform/binaries/${binary_name}.json",
    "lambda_compatible": true
}
EOF
        echo "  ✅ Created manifest for $binary_name"
    fi
done

# Create API endpoints
echo ""
echo "🔌 Creating platform API endpoints..."

# Create latest binary version endpoints
for saas in slack github zoom; do
    cat > "dist/platform/api/${saas}-monitor-latest.json" << EOF
{
    "name": "watchy-${saas}-monitor",
    "saas_app": "$saas",
    "version": "$VERSION",
    "download_url": "https://$DOMAIN_NAME/platform/binaries/watchy-${saas}-monitor",
    "sha256_url": "https://$DOMAIN_NAME/platform/binaries/watchy-${saas}-monitor.json",
    "latest": true,
    "release_date": "$BUILD_TIME",
    "architecture": "x86_64",
    "binary_type": "nuitka"
}
EOF
    echo "  ✅ Created API endpoint for $saas monitor"
done

# Create platform version manifest
cat > dist/platform/api/version.json << EOF
{
    "platform": "Watchy Cloud Multi-SaaS Monitoring",
    "version": "$VERSION",
    "release_date": "$BUILD_TIME",
    "base_url": "https://$DOMAIN_NAME/platform",
    "components": {
        "templates": {
            "parent": "https://$DOMAIN_NAME/platform/templates/watchy-platform.yaml",
            "saas_template": "https://$DOMAIN_NAME/platform/templates/watchy-saas-template.yaml",
            "saas_apps": {
                "slack": "https://$DOMAIN_NAME/platform/templates/watchy-slack-monitoring.yaml",
                "github": "https://$DOMAIN_NAME/platform/templates/watchy-github-monitoring.yaml",
                "zoom": "https://$DOMAIN_NAME/platform/templates/watchy-zoom-monitoring.yaml"
            }
        },
        "binaries": {
            "slack": "https://$DOMAIN_NAME/platform/binaries/watchy-slack-monitor",
            "github": "https://$DOMAIN_NAME/platform/binaries/watchy-github-monitor",
            "zoom": "https://$DOMAIN_NAME/platform/binaries/watchy-zoom-monitor"
        },
        "api": {
            "slack_latest": "https://$DOMAIN_NAME/platform/api/slack-monitor-latest.json",
            "github_latest": "https://$DOMAIN_NAME/platform/api/github-monitor-latest.json",
            "zoom_latest": "https://$DOMAIN_NAME/platform/api/zoom-monitor-latest.json",
            "version": "https://$DOMAIN_NAME/platform/api/version.json"
        }
    },
    "deployment": {
        "quick_deploy_url": "https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-platform&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-platform.yaml",
        "documentation": "https://$DOMAIN_NAME/platform/docs/",
        "platform_overview": "https://$DOMAIN_NAME/platform/"
    },
    "build_info": {
        "build_time": "$BUILD_TIME",
        "build_system": "nuitka",
        "source_protection": "native_binary",
        "license_system": "lemonsqueezy"
    }
}
EOF

echo "  ✅ Created platform version manifest"

# Copy documentation
echo ""
echo "📚 Preparing documentation..."
cp platform/README.md dist/platform/docs/README.md
if [ -f "LICENSE" ]; then
    cp LICENSE dist/platform/docs/LICENSE
fi

# Create platform overview page (this won't overwrite main index.html)
echo ""
echo "🌐 Creating platform overview page..."
cat > dist/platform/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Watchy Cloud Platform - SaaS Monitoring</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        .header {
            text-align: center;
            margin-bottom: 3rem;
        }
        
        .logo {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        
        h1 {
            color: white;
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        
        .tagline {
            color: rgba(255,255,255,0.9);
            font-size: 1.3rem;
            margin-bottom: 2rem;
        }
        
        .nav {
            display: flex;
            justify-content: center;
            gap: 1rem;
            margin-bottom: 3rem;
            flex-wrap: wrap;
        }
        
        .nav-link {
            background: rgba(255,255,255,0.1);
            color: white;
            padding: 0.75rem 1.5rem;
            text-decoration: none;
            border-radius: 10px;
            backdrop-filter: blur(10px);
            transition: all 0.3s ease;
        }
        
        .nav-link:hover {
            background: rgba(255,255,255,0.2);
            transform: translateY(-2px);
        }
        
        .deploy-section {
            background: white;
            border-radius: 20px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        
        .deploy-button {
            display: inline-block;
            background: #FF9500;
            color: white;
            padding: 1rem 2rem;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 1.1rem;
            transition: all 0.3s ease;
            margin: 0.5rem;
        }
        
        .deploy-button:hover {
            background: #e68900;
            transform: translateY(-2px);
        }
        
        .templates-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }
        
        .template-card {
            background: white;
            padding: 2rem;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .template-card h3 {
            color: #667eea;
            margin-bottom: 1rem;
        }
        
        .template-links {
            display: flex;
            gap: 1rem;
            margin-top: 1rem;
            flex-wrap: wrap;
        }
        
        .template-link {
            background: #f0f0f0;
            color: #333;
            padding: 0.5rem 1rem;
            text-decoration: none;
            border-radius: 5px;
            font-size: 0.9rem;
            transition: background 0.3s ease;
        }
        
        .template-link:hover {
            background: #e0e0e0;
        }
        
        .code-block {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 1rem;
            margin: 1rem 0;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.9rem;
            overflow-x: auto;
        }
        
        .version-info {
            background: rgba(255,255,255,0.1);
            color: white;
            padding: 1rem;
            border-radius: 10px;
            margin-bottom: 2rem;
            backdrop-filter: blur(10px);
        }
        
        @media (max-width: 768px) {
            .container { padding: 1rem; }
            h1 { font-size: 2rem; }
            .logo { font-size: 3rem; }
            .nav { flex-direction: column; align-items: center; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">⏱️</div>
            <h1>Watchy Cloud Platform</h1>
            <p class="tagline">Enterprise SaaS Monitoring for AWS</p>
        </div>
        
        <div class="nav">
            <a href="/" class="nav-link">🏠 Home</a>
            <a href="/platform/" class="nav-link">📊 Platform</a>
            <a href="/platform/docs/" class="nav-link">📚 Docs</a>
            <a href="/platform/templates/" class="nav-link">📋 Templates</a>
            <a href="/platform/api/version.json" class="nav-link">🔌 API</a>
        </div>
        
        <div class="version-info">
            <h3>🚀 Platform Status</h3>
            <p id="version-info">Loading platform information...</p>
        </div>
        
        <div class="deploy-section">
            <h2>🚀 Quick Deploy Complete Platform</h2>
            <p>Deploy the entire Watchy Cloud monitoring platform with Slack, GitHub, and Zoom monitoring:</p>
            
            <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-platform&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-platform.yaml" 
               class="deploy-button" target="_blank">
                📊 Deploy Complete Platform
            </a>
            
            <h3>Manual Deployment</h3>
            <div class="code-block">
aws cloudformation create-stack \
  --stack-name watchy-platform \
  --template-url https://$TEMPLATES_BUCKET.s3.amazonaws.com/platform/templates/watchy-platform.yaml \
  --parameters \
    ParameterKey=WatchyLicenseKey,ParameterValue="your-license-key" \
    ParameterKey=NotificationEmail,ParameterValue="alerts@yourcompany.com" \
    ParameterKey=EnableSlackMonitoring,ParameterValue=true \
    ParameterKey=EnableGitHubMonitoring,ParameterValue=true \
    ParameterKey=EnableZoomMonitoring,ParameterValue=true \
  --capabilities CAPABILITY_NAMED_IAM
            </div>
        </div>
        
        <div class="deploy-section">
            <h2>📋 Individual SaaS Monitoring Templates</h2>
            <p>Deploy specific SaaS monitoring independently:</p>
            
            <div class="templates-grid">
                <div class="template-card">
                    <h3>💬 Slack Monitoring</h3>
                    <p>Monitor Slack API, messaging, file sharing, calls, and all service components.</p>
                    <div class="template-links">
                        <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-slack&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-slack-monitoring.yaml" 
                           class="deploy-button">Deploy</a>
                        <a href="/platform/templates/watchy-slack-monitoring.yaml" class="template-link">View Template</a>
                    </div>
                </div>
                
                <div class="template-card">
                    <h3>🐙 GitHub Monitoring</h3>
                    <p>Monitor GitHub API, Git operations, Actions, Pages, and repository services.</p>
                    <div class="template-links">
                        <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-github&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-github-monitoring.yaml" 
                           class="deploy-button">Deploy</a>
                        <a href="/platform/templates/watchy-github-monitoring.yaml" class="template-link">View Template</a>
                    </div>
                </div>
                
                <div class="template-card">
                    <h3>🎥 Zoom Monitoring</h3>
                    <p>Monitor Zoom meetings, webinars, recordings, chat, phone, and dashboard services.</p>
                    <div class="template-links">
                        <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-zoom&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-zoom-monitoring.yaml" 
                           class="deploy-button">Deploy</a>
                        <a href="/platform/templates/watchy-zoom-monitoring.yaml" class="template-link">View Template</a>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="deploy-section">
            <h2>🔗 Platform Resources</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
                <a href="/platform/api/version.json" class="template-link">📊 Platform API</a>
                <a href="/platform/docs/README.md" class="template-link">📚 Documentation</a>
                <a href="/platform/binaries/" class="template-link">💾 Binaries</a>
                <a href="/platform/templates/" class="template-link">📋 All Templates</a>
            </div>
        </div>
    </div>
    
    <script>
        // Load version information
        fetch('/platform/api/version.json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('version-info').innerHTML = `
                    Platform Version: <strong>${data.version}</strong><br>
                    Release Date: <strong>${new Date(data.release_date).toLocaleDateString()}</strong><br>
                    Build System: <strong>${data.build_info?.build_system || 'Nuitka'}</strong>
                `;
            })
            .catch(error => {
                document.getElementById('version-info').innerHTML = 'Platform information unavailable';
            });
    </script>
</body>
</html>
EOF

# Create templates index page
cat > dist/platform/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Watchy Cloud - CloudFormation Templates</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 2rem; 
            line-height: 1.6;
            background: #f8f9fa;
        }
        .container { max-width: 1000px; margin: 0 auto; }
        .template { 
            background: white;
            margin: 1rem 0; 
            padding: 2rem; 
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .deploy-btn { 
            background: #ff9500; 
            color: white; 
            padding: 0.75rem 1.5rem; 
            text-decoration: none; 
            border-radius: 8px; 
            display: inline-block;
            margin-right: 1rem;
            font-weight: 500;
        }
        .deploy-btn:hover { background: #e68900; }
        .view-btn {
            background: #007bff;
            color: white;
            padding: 0.75rem 1.5rem;
            text-decoration: none;
            border-radius: 8px;
            display: inline-block;
            font-weight: 500;
        }
        .view-btn:hover { background: #0056b3; }
        h1 { color: #333; }
        h2 { color: #667eea; margin-bottom: 1rem; }
        .nav { margin-bottom: 2rem; }
        .nav a { 
            background: #667eea;
            color: white;
            padding: 0.5rem 1rem;
            text-decoration: none;
            border-radius: 5px;
            margin-right: 1rem;
        }
        .nav a:hover { background: #5a6fd8; }
    </style>
</head>
<body>
    <div class="container">
        <div class="nav">
            <a href="/">🏠 Home</a>
            <a href="/platform/">📊 Platform</a>
            <a href="/platform/docs/">📚 Docs</a>
            <a href="/platform/api/version.json">🔌 API</a>
        </div>
        
        <h1>Watchy Cloud - CloudFormation Templates</h1>
        
        <div class="template">
            <h2>🏗️ Watchy Platform (Parent Stack)</h2>
            <p>Complete multi-SaaS monitoring platform with Slack, GitHub, and Zoom support. Includes shared resources, license management, and nested stack deployment.</p>
            <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-platform&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-platform.yaml" 
               class="deploy-btn">Deploy Platform</a>
            <a href="watchy-platform.yaml" class="view-btn">View Template</a>
        </div>
        
        <div class="template">
            <h2>💬 Slack Monitoring</h2>
            <p>Dedicated Slack service monitoring with API status, messaging, file sharing, calls, and all Slack service components.</p>
            <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-slack&templateURL=https://$TEMPLATES_BUCKET.s3.amazonaws.com/platform/templates/watchy-slack-monitoring.yaml" 
               class="deploy-btn">Deploy Slack Monitor</a>
            <a href="watchy-slack-monitoring.yaml" class="view-btn">View Template</a>
        </div>
        
        <div class="template">
            <h2>🐙 GitHub Monitoring</h2>
            <p>GitHub API and service monitoring including Git operations, Actions, Pages, and repository services.</p>
            <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-github&templateURL=https://$TEMPLATES_BUCKET.s3.amazonaws.com/platform/templates/watchy-github-monitoring.yaml" 
               class="deploy-btn">Deploy GitHub Monitor</a>
            <a href="watchy-github-monitoring.yaml" class="view-btn">View Template</a>
        </div>
        
        <div class="template">
            <h2>🎥 Zoom Monitoring</h2>
            <p>Zoom platform monitoring including meetings, webinars, recordings, chat, phone, and dashboard services.</p>
            <a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-zoom&templateURL=https://$TEMPLATES_BUCKET.s3.amazonaws.com/platform/templates/watchy-zoom-monitoring.yaml" 
               class="deploy-btn">Deploy Zoom Monitor</a>
            <a href="watchy-zoom-monitoring.yaml" class="view-btn">View Template</a>
        </div>
        
        <div class="template">
            <h2>📋 SaaS Template (Base)</h2>
            <p>Standardized base template for creating new SaaS monitoring applications. Use this as a starting point for adding new SaaS apps.</p>
            <a href="watchy-saas-template.yaml" class="view-btn">View Template</a>
        </div>
    </div>
</body>
</html>
EOF

# Sync to S3
echo ""
echo "📤 Syncing platform to S3 (preserving main index.html)..."

# Sync platform templates to dedicated templates bucket
echo "  📋 Syncing CloudFormation templates to $TEMPLATES_BUCKET/platform/templates/..."
aws s3 sync dist/platform/templates/ s3://$TEMPLATES_BUCKET/platform/templates/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=300" \
    --content-type "text/yaml" \
    --exclude "*.html"

# Sync HTML files in templates with correct content type to templates bucket
aws s3 sync dist/platform/templates/ s3://$TEMPLATES_BUCKET/platform/templates/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=300" \
    --content-type "text/html" \
    --exclude "*" \
    --include "*.html"

# Sync platform binaries
echo "  💾 Syncing Nuitka binaries..."
aws s3 sync dist/platform/binaries/ s3://$BUCKET_NAME/platform/binaries/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=86400" \
    --content-type "application/octet-stream" \
    --exclude "*.json"

# Sync binary manifests
aws s3 sync dist/platform/binaries/ s3://$BUCKET_NAME/platform/binaries/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=3600" \
    --content-type "application/json" \
    --exclude "*" \
    --include "*.json"

# Sync platform docs
echo "  📚 Syncing documentation..."
aws s3 sync dist/platform/docs/ s3://$BUCKET_NAME/platform/docs/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=3600"

# Sync platform API endpoints
echo "  🔌 Syncing API endpoints..."
aws s3 sync dist/platform/api/ s3://$BUCKET_NAME/platform/api/ \
    $AWS_CLI_ARGS \
    --delete \
    --cache-control "max-age=300" \
    --content-type "application/json"

# Sync platform overview page
echo "  🌐 Syncing platform overview page..."
aws s3 cp dist/platform/index.html s3://$BUCKET_NAME/platform/index.html \
    $AWS_CLI_ARGS \
    --cache-control "max-age=300" \
    --content-type "text/html"

# Set correct MIME types for YAML files (CloudFormation requires this)
echo "  🔧 Setting correct MIME types for CloudFormation templates..."
aws s3 cp s3://$BUCKET_NAME/platform/templates/ s3://$BUCKET_NAME/platform/templates/ \
    $AWS_CLI_ARGS \
    --recursive \
    --exclude "*" \
    --include "*.yaml" \
    --content-type "application/x-yaml" \
    --metadata-directive REPLACE \
    --cache-control "max-age=300"

# Invalidate CloudFront cache
echo ""
echo "🔄 Invalidating CloudFront cache..."

# Get CloudFront distribution ID for watchy.cloud
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    $AWS_CLI_ARGS \
    --query "DistributionList.Items[?contains(Aliases.Items, '$DOMAIN_NAME')].Id" \
    --output text)

if [ -n "$DISTRIBUTION_ID" ] && [ "$DISTRIBUTION_ID" != "None" ]; then
    echo "  Found CloudFront distribution: $DISTRIBUTION_ID"
    
    aws cloudfront create-invalidation \
        $AWS_CLI_ARGS \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/platform/*" > /dev/null 2>&1
    
    echo "  ✅ CloudFront invalidation created for /platform/*"
else
    echo "  ⚠️  CloudFront distribution not found (skipping invalidation)"
fi

# Verify deployment
echo ""
echo "🔍 Verifying deployment..."

sleep 5  # Wait a moment for S3 sync

# Test platform page
if curl -s -f "https://$DOMAIN_NAME/platform/" > /dev/null; then
    echo "  ✅ Platform page accessible"
else
    echo "  ⚠️  Platform page not yet accessible (CloudFront cache may need time)"
fi

# Test templates
if curl -s -f "https://$DOMAIN_NAME/platform/templates/watchy-platform.yaml" > /dev/null; then
    echo "  ✅ CloudFormation templates accessible"
else
    echo "  ❌ CloudFormation templates not accessible"
fi

# Test API
api_response=$(curl -s "https://$DOMAIN_NAME/platform/api/version.json" 2>/dev/null)
if echo "$api_response" | jq -e '.version' > /dev/null 2>&1; then
    current_version=$(echo "$api_response" | jq -r '.version')
    echo "  ✅ Platform API working (version: $current_version)"
else
    echo "  ⚠️  Platform API not yet accessible (may need time for CloudFront)"
fi

# Test binaries
binary_count=0
for binary in slack github zoom; do
    if curl -s -f "https://$DOMAIN_NAME/platform/binaries/watchy-${binary}-monitor" > /dev/null; then
        binary_count=$((binary_count + 1))
    fi
done

if [ $binary_count -eq 3 ]; then
    echo "  ✅ All 3 binaries accessible"
elif [ $binary_count -gt 0 ]; then
    echo "  ⚠️  $binary_count/3 binaries accessible (others may need time)"
else
    echo "  ⚠️  Binaries not yet accessible (may need time for CloudFront)"
fi

# Clean up
echo ""
echo "🧹 Cleaning up build directory..."
rm -rf dist/

echo ""
echo "🎉 Watchy Platform Deployment Complete!"
echo "======================================"
echo ""
echo "📊 Platform URLs:"
echo "  Main site: https://$DOMAIN_NAME (preserved - not modified)"
echo "  Platform: https://$DOMAIN_NAME/platform/"
echo "  Templates: https://$DOMAIN_NAME/platform/templates/"
echo "  API: https://$DOMAIN_NAME/platform/api/version.json"
echo "  Documentation: https://$DOMAIN_NAME/platform/docs/"
echo ""
echo "🚀 Customer Quick Deploy URL:"
echo "https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-platform&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-platform.yaml"
echo ""
echo "📋 Individual SaaS Deployments:"
echo "  Slack: https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-slack&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-slack-monitoring.yaml"
echo "  GitHub: https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-github&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-github-monitoring.yaml"
echo "  Zoom: https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-zoom&templateURL=https://watchy-resources.s3.amazonaws.com/watchy-zoom-monitoring.yaml"
echo ""
echo "💡 Note: If some resources are not immediately accessible, wait 10-15 minutes for CloudFront cache invalidation to complete."
