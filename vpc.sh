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

aws lambda update-function-configuration \
  --function-name "$LAMBDA_NAME" \
  --vpc-config SubnetIds=$SUBNETS,SecurityGroupIds=$SEC_GROUPS

exit 0
