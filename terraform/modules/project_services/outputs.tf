output "enabled_service_apis" {
  description = "List of APIs enabled by this module."
  value = keys(google_project_service.enabled_apis)
}
