# Watchy Binary Build Pipeline

This directory contains the Docker-based build pipeline for creating AWS Lambda-compatible Nuitka binaries for Watchy monitoring applications.

## Overview

The build pipeline compiles Python applications into standalone native binaries using Nuitka, specifically targeting the Amazon Linux 2023 runtime environment used by AWS Lambda.

## Architecture

- **Source**: Python monitoring scripts (Slack, GitHub, Zoom)
- **Compiler**: Nuitka (Python to native binary compiler)
- **Runtime**: Amazon Linux 2023 (AWS Lambda environment)
- **Target**: x86_64 Linux binaries
- **Packaging**: Gzip compression + metadata JSON

## Build Methods

### 1. GitHub Actions (Recommended for Production)

The GitHub Actions workflow automatically builds binaries when:
- Files in `platform/binaries/` are modified
- Infrastructure changes are detected
- Force rebuild is triggered

**To force a rebuild of all binaries:**
```bash
# Update the force build trigger file
echo "BUILD_TRIGGER=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > platform/binaries/FORCE_BUILD
git add platform/binaries/FORCE_BUILD
git commit -m "Force binary rebuild"
git push origin main
```

### 2. Local Development Builds

Automated builds triggered by:
- Push to `main` or `develop` branches
- Manual workflow dispatch
- Pull requests

**Features:**
- ✅ Consistent build environment
- ✅ Automatic S3 uploads
- ✅ Versioned artifacts
- ✅ Build matrix for all monitors
- ✅ Artifact retention

**To trigger manually:**
1. Go to GitHub Actions tab
2. Select "Build Watchy Monitoring Binaries"
3. Click "Run workflow"
4. Specify version (e.g., "1.0.0")

### 2. Local Docker Build

For development and testing:

```bash
# Build all monitors
cd platform/binaries
./build-all.sh

# Build specific monitor
cd platform/binaries/slack-monitor
./docker-build.sh
```

## Directory Structure

```
platform/binaries/
├── build-all.sh              # Local build orchestrator
├── slack-monitor/
│   ├── watchy_slack_monitor.py
│   ├── requirements.txt
│   ├── docker-build.sh       # Auto-generated
│   ├── build/                 # Build artifacts
│   ├── dist/                  # Distribution packages
│   └── lambda/                # Lambda deployment package
├── github-monitor/
│   └── ...
└── zoom-monitor/
    └── ...
```

## Build Process

### Phase 1: Docker Environment Setup
1. **Base Image**: `public.ecr.aws/lambda/python:3.11-x86_64`
2. **Install**: Development tools, compilers, Python packages
3. **Nuitka**: Latest version with Lambda optimizations

### Phase 2: Compilation
1. **Source Preparation**: Copy Python files and dependencies
2. **Nuitka Compilation**: 
   - Standalone binary creation
   - Dependency bundling
   - Size optimization
3. **Verification**: Binary execution test

### Phase 3: Packaging
1. **Metadata Generation**: JSON with version, checksum, URLs
2. **Compression**: Gzip for distribution
3. **Lambda Package**: ZIP with binary for deployment
4. **Artifact Organization**: Versioned files in dist/

## Output Artifacts

Each build produces:

```
dist/
├── watchy-{app}-monitor-{version}        # Raw binary
├── watchy-{app}-monitor-{version}.gz     # Compressed binary
├── watchy-{app}-monitor.json             # Metadata
└── watchy-{app}-lambda-{version}.zip     # Lambda deployment package
```

### Metadata JSON Format

```json
{
  "version": "1.0.0",
  "build_time": "2025-01-27T10:30:00Z",
  "saas_app": "Slack",
  "binary_type": "nuitka",
  "binary_size": 12345678,
  "sha256": "abc123...",
  "download_url": "https://releases.watchy.cloud/binaries/slack-monitor/watchy-slack-monitor-1.0.0.gz",
  "compression": "gzip",
  "target_architecture": "x86_64",
  "target_os": "linux",
  "lambda_compatible": true,
  "runtime_environment": "amazon-linux-2023",
  "python_version": "3.11"
}
```

## Distribution Setup

### S3 Structure
```
s3://watchy-releases/binaries/
├── slack-monitor/
│   ├── watchy-slack-monitor.json         # Latest metadata
│   ├── watchy-slack-monitor.gz           # Latest binary
│   ├── watchy-slack-monitor-1.0.0.json  # Versioned metadata
│   └── watchy-slack-monitor-1.0.0.gz    # Versioned binary
├── github-monitor/
│   └── ...
└── zoom-monitor/
    └── ...
```

### CloudFormation Configuration

Update your CloudFormation template:

```yaml
Parameters:
  BinaryDistributionUrl:
    Type: String
    Default: 'https://releases.watchy.cloud/binaries'
```

The Lambda function will fetch:
- Metadata: `{BinaryDistributionUrl}/{app}-monitor/watchy-{app}-monitor.json`
- Binary: URL specified in metadata JSON

## Development Workflow

### 1. Local Development
```bash
# Test local build
cd platform/binaries/slack-monitor
./docker-build.sh

# Check output
ls -la dist/
```

### 2. Continuous Integration
```bash
# Push changes
git add .
git commit -m "Update Slack monitor"
git push origin main

# GitHub Actions automatically builds and uploads
```

### 3. Deployment
```bash
# Deploy with updated binaries
aws cloudformation deploy \
  --template-file watchy-platform.yaml \
  --stack-name watchy-platform \
  --parameter-overrides BinaryDistributionUrl=https://releases.watchy.cloud/binaries \
  --profile watchy
```

## Troubleshooting

### "Exec format error"
- Binary was built for wrong architecture
- Use Docker build to ensure Linux x86_64 target

### "No such file or directory"
- Check S3 URLs and bucket permissions
- Verify metadata JSON format

### "Permission denied"
- Lambda function needs correct IAM permissions for S3
- Check binary download and execution permissions

### Build Failures
```bash
# Clean build environment
docker system prune -f

# Rebuild with verbose output
WATCHY_VERSION=1.0.0 ./docker-build.sh
```

## Requirements

### Local Development
- Docker Desktop
- Bash shell
- Internet connection (for base images and packages)

### GitHub Actions
- Repository secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- S3 bucket: `watchy-releases`
- Appropriate IAM permissions

## Security Considerations

- ✅ **Reproducible Builds**: Docker ensures consistent environment
- ✅ **Checksum Verification**: SHA256 hashes for integrity
- ✅ **Minimal Dependencies**: Only required packages included
- ✅ **No Secrets in Binaries**: Credentials fetched at runtime
- ✅ **Signed Artifacts**: GitHub Actions provides provenance

## Performance Optimizations

- **Native Binaries**: Faster startup than interpreted Python
- **Standalone**: No dependency resolution at runtime
- **Compressed**: Reduced download time and storage
- **Cached**: Docker layers cached for faster subsequent builds

## Monitoring

Track build metrics:
- Build duration
- Binary sizes
- Success/failure rates
- Distribution download counts

## Future Enhancements

- [ ] Multi-architecture builds (ARM64)
- [ ] Binary signing and verification
- [ ] Automated security scanning
- [ ] Performance benchmarking
- [ ] Build caching optimizations
