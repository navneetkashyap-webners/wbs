#!/bin/bash

# Define ENV_VARS in a format compatible with aws cli:
#   --environment "Variables={KEY1=value1,KEY2=value2}"

function set_lambda_env_vars() {
  local function_name="$1"
  local env="$2"

  if [[ "$env" == "prod" ]]; then
    ENV_VARS="Variables={ENV=prod,DEBUG=false}"
  elif [[ "$env" == "staging" ]]; then
    ENV_VARS="Variables={ENV=staging,DEBUG=true}"
  elif [[ "$env" == "dev" ]]; then
    ENV_VARS="Variables={ENV=dev,DEBUG=true}"
  else
    echo "Unknown environment: $env"
    return 1
  fi

  return 0
}
