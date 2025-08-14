#!/bin/bash
export AWS_PAGER=""
    
if [ -z "$1" ]; then
  echo "Usage: ./publish.sh <lambda_function_name>"
  exit 1
fi

LAMBDA_NAME="$1"

aws lambda publish-version --function-name "$LAMBDA_NAME"

exit 0
