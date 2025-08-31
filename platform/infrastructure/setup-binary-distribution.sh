#!/bin/bash

# Step-by-step CloudFront Distribution Setup for Binary Distribution
# This script handles SSL certificate creation and CloudFront setup

set -e

PROFILE="watchy"
DOMAIN_NAME="releases.watchy.cloud"
BUCKET_NAME="watchy-releases"

echo "🚀 Setting up Binary Distribution Infrastructure"
echo "=============================================="
echo "Domain: ${DOMAIN_NAME}"
echo "Bucket: ${BUCKET_NAME}"
echo ""

# Step 1: Create SSL Certificate in us-east-1
echo "🔐 Step 1: Creating SSL Certificate in us-east-1..."
echo ""

# Use the existing validated certificate
CERT_ARN="arn:aws:acm:us-east-1:571600842718:certificate/75d03bd2-206f-4a00-85f0-c668a5f74949"

echo "✅ Using existing validated certificate: ${CERT_ARN}"
echo ""

# Verify certificate is valid
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn ${CERT_ARN} \
    --profile ${PROFILE} \
    --region us-east-1 \
    --query "Certificate.Status" \
    --output text)

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not in ISSUED status: ${CERT_STATUS}"
    exit 1
fi

echo "✅ Certificate is valid and issued"

if false; then
    # This block is kept for reference but not executed
    echo "📋 Requesting new SSL certificate for *.watchy.cloud..."
    
    CERT_ARN=$(aws acm request-certificate \
        --domain-name "*.watchy.cloud" \
        --subject-alternative-names "watchy.cloud" \
        --validation-method DNS \
        --profile ${PROFILE} \
        --region us-east-1 \
        --query CertificateArn \
        --output text)
    
    echo "✅ Certificate requested: ${CERT_ARN}"
    echo ""
    echo "🔍 Getting DNS validation records..."
    
    # Get validation records
    aws acm describe-certificate \
        --certificate-arn ${CERT_ARN} \
        --profile ${PROFILE} \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord.Name,ResourceRecord.Value]' \
        --output table
    
    echo ""
    echo "⚠️  IMPORTANT: You need to add these DNS records to validate the certificate:"
    echo ""
    echo "1. Go to your DNS provider (Route 53, Cloudflare, etc.)"
    echo "2. Add the CNAME records shown above"
    echo "3. Wait for DNS propagation (5-10 minutes)"
    echo "4. Come back and run this script again"
    echo ""
    echo "To check certificate status:"
    echo "aws acm describe-certificate --certificate-arn ${CERT_ARN} --profile ${PROFILE} --region us-east-1 --query 'Certificate.Status'"
    echo ""
    exit 0
fi

# Check certificate status
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn ${CERT_ARN} \
    --profile ${PROFILE} \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not yet issued. Status: ${CERT_STATUS}"
    echo ""
    echo "Please wait for certificate validation to complete."
    echo "Check status with:"
    echo "aws acm describe-certificate --certificate-arn ${CERT_ARN} --profile ${PROFILE} --region us-east-1 --query 'Certificate.Status'"
    exit 1
fi

echo "✅ Certificate is ready: ${CERT_ARN}"
echo ""

# Step 2: Create S3 bucket
echo "📦 Step 2: Creating S3 bucket..."
if aws s3 ls s3://${BUCKET_NAME} --profile ${PROFILE} 2>/dev/null; then
    echo "✅ Bucket ${BUCKET_NAME} already exists"
else
    aws s3 mb s3://${BUCKET_NAME} --profile ${PROFILE}
    echo "✅ Created bucket ${BUCKET_NAME}"
fi

# Set bucket security
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --profile ${PROFILE}

echo "🔒 Bucket security configured"

# Step 3: Create Origin Access Control
echo ""
echo "🔐 Step 3: Creating Origin Access Control..."

OAC_NAME="watchy-binary-oac"
EXISTING_OAC=$(aws cloudfront list-origin-access-controls --profile ${PROFILE} \
    --query "OriginAccessControlList.Items[?Name=='${OAC_NAME}'].Id" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$EXISTING_OAC" ]; then
    echo "✅ Found existing OAC: ${EXISTING_OAC}"
    OAC_ID="$EXISTING_OAC"
else
    OAC_RESULT=$(aws cloudfront create-origin-access-control \
        --origin-access-control-config Name="${OAC_NAME}",Description="OAC for Watchy binary distribution",OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4 \
        --profile ${PROFILE} \
        --output json)
    
    OAC_ID=$(echo ${OAC_RESULT} | jq -r '.OriginAccessControl.Id')
    echo "✅ Created OAC: ${OAC_ID}"
fi

# Step 4: Create CloudFront Distribution
echo ""
echo "🌐 Step 4: Creating CloudFront Distribution..."

# Create distribution config
cat > /tmp/cf-distribution-config.json << EOF
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
                "OriginAccessControlId": "${OAC_ID}"
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 3,
            "Items": ["GET", "HEAD", "OPTIONS"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
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
                "AllowedMethods": {
                    "Quantity": 3,
                    "Items": ["GET", "HEAD", "OPTIONS"],
                    "CachedMethods": {
                        "Quantity": 2,
                        "Items": ["GET", "HEAD"]
                    }
                },
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
                "AllowedMethods": {
                    "Quantity": 2,
                    "Items": ["GET", "HEAD"],
                    "CachedMethods": {
                        "Quantity": 2,
                        "Items": ["GET", "HEAD"]
                    }
                },
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
echo "🚀 Creating CloudFront distribution..."
DISTRIBUTION_RESULT=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/cf-distribution-config.json \
    --profile ${PROFILE} \
    --output json)

DISTRIBUTION_ID=$(echo ${DISTRIBUTION_RESULT} | jq -r '.Distribution.Id')
CLOUDFRONT_DOMAIN=$(echo ${DISTRIBUTION_RESULT} | jq -r '.Distribution.DomainName')

echo "✅ CloudFront distribution created!"
echo "   Distribution ID: ${DISTRIBUTION_ID}"
echo "   CloudFront Domain: ${CLOUDFRONT_DOMAIN}"

# Step 5: Update bucket policy
echo ""
echo "🔧 Step 5: Updating bucket policy for CloudFront access..."

ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} --query Account --output text)

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
                    "AWS:SourceArn": "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}"
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

# Step 6: Create directory structure and test file
echo ""
echo "📁 Step 6: Creating directory structure..."

# Create directories
for monitor in slack-monitor github-monitor zoom-monitor; do
    aws s3api put-object \
        --bucket ${BUCKET_NAME} \
        --key "binaries/${monitor}/" \
        --profile ${PROFILE} >/dev/null
done

# Create test JSON
cat > /tmp/test-binary.json << EOF
{
  "version": "1.0.0",
  "build_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "saas_app": "Slack",
  "binary_type": "nuitka",
  "binary_size": 1234567,
  "sha256": "test-checksum-placeholder",
  "download_url": "https://${DOMAIN_NAME}/binaries/slack-monitor/watchy-slack-monitor.gz",
  "compression": "gzip",
  "target_architecture": "x86_64",
  "target_os": "linux",
  "lambda_compatible": true,
  "runtime_environment": "amazon-linux-2023"
}
EOF

aws s3 cp /tmp/test-binary.json \
    "s3://${BUCKET_NAME}/binaries/slack-monitor/watchy-slack-monitor.json" \
    --profile ${PROFILE}

echo "✅ Test files uploaded"

# Cleanup
rm -f /tmp/cf-distribution-config.json /tmp/bucket-policy.json /tmp/test-binary.json

echo ""
echo "🎉 Binary Distribution Setup Complete!"
echo "======================================"
echo ""
echo "📊 Summary:"
echo "   S3 Bucket: s3://${BUCKET_NAME}"
echo "   CloudFront ID: ${DISTRIBUTION_ID}"
echo "   CloudFront Domain: ${CLOUDFRONT_DOMAIN}"
echo "   Custom Domain: ${DOMAIN_NAME}"
echo "   SSL Certificate: ${CERT_ARN}"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 🌐 Update DNS: Create CNAME record:"
echo "   ${DOMAIN_NAME} → ${CLOUDFRONT_DOMAIN}"
echo ""
echo "2. 🔧 Update your platform template:"
echo "   BinaryDistributionUrl: https://${DOMAIN_NAME}"
echo ""
echo "3. 📦 Update GitHub Actions to upload to:"
echo "   s3://${BUCKET_NAME}/binaries/"
echo ""
echo "4. ⏳ Wait for distribution deployment (15-20 minutes):"
echo "   aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --profile ${PROFILE} --query 'Distribution.Status'"
echo ""
echo "5. 🧪 Test the distribution:"
echo "   curl -I https://${CLOUDFRONT_DOMAIN}/binaries/slack-monitor/watchy-slack-monitor.json"
echo "   curl -I https://${DOMAIN_NAME}/binaries/slack-monitor/watchy-slack-monitor.json"
echo ""
echo "✅ Infrastructure ready for binary distribution!"
