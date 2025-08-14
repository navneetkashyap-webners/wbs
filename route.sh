#!/bin/bash
export AWS_PAGER=""

if [ "$#" -lt 5 ]; then
  echo "Usage: ./route.sh <lambda_function_name> <alias_name> <new_version> <weight (0.0 - 1.0)> <region>"
  exit 1
fi

LAMBDA_NAME="$1"
ALIAS_NAME="$2"
NEW_VERSION="$3"
WEIGHT="$4"
REGION="$5"

echo "Routing $WEIGHT of traffic to version $NEW_VERSION..."

aws lambda update-alias \
  --function-name "$LAMBDA_NAME" \
  --name "$ALIAS_NAME" \
  --region "$REGION" \
  --routing-config "{\"AdditionalVersionWeights\": {\"$NEW_VERSION\": $WEIGHT}}"
