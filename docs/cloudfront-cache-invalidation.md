# CloudFront Cache Invalidation System

## Overview

The Watchy.cloud platform now includes automatic CloudFront cache invalidation to prevent stale content issues when new binaries or templates are deployed. This system was implemented to resolve issues where Lambda functions would download outdated binaries due to CloudFront caching.

## How It Works

### Binary Distribution Cache Invalidation

When new binaries are built and deployed via GitHub Actions:

1. **Automatic Detection**: The CI/CD pipeline detects when binaries are updated
2. **Upload Process**: New binaries and metadata are uploaded to S3
3. **Cache Invalidation**: CloudFront cache is automatically invalidated for:
   - `/binaries/{monitor}/watchy-{monitor}-latest` (latest binary)
   - `/binaries/{monitor}/watchy-{monitor}-{version}` (versioned binary)
   - `/binaries/{monitor}/metadata.json` (metadata file)

### Customer Templates Cache Invalidation

When customer templates are updated:

1. **Template Sync**: Updated templates are synced to the template resources bucket
2. **Cache Invalidation**: CloudFront cache is invalidated for `/customer-templates/*`

## Implementation Details

### Binary Deployment Process

```bash
# 1. Upload binary to S3
aws s3 cp "watchy-slack-monitor" "s3://bucket/binaries/slack-monitor/watchy-slack-monitor-latest"

# 2. Upload metadata with checksum
aws s3 cp "metadata.json" "s3://bucket/binaries/slack-monitor/metadata.json"

# 3. Automatically invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id "E2BX1E7RR7IV8R" \
  --paths "/binaries/slack-monitor/watchy-slack-monitor-latest,/binaries/slack-monitor/metadata.json"
```

### Cache Invalidation Targets

| Resource Type | CloudFront Distribution | Invalidation Paths |
|---------------|-------------------------|-------------------|
| Binary Distribution | `releases.watchy.cloud` | `/binaries/{monitor}/*` |
| Customer Templates | Template Resources | `/customer-templates/*` |
| Platform Files | `watchy.cloud` | Manual if needed |

## Benefits

### 🚫 **Prevents Cache Issues**
- Eliminates stale binary downloads
- Ensures Lambda functions get latest versions
- Prevents checksum mismatches

### ⚡ **Automatic Operation**
- No manual intervention required
- Integrated into CI/CD pipeline
- Happens immediately after uploads

### 🔍 **Comprehensive Coverage**
- Covers Slack binary cache invalidation
- Includes metadata files
- Covers customer templates

### 📊 **Monitoring & Logging**
- Invalidation IDs logged for tracking
- Clear success/failure reporting
- Non-critical errors don't break builds

## Troubleshooting

### Cache Invalidation Failures

If cache invalidation fails (non-critical):

1. **Check Distribution ID**: Verify CloudFront distribution exists
2. **Manual Invalidation**: Can be performed manually if needed:
   ```bash
   aws cloudfront create-invalidation \
     --distribution-id E2BX1E7RR7IV8R \
     --paths "/binaries/slack-monitor/*"
   ```

### Verification

To verify cache invalidation worked:

```bash
# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E2BX1E7RR7IV8R \
  --id INVALIDATION_ID

# Test fresh download
curl -v https://releases.watchy.cloud/binaries/slack-monitor/metadata.json
# Look for "X-Cache: Miss from cloudfront" in headers
```

### Timeline

- **Invalidation Creation**: Immediate
- **Propagation Time**: 5-15 minutes
- **Global Effect**: All edge locations updated

## Configuration

### Environment Variables

The system automatically detects:
- CloudFront distribution IDs by domain alias
- S3 bucket names from CloudFormation outputs
- AWS region from workflow environment

### Dependencies

- AWS CLI with CloudFront permissions
- CloudFormation stack outputs
- GitHub Actions secrets for AWS credentials

## Future Enhancements

### Potential Improvements

1. **Selective Invalidation**: Only invalidate changed files
2. **Batch Invalidation**: Group multiple invalidations
3. **Status Monitoring**: Wait for invalidation completion
4. **Cost Optimization**: Monitor invalidation costs

### Monitoring

Consider adding:
- CloudWatch metrics for invalidation success/failure
- Alerts for repeated invalidation failures
- Cost tracking for invalidation requests

## Related Documentation

- [Binary Distribution Architecture](../platform/binaries/README.md)
- [CloudFormation Infrastructure](../platform/infrastructure/README.md)
- [CI/CD Pipeline](../.github/workflows/ci-cd.yml)
