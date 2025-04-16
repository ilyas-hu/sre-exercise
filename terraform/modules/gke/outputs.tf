output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_location" {
  description = "The location (region) of the GKE cluster."
  value       = google_container_cluster.primary.location
}

output "cluster_endpoint" {
  description = "The public or private endpoint of the GKE cluster control plane."
  value       = var.enable_private_endpoint ? google_container_cluster.primary.private_cluster_config[0].private_endpoint : google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The base64 encoded CA certificate for the GKE cluster."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "node_pools_names" {
  description = "A list of the names of the created node pools."
  value       = [for pool in google_container_node_pool.pools : pool.name]
}

output "node_service_account_email" {
  description = "The email address of the service account used by the GKE nodes."
  value       = local.node_sa_email
}

output "workload_identity_pool" {
  description = "The Workload Identity Pool associated with the cluster."
  value       = "${var.project_id}.svc.id.goog"
}

