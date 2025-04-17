# Setup Required (Using Service Account Key)

## Create GCP Service Account: 
Create a Google Service Account in GCP project that will be used by terraform. Grant the service account necessary Permissions to manage all the resources defined in Terraform code (GKE Admin, Compute Network Admin, Cloud SQL Admin, Service Account Admin, IAM Role Admin, Artifact Registry Admin, Service Usage Admin ) and permission to write to the GCS bucket (roles/storage.objectAdmin on the bucket).

Create Service Account Key: Generate and download the JSON key file.

## GitHub Secrets:

GCP_SA_KEY: Content of the downloaded JSON key file.

TF_OUTPUT_BUCKET: The name of the GCS bucket for state file and outputs.

## GitHub Variables:

GCP_PROJECT_ID: Your Google Cloud Project ID.

TF_OUTPUT_PATH: Path within the bucket for the output file (e.g., tf-outputs/birthday-app/outputs.json).

