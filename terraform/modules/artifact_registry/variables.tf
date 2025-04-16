variable "project_id" {
  description = "The GCP project ID where the Artifact Registry repository will be created."
  type        = string
}

variable "location" {
  description = "The GCP region for the Artifact Registry repository."
  type        = string
}

variable "repository_id" {
  description = "The desired ID (name) for the Artifact Registry repository."
  type        = string
}

variable "description" {
  description = "Optional description for the repository."
  type        = string
  default     = "Docker image repository"
}
