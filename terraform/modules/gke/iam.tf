resource "google_service_account" "node_service_account" {
  count        = var.node_service_account_email == null ? 1 : 0
  project      = var.project_id
  account_id   = "${var.cluster_name}-nodesa"
  display_name = "GKE Node Service Account for ${var.cluster_name}"
}

locals {
   node_sa_email = var.node_service_account_email == null ? google_service_account.node_service_account[0].email : var.node_service_account_email
}

# Grant necessary roles to the Node Service Account
resource "google_project_iam_member" "node_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${local.node_sa_email}"
}

resource "google_project_iam_member" "node_sa_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.node_sa_email}"
}

resource "google_project_iam_member" "node_sa_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.node_sa_email}"
}

resource "google_project_iam_member" "node_sa_artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.node_sa_email}"
}
