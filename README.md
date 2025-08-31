# Watchy Cloud Platform

Advanced SaaS monitoring platform with secure native binaries and automated infrastructure deployment.

## 🏗️ **Repository Structure**

```text
watchy.cloud/
├── 🌐 platform/                   # Platform infrastructure & binaries
│   ├── infrastructure/            # CloudFormation templates
│   ├── binaries/                  # Monitor source code & builds
│   ├── deploy/                    # Platform deployment scripts
│   └── watchy-platform.yaml      # Main platform template
│
├── 📦 customer-templates/         # Customer deployment templates
│   ├── templates/                 # CloudFormation for customer AWS
│   ├── scripts/                   # Customer setup scripts
│   └── docs/                      # Customer documentation
│
└── 🌐 website/                    # watchy.cloud website
```

## 🚀 **Quick Start**

### 1. Automated Deployment

Platform deployment is handled by GitHub Actions:

- **Push to `main`** → Automatic deployment to production
- **Manual trigger** → Deploy specific version/environment

### 2. Required GitHub Secrets

```text
AWS_ACCESS_KEY_ID       # AWS deployment credentials
AWS_SECRET_ACCESS_KEY   # AWS deployment credentials  
SSL_CERTIFICATE_ARN     # For *.watchy.cloud (optional)
```

**Note**: Platform notifications are sent to `contact@watchy.cloud` by default.

## 🔒 **Security & Binary Integrity**

### Security Features

- **🔍 Automated Security Scanning**: Dependencies, secrets, CloudFormation templates
- **🤖 Dependabot Updates**: Weekly security patches and dependency updates
- **🛡️ CI/CD Integration**: Security checks required for all deployments

### Binary Metadata System

Each compiled binary includes integrity verification:

```bash
# Download and verify binary integrity
curl -s https://releases.watchy.cloud/binaries/slack-monitor/metadata.json | \
  jq -r '.sha256, .latestUrl'
```

**Metadata includes**: SHA256 checksums, build timestamps, git commits, and download URLs for complete audit trail.

### Source Code Protection

- **Nuitka Compilation**: Python source compiled to native x86_64 binaries
- **IP Protection**: No reverse engineering possible from compiled binaries
- **AWS Security**: IAM least privilege, encrypted parameter storage

## 📊 **Platform Components**

### SaaS Monitors

- **Slack Monitor**: Real-time Slack API monitoring with team health checks
- **GitHub Monitor**: Repository and API availability monitoring  
- **Zoom Monitor**: Meeting services and API endpoint monitoring

### Infrastructure

- **Binary Distribution**: CloudFront CDN serving verified Nuitka binaries
- **Monitoring**: CloudWatch integration with custom metrics
- **Customer Templates**: Pre-built CloudFormation for customer deployments

## 🛠️ **Development**

### Local Development

```bash
# Build and test monitors locally
cd platform/binaries/slack-monitor
./build.sh

# Test local builds (no deployment)
python3 watchy_slack_monitor.py
```

### Production Deployment

All production deployment happens via GitHub Actions:

```bash
git add .
git commit -m "Deploy platform updates"
git push origin main
```

## 📋 **Requirements**

- **AWS CLI v2.x** (for local development)
- **Python 3.11+** (for local builds)
- **Nuitka compiler** (for local binary compilation)

## 🆘 **Support & Security**

### Reporting Security Issues

- **Critical**: Email <security@watchy.cloud> (24hr response)
- **Non-critical**: GitHub issue with `security` label (1 week response)

### Platform Support

For support and licensing: [watchy.cloud](https://watchy.cloud)

## 📄 **License**

Commercial license required. Contact us for licensing information.
