# Watchy Cloud Platform - Deployment Guide

Complete deployment system for the Watchy Cloud multi-SaaS monitoring platform to your existing `watchy.cloud` S3 bucket.

## 🚀 Quick Deploy

Deploy the entire platform with one command:

```bash
./deploy.sh
```

This will:
- ✅ Build all Nuitka native binaries
- ✅ Update CloudFormation templates 
- ✅ Deploy to `/platform/` subfolder in your S3 bucket
- ✅ Preserve your existing `index.html`
- ✅ Invalidate CloudFront cache
- ✅ Verify deployment

## 📁 Platform Structure

Your `watchy.cloud` bucket will have this structure:

```
watchy.cloud/
├── index.html                     # Your existing website (preserved)
├── (your other website files)     # Your existing content (preserved)
└── platform/                      # Watchy Platform (new)
    ├── index.html                  # Platform overview page
    ├── templates/                  # CloudFormation templates
    │   ├── watchy-platform.yaml    # Parent stack
    │   ├── watchy-slack-monitoring.yaml
    │   ├── watchy-github-monitoring.yaml
    │   ├── watchy-zoom-monitoring.yaml
    │   └── index.html              # Templates browser
    ├── binaries/                   # Nuitka native binaries
    │   ├── watchy-slack-monitor    # Slack binary
    │   ├── watchy-github-monitor   # GitHub binary
    │   ├── watchy-zoom-monitor     # Zoom binary
    │   └── *.json                  # Binary manifests
    ├── api/                        # JSON API endpoints
    │   ├── version.json            # Platform version
    │   ├── slack-monitor-latest.json
    │   ├── github-monitor-latest.json
    │   └── zoom-monitor-latest.json
    └── docs/                       # Documentation
        ├── README.md
        └── LICENSE
```

## 🔧 Configuration Options

### Environment Variables

```bash
export WATCHY_VERSION="1.0.0"      # Set custom version
export AWS_REGION="us-east-1"       # Set AWS region
./deploy.sh
```

### Manual Deployment Steps

If you want to run steps individually:

```bash
# 1. Build binaries only
cd platform/binaries/slack-monitor && ./build.sh
cd ../github-monitor && ./build.sh  
cd ../zoom-monitor && ./build.sh

# 2. Deploy to S3 only
./platform/deploy/deploy-to-watchy-cloud.sh
```

## 🔍 Verification

After deployment, verify these URLs work:

```bash
# Platform overview
curl https://watchy.cloud/platform/

# Platform API
curl https://watchy.cloud/platform/api/version.json

# CloudFormation templates
curl https://watchy-resources.s3.amazonaws.com/platform/templates/watchy-platform.yaml

# Binaries (will be binary data)
curl -I https://watchy.cloud/platform/binaries/watchy-slack-monitor
```

## 👥 Customer Experience

### Quick Deploy URLs

Customers can deploy your platform using these one-click links:

**Complete Platform:**
```
https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-platform&templateURL=https://watchy-resources.s3.amazonaws.com/platform/templates/watchy-platform.yaml
```

**Individual SaaS Apps:**
- **Slack:** `https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-slack&templateURL=https://watchy-resources.s3.amazonaws.com/platform/templates/watchy-slack-monitoring.yaml`
- **GitHub:** `https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-github&templateURL=https://watchy-resources.s3.amazonaws.com/platform/templates/watchy-github-monitoring.yaml`
- **Zoom:** `https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=watchy-zoom&templateURL=https://watchy-resources.s3.amazonaws.com/platform/templates/watchy-zoom-monitoring.yaml`

### Customer Onboarding Script

Provide this command to customers for guided setup:

```bash
curl -s https://watchy.cloud/platform/scripts/customer-onboard.sh | bash
```

## 🔄 Automated Deployment

### GitHub Actions

The repository includes a GitHub Actions workflow that automatically deploys on:
- Pushes to `main` branch
- New version tags (`v1.0.0`, etc.)
- Manual workflow dispatch

### Prerequisites for GitHub Actions

Set these secrets in your GitHub repository:

```
AWS_ACCESS_KEY_ID     # AWS access key
AWS_SECRET_ACCESS_KEY # AWS secret key
```

### Manual Trigger

You can manually trigger deployment from GitHub Actions with a custom version:

1. Go to Actions tab
2. Click "Deploy Watchy Platform to watchy.cloud"
3. Click "Run workflow"
4. Enter version (optional)
5. Click "Run workflow"

## 📊 Monitoring Deployment

### CloudFront Cache

The deployment script automatically invalidates CloudFront cache for `/platform/*`. If resources aren't immediately accessible:

1. Wait 10-15 minutes for cache invalidation
2. Or manually invalidate: `aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/platform/*"`

### Health Checks

Monitor platform health:

```bash
# Check platform version
curl https://watchy.cloud/platform/api/version.json | jq '.version'

# Check all binaries
for app in slack github zoom; do
  echo "Testing $app binary..."
  curl -s -I "https://watchy.cloud/platform/binaries/watchy-${app}-monitor" | head -1
done
```

## 🔒 Security Notes

- ✅ **Source Protection:** All monitoring logic is compiled to native binaries
- ✅ **License Protection:** LemonSqueezy validation embedded in binaries
- ✅ **API Keys:** Stored encrypted in Parameter Store
- ✅ **Binary Integrity:** SHA256 verification for all binaries
- ✅ **Access Control:** CloudFormation uses least-privilege IAM

## 🐛 Troubleshooting

### Build Issues

```bash
# Check Nuitka installation
python3 -c "import nuitka; print('Nuitka OK')"

# Install Nuitka if missing
pip3 install nuitka

# Check build dependencies (Linux)
sudo apt-get install gcc g++ ccache
```

### Deployment Issues

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check bucket access
aws s3 ls s3://watchy.cloud/

# Check CloudFront distribution
aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items, 'watchy.cloud')]"
```

### Access Issues

```bash
# Test platform directly via S3
curl https://watchy.cloud.s3.amazonaws.com/platform/api/version.json

# vs CloudFront cached version
curl https://watchy.cloud/platform/api/version.json
```

## 📈 Scaling & Updates

### Version Updates

1. Update version: `export WATCHY_VERSION="1.1.0"`
2. Run: `./deploy.sh`
3. Lambda functions automatically get new binaries

### Adding New SaaS Apps

1. Create binary in `platform/binaries/new-app/`
2. Create CloudFormation template in `platform/saas-apps/`
3. Update parent template to include new nested stack
4. Redeploy platform

### Multi-Region

Deploy to multiple regions by setting `AWS_REGION`:

```bash
AWS_REGION=us-west-2 ./deploy.sh
AWS_REGION=eu-west-1 ./deploy.sh
```

## 📞 Support

- 🌐 **Platform:** https://watchy.cloud/platform/
- 📚 **Documentation:** https://watchy.cloud/platform/docs/
- 🔌 **API Reference:** https://watchy.cloud/platform/api/version.json
- 📧 **Support:** support@watchy.cloud

---

**Watchy Cloud** - Enterprise SaaS Monitoring with Maximum IP Protection 🚀
