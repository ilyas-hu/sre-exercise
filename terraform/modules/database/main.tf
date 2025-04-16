# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"
    disk_autoresize   = true
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled    = false # Disable Public IP
      private_network = var.network_id
    }

    backup_configuration {
      enabled                        = var.enable_backups
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_pitr
    }

    maintenance_window {
      day  = var.maintenance_window_day
      hour = var.maintenance_window_hour
    }

    dynamic "database_flags" {
      for_each = var.db_database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
  }
}

# Optional: Create an initial database
resource "google_sql_database" "initial_db" {
  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
}

# Create a service account
resource "google_service_account" "sql_service_account" {
  project      = var.project_id
  account_id   = "${var.app_gsa_name}-sqlsa"
  display_name = "Service Account for SQL"
}

locals {
   sql_sa_email = google_service_account.sql_service_account.email
   sql_sa_name  = split("@", local.sql_sa_email)[0]
}

# Create an IAM Service Account user in Cloud SQL
resource "google_sql_user" "iam_app_user" {
  project  = var.project_id
  name     = trimsuffix(local.sql_sa_email, ".gserviceaccount.com")
  instance = google_sql_database_instance.instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"

  depends_on = [
    google_sql_database_instance.instance,
    google_service_account.sql_service_account,
  ]
}

# Grant the App GSA the Cloud SQL Instance User role on the instance
resource "google_project_iam_member" "app_user_iam" {
  project  = var.project_id
  role     = "roles/cloudsql.instanceUser"
  member   = "serviceAccount:${local.sql_sa_email}"
  depends_on = [
    google_service_account.sql_service_account,
  ]
}

# Grant roles/cloudsql.client to the App GSA
resource "google_project_iam_member" "app_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${local.sql_sa_email}"
  depends_on = [
    google_service_account.sql_service_account,
  ]
}

# Bind KSA to GSA for Workload Identity impersonation
resource "google_service_account_iam_member" "ksa_workload_identity_user" {
  service_account_id = google_service_account.sql_service_account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[birthday-app-ns/birthday-app-sa]"
}
