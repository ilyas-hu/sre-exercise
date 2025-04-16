variable "project_id" {
  description = "The GCP project ID where the Cloud SQL instance will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud SQL instance."
  type        = string
}

variable "instance_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
}

variable "database_version" {
  description = "The PostgreSQL version for the Cloud SQL instance (e.g., POSTGRES_15)."
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "The machine type for the Cloud SQL instance (e.g., db-f1-micro, db-custom-1-3840)."
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size" {
  description = "The size of the database disk in GB."
  type        = number
  default     = 20 
}

variable "disk_type" {
  description = "The type of database disk (PD_SSD or PD_HDD)."
  type        = string
  default     = "PD_SSD"
}

variable "network_id" {
  description = "The self-link of the VPC network to associate the private IP with (output from the network module)."
  type        = string
}

variable "deletion_protection" {
  description = "Whether or not to enable deletion protection for the instance."
  type        = bool
  default     = false 
}

variable "enable_backups" {
  description = "Flag to enable automated backups."
  type        = bool
  default     = true
}

variable "enable_pitr" {
  description = "Flag to enable Point-in-Time Recovery (requires backups and binary logs)."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "The start time for the daily backup window in HH:MM format (UTC)."
  type        = string
  default     = "03:00"
}

variable "database_name" {
  description = "Name for the initial database if create_initial_database is true."
  type        = string
}

variable "app_gsa_name" {
  description = "Name for the Google Service Account used by the application via Workload Identity."
  type        = string
}

variable "db_database_flags" {
  description = "List of database flags to set. MUST include {name = \"cloudsql.iam_authentication\", value = \"on\"} for IAM auth."
  type        = list(object({ name = string, value = string }))
}

variable "maintenance_window_day" {
  description = "The day of week (1-7) for the maintenance window."
  type        = number
  default     = 7 # Sunday
}

variable "maintenance_window_hour" {
  description = "The hour of day (0-23) for the maintenance window (UTC)."
  type        = number
  default     = 4 # 4 AM UTC
}