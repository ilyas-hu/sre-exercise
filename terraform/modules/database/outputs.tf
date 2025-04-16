output "instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = google_sql_database_instance.instance.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance (used by Cloud SQL Proxy)."
  value       = google_sql_database_instance.instance.connection_name
}

output "instance_private_ip_address" {
  description = "The private IP address assigned to the Cloud SQL instance."
  value       = google_sql_database_instance.instance.private_ip_address
  sensitive   = true # IP can be considered sensitive
}

output "instance_self_link" {
  description = "The self-link of the Cloud SQL instance."
  value       = google_sql_database_instance.instance.self_link
}

output "initial_database_name" {
  description = "Name of the initial database created (if applicable)."
  value       = google_sql_database.initial_db.name
}

output "iam_user_name" {
  description = "The name of the initial IAM user created (the GSA email)."
  value       = google_sql_user.iam_app_user.name
}
