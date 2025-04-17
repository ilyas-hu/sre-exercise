# Setup Required (Using Service Account Key)
## Create GCP Service Account: 
Create a Google Service Account your GCP project that Terraform will use.

Grant GSA Permissions: Assign sufficient IAM roles to this GSA in GCP to manage all the resources defined in Terraform code (GKE Admin, Compute Network Admin, Cloud SQL Admin, Service Account Admin, IAM Role Admin, Artifact Registry Admin, Service Usage Admin ) AND permission to write to the GCS bucket (roles/storage.objectAdmin on the bucket).

Create Service Account Key: Generate a JSON key file for this GSA. Download the JSON key file.

Configure The following GitHub Secret and variable:

GCP_SA_KEY = content of the downloaded JSON key file.

TF_OUTPUT_BUCKET (Secret): The name of the GCS bucket used for both state and outputs.

TF_OUTPUT_PATH (Variable): The path within the bucket where the output file should be stored (e.g., tf-outputs/birthday-app/outputs.json).

