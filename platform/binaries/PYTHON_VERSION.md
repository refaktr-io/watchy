# Python Version Management for Nuitka Binaries

## Current Configuration: Python 3.13

All Watchy Nuitka binaries are compiled using **Python 3.13** to match the AWS Lambda runtime.

## Why Version Matching Matters

Nuitka compiles Python code into native binaries that include the Python runtime. The compiled binary must match the Lambda runtime version to ensure:

1. **Binary Compatibility**: Native extensions and C libraries must match the target environment
2. **API Compatibility**: Python standard library APIs match what's available in Lambda
3. **Performance**: Optimizations are tailored to the specific Python version
4. **Dependency Compatibility**: boto3, botocore, and other AWS libraries work correctly

## Updated Files

### Build Scripts
- `platform/binaries/slack-monitor/build.sh`: Uses `python3.13` for compilation
- All Nuitka compilation commands use `python3.13 -m nuitka`

### GitHub Actions
- `.github/workflows/ci-cd.yaml`: All Python setup actions use version `3.13`
- Docker container (amazonlinux:2023) installs `python3.13` and dependencies
- Build environment variable: `PYTHON_VERSION=3.13`

### CloudFormation Templates
- `platform/watchy-platform.yaml`: Lambda runtime set to `python3.13`
- `customer-templates/templates/watchy-slack-monitoring.yaml`: Lambda runtime set to `python3.13`

## Local Development

To build Nuitka binaries locally that match Lambda:

```bash
# Install Python 3.13 (macOS with Homebrew)
brew install python@3.13

# Verify version
python3.13 --version  # Should show Python 3.13.x

# Build the binary
cd platform/binaries/slack-monitor
./build.sh
```

## Upgrading Python Version

When AWS Lambda adds support for a newer Python version:

1. Update all `python3.13` references to the new version in:
   - `platform/binaries/*/build.sh`
   - `.github/workflows/ci-cd.yaml`
   - `platform/watchy-platform.yaml`
   - `customer-templates/templates/*.yaml`

2. Test locally with the new Python version

3. Update this document with the new version number

## Version History

- **2025-10-18**: Upgraded to Python 3.13 (matches Lambda runtime)
- **2025-09-04**: Previously used Python 3.12
