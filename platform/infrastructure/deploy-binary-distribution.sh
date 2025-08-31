#!/bin/bash

# DEPRECATED: Deploy Watchy Binary Distribution Infrastructure
# This functionality is now handled by GitHub Actions

echo "⚠️  DEPRECATED: Infrastructure deployment is now handled by GitHub Actions"
echo ""
echo "🚀 Infrastructure is deployed automatically via GitHub Actions:"
echo ""
echo "📋 Automatic Deployment:"
echo "  • Infrastructure deploys when you push to main branch"
echo "  • CloudFormation templates are validated on every PR"
echo ""
echo "📋 Manual Infrastructure Deployment:"
echo "  1. Go to: https://github.com/cloudbennett/watchy.cloud/actions"
echo "  2. Select: 'Complete CI/CD Pipeline'"
echo "  3. Click: 'Run workflow'"
echo "  4. Infrastructure will deploy as part of the pipeline"
echo ""
echo "🏗️ This script deployed:"
echo "  • CloudFront distribution (releases.watchy.cloud)"
echo "  • S3 bucket for binary hosting"
echo "  • SSL certificate integration"
echo "  • CDN caching rules"
echo ""
echo "❌ Local infrastructure deployment is disabled"
echo "✅ Use GitHub Actions for consistent, auditable deployments"

exit 1
    echo "Please configure AWS CLI with: aws configure --profile watchy"
    exit 1
fi

# Check if certificate exists (this is required for CloudFront)
echo -e "${YELLOW}🔍 Checking for SSL certificate...${NC}"
CERT_ARN=$(aws acm list-certificates --profile watchy --region us-east-1 \
    --query "CertificateList[?DomainName=='*.watchy.cloud' || DomainName=='watchy.cloud'].CertificateArn" \
    --output text 2>/dev/null || echo "")

if [ -z "$CERT_ARN" ]; then
    echo -e "${RED}❌ No SSL certificate found for *.watchy.cloud or watchy.cloud in us-east-1${NC}"
    echo ""
    echo "You need to create an SSL certificate in us-east-1 for CloudFront:"
    echo ""
    echo "1. Go to AWS Certificate Manager in us-east-1 region"
    echo "2. Request a certificate for *.watchy.cloud"
    echo "3. Validate the certificate"
    echo "4. Come back and run this script again"
    echo ""
    echo "Or create it via CLI:"
    echo "aws acm request-certificate --domain-name '*.watchy.cloud' --validation-method DNS --profile watchy --region us-east-1"
    exit 1
fi

echo -e "${GREEN}✅ Found SSL certificate: ${CERT_ARN}${NC}"

# Check if the stack already exists
STACK_EXISTS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --profile watchy 2>/dev/null && echo "true" || echo "false")

if [ "$STACK_EXISTS" = "true" ]; then
    echo -e "${YELLOW}📦 Updating existing stack...${NC}"
    OPERATION="update-stack"
else
    echo -e "${YELLOW}📦 Creating new stack...${NC}"
    OPERATION="create-stack"
fi

# Deploy the stack
echo -e "${BLUE}🔨 Deploying CloudFormation template...${NC}"
aws cloudformation ${OPERATION} \
    --stack-name ${STACK_NAME} \
    --template-body file://${TEMPLATE_FILE} \
    --parameters \
        ParameterKey=DomainName,ParameterValue=${DOMAIN_NAME} \
        ParameterKey=CertificateArn,ParameterValue=${CERT_ARN} \
        ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
    --capabilities CAPABILITY_IAM \
    --profile watchy

# Wait for stack completion
echo -e "${YELLOW}⏳ Waiting for stack deployment to complete...${NC}"
aws cloudformation wait stack-${OPERATION%-stack}-complete \
    --stack-name ${STACK_NAME} \
    --profile watchy

# Get stack outputs
echo -e "${GREEN}✅ Stack deployment completed!${NC}"
echo ""
echo -e "${BLUE}📊 Stack Outputs:${NC}"
aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --profile watchy \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

# Get specific values for next steps
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --profile watchy \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --profile watchy \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --profile watchy \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionDomainName`].OutputValue' \
    --output text)

echo ""
echo -e "${GREEN}🎉 Binary Distribution Infrastructure Created!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📦 S3 Bucket:${NC} ${BUCKET_NAME}"
echo -e "${BLUE}🌐 CloudFront ID:${NC} ${DISTRIBUTION_ID}"
echo -e "${BLUE}🔗 CloudFront Domain:${NC} ${CLOUDFRONT_DOMAIN}"
echo -e "${BLUE}🎯 Custom Domain:${NC} ${DOMAIN_NAME}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. ${BLUE}Update DNS:${NC} Create a CNAME record for ${DOMAIN_NAME} pointing to:"
echo "   ${CLOUDFRONT_DOMAIN}"
echo ""
echo "2. ${BLUE}Test the setup:${NC}"
echo "   curl -I https://${DOMAIN_NAME}"
echo ""
echo "3. ${BLUE}Update your platform template:${NC} Set BinaryDistributionUrl to:"
echo "   https://${DOMAIN_NAME}"
echo ""
echo "4. ${BLUE}Build and upload binaries:${NC}"
echo "   cd platform/binaries && ./build-all.sh"
echo ""
echo "5. ${BLUE}GitHub Actions will upload to:${NC} s3://${BUCKET_NAME}/binaries/"
echo ""
echo -e "${GREEN}✅ Infrastructure ready for binary distribution!${NC}"

# Test if domain is accessible
echo ""
echo -e "${YELLOW}🧪 Testing CloudFront distribution...${NC}"
if curl -f -s -I "https://${CLOUDFRONT_DOMAIN}" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ CloudFront distribution is accessible${NC}"
else
    echo -e "${YELLOW}⏳ CloudFront distribution is still deploying (this can take 15-20 minutes)${NC}"
fi
