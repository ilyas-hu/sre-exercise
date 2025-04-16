#!/bin/bash

set -e

# === Configuration ===
# Directory containing the original Kubernetes manifest templates
K8S_TEMPLATE_DIR="./k8s"
# Directory where the processed manifests will be written
K8S_OUTPUT_DIR="./k8s_processed"
# Terraform output file (JSON format)
TF_OUTPUT_FILE="tf_outputs.json"
# Default Image Tag (can be overridden by command line argument)
DEFAULT_IMAGE_TAG="latest"

# === Get Image Tag from Argument ===
# Use provided tag or default to 'latest'
IMAGE_TAG="${1:-$DEFAULT_IMAGE_TAG}"
echo "Using Image Tag: $IMAGE_TAG"

# === Get Terraform Outputs ===
echo "Fetching Terraform outputs..."
# Run from the terraform directory
(cd ../terraform && terraform output -json > ../birthday-app/"$TF_OUTPUT_FILE")
echo "Terraform outputs saved to $TF_OUTPUT_FILE"

# === Check for jq ===
if ! command -v jq &> /dev/null
then
    echo "Error: jq is not installed. Please install jq for parsing Terraform outputs."
    exit 1
fi

# === Extract Values from Terraform Output ===
echo "Extracting values from Terraform output..."
PROJECT_ID=$(jq -e -r '.project_id.value' "$TF_OUTPUT_FILE")
GSA_EMAIL=$(jq -e -r '.app_gsa_email.value' "$TF_OUTPUT_FILE")
SQL_INSTANCE_CONNECTION_NAME=$(jq -e -r '.instance_connection_name.value' "$TF_OUTPUT_FILE")
SQL_DB_NAME=$(jq -e -r '.database_name.value' "$TF_OUTPUT_FILE")
AR_REPO_URL=$(jq -e -r '.artifact_registry_repo_url.value' "$TF_OUTPUT_FILE")

# Check if extraction was successful
if [ -z "$PROJECT_ID" ] || [ -z "$GSA_EMAIL" ] || [ -z "$SQL_INSTANCE_CONNECTION_NAME" ] || [ -z "$SQL_DB_NAME" ] || [ -z "$AR_REPO_URL" ]; then
  echo "Error: Failed to extract one or more required values from $TF_OUTPUT_FILE."
  echo "Ensure Terraform outputs 'project_id', 'app_gsa_email', 'instance_connection_name', 'database_name', and 'artifact_registry_repo_url' are defined in your root module."
  exit 1
fi

# === Construct Full Image Path ===
IMAGE_NAME="birthday-app"
FULL_IMAGE_PATH="${AR_REPO_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "Full Image Path: $FULL_IMAGE_PATH"

# === Prepare Output Directory ===
echo "Preparing output directory: $K8S_OUTPUT_DIR"
rm -rf "$K8S_OUTPUT_DIR" # Remove old processed files
mkdir -p "$K8S_OUTPUT_DIR"
cp "$K8S_TEMPLATE_DIR"/*.yaml "$K8S_OUTPUT_DIR/" # Copy templates

# === Substitute Placeholders ===
echo "Substituting placeholders..."
SED_CMD="sed -i.bak" # Use -i for in-place edit, .bak creates backup

# --- Service Account ---
$SED_CMD "s#__GSA_EMAIL__#${GSA_EMAIL}#g" "${K8S_OUTPUT_DIR}/serviceaccount.yaml"

# --- ConfigMap ---
$SED_CMD "s#__SQL_INSTANCE_CONNECTION_NAME__#${SQL_INSTANCE_CONNECTION_NAME}#g" "${K8S_OUTPUT_DIR}/configmap.yaml"
$SED_CMD "s#__GSA_EMAIL__#${GSA_EMAIL}#g" "${K8S_OUTPUT_DIR}/configmap.yaml"
$SED_CMD "s#__SQL_DB_NAME__#${SQL_DB_NAME}#g" "${K8S_OUTPUT_DIR}/configmap.yaml"

# --- Deployment ---
$SED_CMD "s#__FULL_IMAGE_PATH__#${FULL_IMAGE_PATH}#g" "${K8S_OUTPUT_DIR}/deployment.yaml"

# --- Clean up backup files ---
find "$K8S_OUTPUT_DIR" -name '*.bak' -delete

echo "Manifests processed and saved in $K8S_OUTPUT_DIR"
echo "You can now apply them using: kubectl apply -f $K8S_OUTPUT_DIR -n birthday-app-ns"

