# Contributing to Watchy Cloud Platform

Thank you for your interest in contributing to the Watchy Cloud Platform!

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/cloudbennett/watchy.cloud.git
   cd watchy.cloud
   ```

2. **Set up AWS credentials**
   ```bash
   # See AWS_PROFILE_SETUP.md for detailed setup
   aws configure --profile watchy
   ```

3. **Build binaries (optional for development)**
   ```bash
   cd platform/binaries/
   ./build-all.sh
   ```

## Directory Structure

```
watchy.cloud/
├── platform/                 # Main platform code
│   ├── binaries/             # Native binary monitors
│   ├── infrastructure/       # CloudFormation infrastructure
│   ├── saas-apps/           # SaaS monitoring templates
│   ├── deploy/              # Deployment scripts
│   └── scripts/             # Utility scripts
├── website/                  # Static website content
├── tests/                    # Test files
└── .github/workflows/        # CI/CD pipelines
```

## Development Workflow

### 1. Local Development
```bash
# Test monitors without compilation
export WATCHY_LICENSE_KEY="test_key"
export SLACK_OAUTH_TOKEN="your_token"
python3 platform/binaries/slack-monitor/watchy_slack_monitor.py
```

### 2. Building Binaries
```bash
# Build individual monitor
cd platform/binaries/slack-monitor/
./build.sh

# Build all monitors
cd platform/binaries/
./build-all.sh
```

### 3. Testing Deployment
```bash
# Test deployment (requires AWS access)
./deploy.sh
```

## Code Style

- Follow PEP 8 for Python code
- Use meaningful commit messages
- Add comments for complex logic
- Update documentation for new features

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For questions or issues, please open a GitHub issue or contact support@watchy.cloud.

## License

This project requires a commercial license. See LICENSE file for details.
