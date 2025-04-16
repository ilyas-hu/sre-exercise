
variable "project_id" {
  description = "The GCP project ID where services will be enabled."
  type        = string
}

variable "apis_list" {
  description = "A list of Google Cloud APIs to enable (e.g., ['compute.googleapis.com', 'sqladmin.googleapis.com'])."
  type        = list(string)
  default     = []
}

variable "disable_services_on_destroy" {
  description = "Whether to disable the services when the resources are destroyed. Defaults to false."
  type        = bool
  default     = false
}
