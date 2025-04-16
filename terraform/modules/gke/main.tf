# GKE Cluster Resource
resource "google_container_cluster" "primary" {
  project    = var.project_id
  name       = var.cluster_name
  location   = var.region
  min_master_version = var.kubernetes_version
  initial_node_count = 1 

  remove_default_node_pool = true

  # --- Networking ---
  network    = var.network_id
  subnetwork = var.subnet_id
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  network_policy {
    enabled = var.enable_network_policy
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_endpoint ? var.master_ipv4_cidr_block : null
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      # Only configure if private endpoint is FALSE and networks are provided
      for_each = !var.enable_private_endpoint && length(var.master_authorized_networks) > 0 ? var.master_authorized_networks : []
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # --- Security ---
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  gateway_api_config {
    # Enable the standard GKE Gateway controller
    channel = "CHANNEL_STANDARD"
  }

  # Lifecycle rule to prevent accidental deletion if default pool is removed later
  lifecycle {
    ignore_changes = [
      node_pool, # Ignore changes to the default node pool as we manage our own
      initial_node_count,
    ]
  }
}