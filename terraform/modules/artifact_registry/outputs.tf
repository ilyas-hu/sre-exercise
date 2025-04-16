output "repository_id" {
  description = "The ID (name) of the created Artifact Registry repository."
  value       = google_artifact_registry_repository.repository.repository_id
}

output "repository_name" {
  description = "The full name of the repository resource."
  value       = google_artifact_registry_repository.repository.name
}

output "repository_url" {
  description = "The full URL of the repository, used for docker login/push/pull."
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_id}"
}
