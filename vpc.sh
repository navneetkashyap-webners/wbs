#!/bin/bash
export AWS_PAGER=""

if [ "$#" -lt 2 ]; then
  echo "Usage: ./vpc.sh <lambda_function_name> <environment=prod|dev>"
  exit 1
fi

LAMBDA_NAME="$1"
ENVIRONMENT="$2"

if [ "$ENVIRONMENT" == "prod" ]; then
  SUBNETS="subnet-0d929a68ce19ad1c7"
  SEC_GROUPS="sg-029668d231d090f15"
elif [ "$ENVIRONMENT" == "dev" ]; then
  SUBNETS="subnet-5aa2b22c"
  SEC_GROUPS="sg-0759b55b0464beb0a"
else
  echo "Invalid environment: $ENVIRONMENT"
  exit 1
fi

echo "Configuring VPC..."

# Retry logic for handling ResourceConflictException
for i in {1..10}; do
  aws lambda update-function-configuration \
    --function-name "$LAMBDA_NAME" \
    --vpc-config SubnetIds=$SUBNETS,SecurityGroupIds=$SEC_GROUPS && break

  echo "Update in progress, retrying in $((i * 5)) seconds..."
  sleep $((i * 5))
done

echo "Waiting for function update to complete..."
aws lambda wait function-updated --function-name "$LAMBDA_NAME"

echo "Publishing new Lambda version..."
VERSION=$(aws lambda publish-version \
  --function-name "$LAMBDA_NAME" \
  --query 'Version' \
  --output text)

if [[ -z "$VERSION" || "$VERSION" == "None" ]]; then
  echo "Failed to publish version. Exiting."
  exit 1
fi

echo "Published version: $VERSION"

echo "Updating alias..."
aws lambda update-alias \
  --function-name "$LAMBDA_NAME" \
  --name "$ENVIRONMENT" \
  --function-version "$VERSION"

echo "Alias '$ENVIRONMENT' updated to version $VERSION"
