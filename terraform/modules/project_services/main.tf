resource "google_project_service" "enabled_apis" {
  # Loop over the list of APIs to enable
  for_each = toset(var.apis_list)
  project                    = var.project_id
  service                    = each.key 
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_services_on_destroy 
}
