#!/bin/bash

# Build all Watchy monitoring binaries locally using Docker
# This script builds all binaries for AWS Lambda compatibility

set -e

VERSION=${WATCHY_VERSION:-"1.0.0"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🏗️ Building all Watchy monitoring binaries v${VERSION}"
echo "Target: AWS Lambda x86_64 (Amazon Linux 2023)"
echo "=================================================="

# Function to build a monitor
build_monitor() {
    local monitor_name=$1
    local monitor_dir="${SCRIPT_DIR}/${monitor_name}"
    
    if [ ! -d "$monitor_dir" ]; then
        echo "⚠️ Directory not found: $monitor_dir"
        return 1
    fi
    
    echo ""
    echo "🔨 Building ${monitor_name}..."
    echo "-------------------------------"
    
    cd "$monitor_dir"
    
    if [ -f "docker-build.sh" ]; then
        ./docker-build.sh
        echo "✅ ${monitor_name} build completed"
    else
        echo "⚠️ docker-build.sh not found for ${monitor_name}"
        echo "Creating build script..."
        
        # Create a generic build script if it doesn't exist
        cat > docker-build.sh << EOF
#!/bin/bash
set -e

VERSION=\${WATCHY_VERSION:-"1.0.0"}
BUILD_TIME=\$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="watchy-${monitor_name//-/}"

echo "🐳 Building \${BINARY_NAME} with Docker + Nuitka v\${VERSION}"

# Clean and create directories
rm -rf build dist lambda
mkdir -p build dist lambda

# Create Dockerfile
cat > Dockerfile << 'DOCKERFILE'
FROM public.ecr.aws/lambda/python:3.11-x86_64

RUN dnf update -y && \\
    dnf groupinstall -y "Development Tools" && \\
    dnf install -y gcc gcc-c++ make zlib-devel openssl-devel libffi-devel bzip2-devel xz-devel sqlite-devel readline-devel tk-devel gdbm-devel ncurses-devel python3-devel && \\
    dnf clean all

RUN pip install --upgrade pip setuptools wheel && \\
    pip install nuitka requests boto3 certifi urllib3

WORKDIR /build
COPY *.py .
COPY requirements.txt .
COPY docker-build-internal.sh .
RUN chmod +x docker-build-internal.sh

CMD ["./docker-build-internal.sh"]
DOCKERFILE

# Create internal build script
cat > docker-build-internal.sh << 'INTERNAL'
#!/bin/bash
set -e

VERSION=\${WATCHY_VERSION:-"1.0.0"}
BUILD_TIME=\${WATCHY_BUILD_TIME:-\$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
BINARY_NAME="\${BINARY_NAME:-watchy-monitor}"

echo "🔨 Building \${BINARY_NAME}..."

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

# Find the main Python file
MAIN_FILE=\$(ls *.py | head -1)
if [ -z "\$MAIN_FILE" ]; then
    echo "❌ No Python files found!"
    exit 1
fi

python -m nuitka \\
    --standalone \\
    --onefile \\
    --assume-yes-for-downloads \\
    --follow-imports \\
    --output-filename=\${BINARY_NAME} \\
    --output-dir=/output \\
    --python-flag=no_warnings \\
    --python-flag=no_docstrings \\
    --python-flag=no_asserts \\
    --disable-console \\
    --include-package=requests \\
    --include-package=boto3 \\
    --include-package=botocore \\
    --include-package=urllib3 \\
    --include-package=certifi \\
    \$MAIN_FILE

# Create metadata
BINARY_SIZE=\$(stat -c%s /output/\${BINARY_NAME})
BINARY_HASH=\$(sha256sum /output/\${BINARY_NAME} | cut -d' ' -f1)

cat > /output/\${BINARY_NAME}.json << METADATA
{
  "version": "\${VERSION}",
  "build_time": "\${BUILD_TIME}",
  "saas_app": "${monitor_name}",
  "binary_type": "nuitka",
  "binary_size": \${BINARY_SIZE},
  "sha256": "\${BINARY_HASH}",
  "download_url": "https://releases.watchy.cloud/binaries/${monitor_name}/\${BINARY_NAME}-\${VERSION}.gz",
  "compression": "gzip",
  "target_architecture": "x86_64",
  "target_os": "linux",
  "lambda_compatible": true,
  "runtime_environment": "amazon-linux-2023",
  "python_version": "3.11"
}
METADATA

echo "✅ \${BINARY_NAME} build complete!"
INTERNAL

chmod +x docker-build-internal.sh

# Build and run
docker build -t watchy-${monitor_name}-builder:\${VERSION} .
docker run --rm -v "\${SCRIPT_DIR}/build:/output" -e WATCHY_VERSION="\${VERSION}" -e WATCHY_BUILD_TIME="\${BUILD_TIME}" -e BINARY_NAME="\${BINARY_NAME}" watchy-${monitor_name}-builder:\${VERSION}

# Package
if [ -f "build/\${BINARY_NAME}" ]; then
    cp build/\${BINARY_NAME} dist/\${BINARY_NAME}-\${VERSION}
    cp build/\${BINARY_NAME}.json dist/
    gzip -c dist/\${BINARY_NAME}-\${VERSION} > dist/\${BINARY_NAME}-\${VERSION}.gz
    cp build/\${BINARY_NAME} lambda/
    cd lambda && zip -r ../dist/\${BINARY_NAME}-lambda-\${VERSION}.zip . && cd ..
    echo "✅ \${BINARY_NAME} packaged!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Cleanup
docker rmi watchy-${monitor_name}-builder:\${VERSION} || true
rm -f Dockerfile docker-build-internal.sh
EOF
        
        chmod +x docker-build.sh
        ./docker-build.sh
    fi
}

# Build each monitor
build_monitor "slack-monitor"
build_monitor "github-monitor" 
build_monitor "zoom-monitor"

echo ""
echo "📊 Build Summary"
echo "================"

total_size=0
for monitor in slack-monitor github-monitor zoom-monitor; do
    if [ -d "${SCRIPT_DIR}/${monitor}/dist" ]; then
        echo ""
        echo "${monitor}:"
        ls -la "${SCRIPT_DIR}/${monitor}/dist/" | grep -E '\.(gz|zip|json)$' || echo "  No build artifacts found"
        
        # Calculate sizes
        if [ -f "${SCRIPT_DIR}/${monitor}/dist/"*.gz ]; then
            size=$(du -h "${SCRIPT_DIR}/${monitor}/dist/"*.gz | cut -f1)
            echo "  Compressed size: ${size}"
        fi
    fi
done

echo ""
echo "✅ All builds completed!"
echo ""
echo "📦 Next steps:"
echo "1. Upload dist/*.json and *.gz files to your S3 binary distribution"
echo "2. Update CloudFormation WATCHY_BINARY_DISTRIBUTION_URL parameter"
echo "3. Deploy Lambda functions"
echo ""
echo "🚀 Build pipeline complete!"
