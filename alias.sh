#!/bin/bash
export AWS_PAGER=""

if [ "$#" -lt 4 ]; then
  echo "Usage: ./alias.sh <lambda_function_name> <alias_name> <version_number> <region>"
  exit 1
fi

LAMBDA_NAME="$1"
ALIAS_NAME="$2"
VERSION="$3"
REGION="$4"

ALIAS_EXISTS=$(aws lambda get-alias \
  --function-name "$LAMBDA_NAME" \
  --name "$ALIAS_NAME" \
  --region "$REGION" \
  --query 'Name' \
  --output text 2>/dev/null)

if [ "$ALIAS_EXISTS" == "$ALIAS_NAME" ]; then
  echo "Updating alias '$ALIAS_NAME' to version $VERSION..."
  aws lambda update-alias \
    --function-name "$LAMBDA_NAME" \
    --name "$ALIAS_NAME" \
    --function-version "$VERSION" \
    --region "$REGION" \
    --description "Updated alias $ALIAS_NAME to version $VERSION"
else
  echo "Creating alias '$ALIAS_NAME' for version $VERSION..."
  aws lambda create-alias \
    --function-name "$LAMBDA_NAME" \
    --name "$ALIAS_NAME" \
    --function-version "$VERSION" \
    --region "$REGION" \
    --description "Created alias $ALIAS_NAME for version $VERSION"
fi
