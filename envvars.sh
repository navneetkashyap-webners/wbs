#!/bin/bash
export AWS_PAGER=""

if [ "$#" -lt 2 ]; then
  echo "Usage: ./envvars.sh <lambda_function_name> <environment=prod|dev>"
  exit 1
fi

LAMBDA_NAME="$1"
ENVIRONMENT="$2"

# Source the shared environment variable config logic
source ./lambda-env-config.sh

# Call the logic to populate ENV_VARS
set_lambda_env_vars "$LAMBDA_NAME" "$ENVIRONMENT"
if [ $? -ne 0 ]; then
  echo "Failed to set environment variables."
  exit 1
fi

echo " Updating environment variables for $LAMBDA_NAME in $ENVIRONMENT environment..."
aws lambda update-function-configuration \
  --function-name "$LAMBDA_NAME" \
  --environment "$ENV_VARS"

exit 0
