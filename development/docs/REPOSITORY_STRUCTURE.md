# Repository Structure Reference

This document provides a complete overview of the watchy.cloud repository structure after optimization and security enhancements.

## 📁 **Root Level Files**

```
watchy.cloud/
├── .gitignore              # Ignore patterns (includes security artifacts)
├── LICENSE                 # MIT License
├── README.md              # Main documentation with security features
└── SECURITY.md            # Security policy and procedures
```

## 🔧 **GitHub Configuration (`.github/`)**

```
.github/
├── dependabot.yml         # Automated dependency updates
├── workflows/
│   └── ci-cd.yml         # Complete CI/CD pipeline with security scanning
└── ISSUE_TEMPLATE/
    └── deployment.yml    # GitHub form for deployment issues
```

## 🏗️ **Platform Infrastructure (`platform/`)**

```
platform/
├── README.md                          # Platform documentation
├── watchy-platform.yaml              # Main platform CloudFormation
├── infrastructure/                    # Infrastructure templates
│   ├── binary-distribution.yaml      # CloudFront & S3 for binaries
│   ├── create-binary-distribution.sh # Infrastructure setup
│   ├── deploy-binary-distribution.sh # Infrastructure deployment
│   └── setup-binary-distribution.sh  # Initial infrastructure setup
├── binaries/                          # Monitor source code & builds
│   ├── README.md                      # Binary build documentation
│   ├── build-all.sh                  # Build all monitors
│   ├── github-monitor/                # GitHub monitoring service
│   ├── slack-monitor/                 # Slack monitoring service
│   └── zoom-monitor/                  # Zoom monitoring service
├── deploy/                            # Platform deployment scripts
│   └── deploy-to-watchy-cloud.sh     # Platform deployment
└── saas-apps/                         # SaaS application templates
    ├── watchy-github-monitoring.yaml
    ├── watchy-saas-template.yaml
    ├── watchy-slack-monitoring.yaml
    └── watchy-zoom-monitoring.yaml
```

## 📦 **Customer Deliverables (`customer-templates/`)**

```
customer-templates/
├── README.md                    # Customer setup guide
├── templates/                   # Customer CloudFormation templates
│   ├── github-monitoring.yaml  # GitHub monitor for customers
│   ├── slack-monitoring.yaml   # Slack monitor for customers
│   └── zoom-monitoring.yaml    # Zoom monitor for customers
├── scripts/                     # Customer setup scripts
│   └── customer-onboard.sh     # Customer onboarding automation
└── docs/                        # Customer documentation
    ├── configuration.md         # Configuration guide
    └── troubleshooting.md       # Troubleshooting guide
```

## 🔧 **Development Resources (`development/`)**

```
development/
├── README.md                           # Development setup guide
├── tests/                              # Testing framework
│   └── test_slack_monitor.py          # Test cases
└── docs/                               # Development documentation
    ├── CONTRIBUTING.md                 # Contribution guidelines
    ├── DEPLOYMENT.md                   # Deployment procedures
    ├── AWS_PROFILE_SETUP.md            # AWS configuration
    └── GITHUB_ACTIONS_OPTIMIZATION.md  # CI/CD optimization guide
```

## 🌐 **Website (`website/`)**

```
website/
└── index.html              # Public watchy.cloud landing page
```

## 🔒 **Security Features Integration**

### **Automated Security Scanning**
- **File**: `.github/workflows/ci-cd.yml`
- **Features**: Secret detection, dependency scanning, Python security analysis
- **Frequency**: Every main branch push + manual triggers

### **Dependency Management**
- **File**: `.github/dependabot.yml`
- **Features**: Weekly automated updates for Python packages and GitHub Actions
- **Organization**: Separate configurations per monitor service

### **Security Documentation**
- **File**: `SECURITY.md`
- **Features**: Vulnerability reporting, security procedures, best practices
- **Integration**: Referenced from README.md

### **Enhanced .gitignore**
- **Security artifacts**: `*.sarif`, `bandit-results.txt`, `safety-report.json`
- **Sensitive files**: `.env*`, `*.pem`, `*.key`, `secrets.yml`
- **Build artifacts**: Platform-specific build outputs

## ✅ **Cleanup Completed**

### **Removed Files**
- ❌ `deploy.sh` - Deprecated root deployment script (replaced by GitHub Actions)
- ❌ `.github/ISSUE_TEMPLATE/deployment.md` - Old markdown template (replaced by YAML form)

### **Enhanced Files**
- ✅ `.gitignore` - Added security and sensitive file patterns
- ✅ `README.md` - Added security features section
- ✅ `.github/workflows/ci-cd.yml` - Enhanced with comprehensive security scanning

## 🎯 **Repository Benefits**

### **Clear Separation**
- **Platform developers** work in `platform/` and `development/`
- **Customers** download and use `customer-templates/`
- **Public website** content in `website/`

### **Security First**
- Automated security scanning and dependency updates
- Clear security policy and vulnerability reporting
- Protected sensitive file patterns in .gitignore

### **CI/CD Optimized**
- Smart change detection to minimize unnecessary deployments
- Comprehensive testing and validation pipeline
- Automated deployment with manual override capability

---

**Last Updated**: August 30, 2025  
**Structure Version**: 2.0 (Post-Security Enhancement)
