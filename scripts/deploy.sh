#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export AWS_REGION="${AWS_REGION:-ap-southeast-1}"
export CDK_DEFAULT_REGION="${CDK_DEFAULT_REGION:-ap-southeast-1}"
export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
echo "Checking s3:PutBucketVersioning (required for CDK bootstrap)..."
TEST_BUCKET="cdk-permission-test-${ACCOUNT}-${AWS_REGION}"
if ! aws s3api create-bucket \
  --bucket "$TEST_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null; then
  aws s3api head-bucket --bucket "$TEST_BUCKET" --region "$AWS_REGION" 2>/dev/null || true
fi
if ! aws s3api put-bucket-versioning \
  --bucket "$TEST_BUCKET" \
  --versioning-configuration Status=Enabled \
  --region "$AWS_REGION" 2>/dev/null; then
  echo "ERROR: deployment-user needs s3:PutBucketVersioning (or s3:*)."
  echo "Add iam/cdk-bootstrap-s3-fix.json to your policy, or use iam/deployment-user-policy.json"
  exit 1
fi
aws s3 rb "s3://${TEST_BUCKET}" --force --region "$AWS_REGION" 2>/dev/null || true
echo "S3 bootstrap permission OK."

echo "Bootstrapping CDK..."
npx cdk bootstrap "aws://${ACCOUNT}/${AWS_REGION}"

echo "Building..."
npm run build

echo "Deploying ImgTransformationStack..."
npx cdk deploy --require-approval never

echo "Done. Check outputs: ImageDeliveryDomain, OriginalImagesS3Bucket"
