#!/bin/bash

# Deployment Verification Script
# Verifies that S3 templates are accessible before deploying watchy-platform

set -e

BUCKET_NAME="watchy-resources-prod"
TEMPLATE_PATH="customer-templates/templates"
AWS_PROFILE="watchy"

echo "🔍 Verifying S3 template access (using profile: ${AWS_PROFILE})..."

# Check if bucket exists
if ! aws s3 ls "s3://${BUCKET_NAME}/" --profile "${AWS_PROFILE}" > /dev/null 2>&1; then
    echo "❌ Error: Bucket ${BUCKET_NAME} does not exist or is not accessible"
    echo "   Please deploy the binary-distribution stack first:"
    echo "   aws cloudformation deploy --template-file platform/infrastructure/binary-distribution.yaml --stack-name watchy-binary-distribution --parameter-overrides Environment=prod --profile ${AWS_PROFILE}"
    exit 1
fi

echo "✅ Bucket ${BUCKET_NAME} exists"

# Check if template files exist
TEMPLATES=(
    "watchy-slack-monitoring.yaml"
    "watchy-github-monitoring.yaml" 
    "watchy-zoom-monitoring.yaml"
)

MISSING_TEMPLATES=()

for template in "${TEMPLATES[@]}"; do
    if aws s3 ls "s3://${BUCKET_NAME}/${TEMPLATE_PATH}/${template}" --profile "${AWS_PROFILE}" > /dev/null 2>&1; then
        echo "✅ Template found: ${template}"
    else
        echo "❌ Template missing: ${template}"
        MISSING_TEMPLATES+=("${template}")
    fi
done

if [ ${#MISSING_TEMPLATES[@]} -gt 0 ]; then
    echo
    echo "❌ Missing templates detected. Please sync templates to S3:"
    echo "   • Run GitHub Actions workflow, or"
    echo "   • Manually sync: aws s3 sync customer-templates/ s3://${BUCKET_NAME}/customer-templates/ --delete --profile ${AWS_PROFILE}"
    exit 1
fi

# Test template accessibility
echo
echo "🌐 Testing template URL accessibility..."
TEMPLATE_URL="https://s3.amazonaws.com/${BUCKET_NAME}/${TEMPLATE_PATH}/watchy-slack-monitoring.yaml"

if curl -s --head "${TEMPLATE_URL}" | head -n 1 | grep -q "200 OK"; then
    echo "✅ Template URLs are publicly accessible"
else
    echo "❌ Template URLs are not accessible"
    echo "   URL tested: ${TEMPLATE_URL}"
    echo "   Check bucket policy permissions"
    exit 1
fi

echo
echo "🚀 All verifications passed! Ready to deploy watchy-platform stack"
echo
echo "Deploy command:"
echo "aws cloudformation deploy \\"
echo "  --template-file platform/watchy-platform.yaml \\"
echo "  --stack-name watchy-platform \\"
echo "  --capabilities CAPABILITY_NAMED_IAM \\"
echo "  --profile ${AWS_PROFILE}"
