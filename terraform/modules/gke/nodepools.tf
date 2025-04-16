# Create Node Pool(s) based on the variable definition
resource "google_container_node_pool" "pools" {
  for_each   = { for pool in var.node_pools : pool.name => pool }
  project    = var.project_id
  location   = var.region 
  cluster    = google_container_cluster.primary.name
  name       = each.value.name
  node_count = lookup(each.value, "initial_node_count", 1)

  node_locations = lookup(each.value, "node_locations", [])

  version    = google_container_cluster.primary.master_version

  autoscaling {
    min_node_count = lookup(each.value, "min_node_count", 1)
    max_node_count = lookup(each.value, "max_node_count", 3)
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = lookup(each.value, "machine_type", "e2-medium")
    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")
    preemptible  = lookup(each.value, "preemptible", false)
    spot         = lookup(each.value, "spot", false)

    # Use the dedicated Service Account
    service_account = local.node_sa_email

    # Standard OAuth scopes needed by GKE nodes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" 
    ]

    labels = lookup(each.value, "node_labels", {})
    tags   = lookup(each.value, "node_tags", [])

    resource_labels = {
      "goog-gke-node-pool-provisioning-model" = "on-demand" 
    }

    dynamic "taint" {
      for_each = lookup(each.value, "node_taints", [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  lifecycle {
    ignore_changes = [
      node_locations
    ]
  }

  # Ensure cluster exists first and SA roles are bound
  depends_on = [
    google_container_cluster.primary,
    google_project_iam_member.node_sa_monitoring_viewer,
    google_project_iam_member.node_sa_logging_writer,
    google_project_iam_member.node_sa_storage_object_viewer,
    google_project_iam_member.node_sa_artifactregistry_reader,
  ]
}