#!/bin/bash
#set -e

# === CONFIG FALLBACK ===

CONFIG_FILE="./config.yml"

if [[ $# -eq 4 ]]; then
    LAMBDA_FUNCTION="$1"
    ENVIRONMENT="$2"
    TRAFFIC_PERCENT="$3"
    DURATION_MINUTES="$4"
else
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: No arguments provided and config.yml not found."
        echo "Usage: $0 <lambda_function_name> <environment> <traffic_percentage> <duration_in_minutes>"
        exit 1
    fi

    if ! command -v yq &> /dev/null; then
        echo "ERROR: yq is not installed. Please install yq to use config fallback."
        exit 1
    fi

    echo "No CLI args provided — loading config from $CONFIG_FILE"
    LAMBDA_FUNCTION=$(yq '.lambda_function' "$CONFIG_FILE")
    ENVIRONMENT=$(yq '.environment' "$CONFIG_FILE")
    TRAFFIC_PERCENT=$(yq '.traffic_percentage' "$CONFIG_FILE")
    DURATION_MINUTES=$(yq '.duration_minutes' "$CONFIG_FILE")
    REGION=$(yq '.region' "$CONFIG_FILE")
    REPO_URL=$(yq '.repo_url' "$CONFIG_FILE")                     # NEW
    BRANCH=$(yq '.branch // "main"' "$CONFIG_FILE")              # NEW (optional)
fi

# === Validate Required Fields ===
if [[ -z "$LAMBDA_FUNCTION" || -z "$ENVIRONMENT" || -z "$TRAFFIC_PERCENT" || -z "$DURATION_MINUTES" ]]; then
    echo "ERROR: Missing one or more required parameters."
    exit 1
fi

# === Log Summary ===
echo "Starting deployment:"
echo "- Lambda:     $LAMBDA_FUNCTION"
echo "- Environment:$ENVIRONMENT"
echo "- Traffic:    $TRAFFIC_PERCENT%"
echo "- Duration:   $DURATION_MINUTES minutes"

# === CLONE & ZIP REPO ===
WORK_DIR="."
ZIP_FILE="deployment_package.zip"

echo "Cloning repository from $REPO_URL (branch: $BRANCH)..."
rm -rf "$WORK_DIR"
git clone --branch "$BRANCH" "$REPO_URL" "$WORK_DIR"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Git clone failed."
    exit 1
fi

echo "Zipping contents..."
## cd "$WORK_DIR" || exit 1
zip -r "../$ZIP_FILE" . > /dev/null
cd - > /dev/null

if [[ ! -f "$ZIP_FILE" ]]; then
    echo "ERROR: Failed to create zip file."
    exit 1
fi

echo "Zip package created: $ZIP_FILE"

# === Upload and Publish Lambda ===
echo "Updating environment variables..."
./envvars.sh "$LAMBDA_FUNCTION" "$ENVIRONMENT"

echo "Configuring VPC..."
./vpc.sh "$LAMBDA_FUNCTION" "$ENVIRONMENT"

echo "Publishing new Lambda version..."
VERSION_OUTPUT=$(./publish.sh "$LAMBDA_FUNCTION" "$ZIP_FILE")   # UPDATED: pass zip file
VERSION=$(echo "$VERSION_OUTPUT" | yq '.Version')

if [[ -z "$VERSION" ]]; then
    echo "Failed to retrieve version number from publish script."
    exit 1
fi

echo "Published version: $VERSION"

echo "Updating alias..."
./alias.sh "$LAMBDA_FUNCTION" "$ENVIRONMENT" "$VERSION" "$REGION"

echo "Shifting traffic: $TRAFFIC_PERCENT% for $DURATION_MINUTES minutes..."
WEIGHT=$(awk "BEGIN { print $TRAFFIC_PERCENT / 100 }")
./route.sh "$LAMBDA_FUNCTION" "$ENVIRONMENT" "$VERSION" "$WEIGHT" "$REGION"

echo "Deployment complete for $LAMBDA_FUNCTION (version $VERSION)"

# === CLEANUP ===
echo "Cleaning up build files..."
rm -rf "$WORK_DIR" "$ZIP_FILE"
