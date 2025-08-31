#!/bin/bash

# Create Binary Distribution CloudFront Distribution
# This creates a separate distribution for hosting Watchy binaries

set -e

PROFILE="watchy"
DOMAIN_NAME="releases.watchy.cloud"
BUCKET_NAME="watchy-releases"

echo "🚀 Creating Binary Distribution Infrastructure"
echo "============================================="
echo "Domain: ${DOMAIN_NAME}"
echo "Bucket: ${BUCKET_NAME}"
echo ""

# 1. Create the S3 bucket for binaries
echo "📦 Creating S3 bucket for binaries..."
if aws s3 ls s3://${BUCKET_NAME} --profile ${PROFILE} 2>/dev/null; then
    echo "✅ Bucket ${BUCKET_NAME} already exists"
else
    aws s3 mb s3://${BUCKET_NAME} --profile ${PROFILE}
    echo "✅ Created bucket ${BUCKET_NAME}"
fi

# 2. Block public access (CloudFront will access via OAC)
echo "🔒 Setting bucket security..."
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --profile ${PROFILE}

# 3. Check for SSL certificate
echo "🔍 Checking for SSL certificate..."
CERT_ARN=$(aws acm list-certificates --profile ${PROFILE} --region us-east-1 \
    --query "CertificateList[?DomainName=='*.watchy.cloud' || DomainName=='watchy.cloud'].CertificateArn" \
    --output text 2>/dev/null || echo "")

if [ -z "$CERT_ARN" ]; then
    echo "❌ No SSL certificate found for *.watchy.cloud in us-east-1"
    echo ""
    echo "Creating SSL certificate..."
    CERT_ARN=$(aws acm request-certificate \
        --domain-name "*.watchy.cloud" \
        --validation-method DNS \
        --profile ${PROFILE} \
        --region us-east-1 \
        --query CertificateArn \
        --output text)
    
    echo "🔐 Certificate requested: ${CERT_ARN}"
    echo "⚠️  You need to validate this certificate in the AWS console before proceeding"
    echo "   Go to: https://console.aws.amazon.com/acm/home?region=us-east-1#/"
    echo ""
    read -p "Press Enter after you've validated the certificate..."
else
    echo "✅ Found SSL certificate: ${CERT_ARN}"
fi

# 4. Create CloudFront distribution using AWS CLI
echo "🌐 Creating CloudFront distribution..."

# Create distribution config JSON
cat > /tmp/distribution-config.json << EOF
{
    "CallerReference": "watchy-binary-dist-$(date +%s)",
    "Comment": "Watchy Binary Distribution CDN",
    "Enabled": true,
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-${BUCKET_NAME}",
                "DomainName": "${BUCKET_NAME}.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                },
                "OriginAccessControlId": ""
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true
    },
    "CacheBehaviors": {
        "Quantity": 2,
        "Items": [
            {
                "PathPattern": "binaries/*/*.json",
                "TargetOriginId": "S3-${BUCKET_NAME}",
                "ViewerProtocolPolicy": "redirect-to-https",
                "TrustedSigners": {
                    "Enabled": false,
                    "Quantity": 0
                },
                "ForwardedValues": {
                    "QueryString": false,
                    "Cookies": {
                        "Forward": "none"
                    }
                },
                "MinTTL": 0,
                "DefaultTTL": 300,
                "MaxTTL": 3600,
                "Compress": true
            },
            {
                "PathPattern": "binaries/*/*.gz",
                "TargetOriginId": "S3-${BUCKET_NAME}",
                "ViewerProtocolPolicy": "redirect-to-https",
                "TrustedSigners": {
                    "Enabled": false,
                    "Quantity": 0
                },
                "ForwardedValues": {
                    "QueryString": false,
                    "Cookies": {
                        "Forward": "none"
                    }
                },
                "MinTTL": 3600,
                "DefaultTTL": 86400,
                "MaxTTL": 31536000,
                "Compress": false
            }
        ]
    },
    "Aliases": {
        "Quantity": 1,
        "Items": ["${DOMAIN_NAME}"]
    },
    "ViewerCertificate": {
        "ACMCertificateArn": "${CERT_ARN}",
        "SSLSupportMethod": "sni-only",
        "MinimumProtocolVersion": "TLSv1.2_2021"
    },
    "PriceClass": "PriceClass_100",
    "HttpVersion": "http2"
}
EOF

# Create the distribution
DISTRIBUTION_RESULT=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/distribution-config.json \
    --profile ${PROFILE} \
    --output json)

DISTRIBUTION_ID=$(echo ${DISTRIBUTION_RESULT} | jq -r '.Distribution.Id')
CLOUDFRONT_DOMAIN=$(echo ${DISTRIBUTION_RESULT} | jq -r '.Distribution.DomainName')

echo "✅ CloudFront distribution created!"
echo "   Distribution ID: ${DISTRIBUTION_ID}"
echo "   Domain: ${CLOUDFRONT_DOMAIN}"

# 5. Wait for distribution to deploy
echo ""
echo "⏳ Waiting for distribution to deploy (this takes 15-20 minutes)..."
echo "   You can check status at: https://console.aws.amazon.com/cloudfront/home"

# 6. Create Origin Access Control and update distribution
echo ""
echo "🔐 Creating Origin Access Control..."

OAC_RESULT=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config Name="watchy-binary-oac",Description="OAC for Watchy binary distribution",OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4 \
    --profile ${PROFILE} \
    --output json)

OAC_ID=$(echo ${OAC_RESULT} | jq -r '.OriginAccessControl.Id')
echo "✅ Created OAC: ${OAC_ID}"

# 7. Update bucket policy for CloudFront access
echo "🔧 Updating bucket policy..."
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::$(aws sts get-caller-identity --profile ${PROFILE} --query Account --output text):distribution/${DISTRIBUTION_ID}"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket ${BUCKET_NAME} \
    --policy file:///tmp/bucket-policy.json \
    --profile ${PROFILE}

echo "✅ Bucket policy updated"

# 8. Create test directory structure
echo ""
echo "📁 Creating test directory structure..."
aws s3api put-object \
    --bucket ${BUCKET_NAME} \
    --key binaries/slack-monitor/ \
    --profile ${PROFILE} >/dev/null

aws s3api put-object \
    --bucket ${BUCKET_NAME} \
    --key binaries/github-monitor/ \
    --profile ${PROFILE} >/dev/null

aws s3api put-object \
    --bucket ${BUCKET_NAME} \
    --key binaries/zoom-monitor/ \
    --profile ${PROFILE} >/dev/null

# Create a test JSON file
cat > /tmp/test-binary.json << EOF
{
  "version": "1.0.0",
  "build_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "saas_app": "Test",
  "binary_type": "nuitka",
  "binary_size": 1234567,
  "sha256": "abcdef1234567890",
  "download_url": "https://${DOMAIN_NAME}/binaries/slack-monitor/test-binary.gz",
  "compression": "gzip",
  "target_architecture": "x86_64",
  "target_os": "linux",
  "lambda_compatible": true,
  "runtime_environment": "amazon-linux-2023"
}
EOF

aws s3 cp /tmp/test-binary.json s3://${BUCKET_NAME}/binaries/slack-monitor/watchy-slack-monitor.json --profile ${PROFILE}

echo "✅ Test files uploaded"

# Cleanup temp files
rm -f /tmp/distribution-config.json /tmp/bucket-policy.json /tmp/test-binary.json

echo ""
echo "🎉 Binary Distribution Setup Complete!"
echo "======================================"
echo ""
echo "📊 Summary:"
echo "   S3 Bucket: s3://${BUCKET_NAME}"
echo "   CloudFront ID: ${DISTRIBUTION_ID}"
echo "   CloudFront Domain: ${CLOUDFRONT_DOMAIN}"
echo "   Custom Domain: ${DOMAIN_NAME}"
echo "   Base URL: https://${DOMAIN_NAME}"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 🌐 Update DNS: Create CNAME record for ${DOMAIN_NAME} → ${CLOUDFRONT_DOMAIN}"
echo ""
echo "2. 🔧 Update your platform template with:"
echo "   BinaryDistributionUrl: https://${DOMAIN_NAME}"
echo ""
echo "3. 📦 Update GitHub Actions to upload to: s3://${BUCKET_NAME}/binaries/"
echo ""
echo "4. 🧪 Test the distribution (after DNS propagation):"
echo "   curl -I https://${DOMAIN_NAME}/binaries/slack-monitor/watchy-slack-monitor.json"
echo ""
echo "5. ⏳ Distribution deployment status:"
echo "   aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --profile ${PROFILE} --query 'Distribution.Status'"
echo ""
echo "✅ Ready for binary hosting!"
