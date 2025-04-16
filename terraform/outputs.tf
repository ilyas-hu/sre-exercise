output "db_instance_connection_name" {
  description = "The connection name for the Cloud SQL database instance."
  value       = module.postgres_db.instance_connection_name
}

output "network_name" {
  description = "The name of the VPC network created."
  value       = module.vpc_network.network_name
}

output "gke_cluster_name" {
  description = "The name of the created GKE cluster."
  value       = module.gke_cluster.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster control plane."
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The base64 encoded CA certificate for the GKE cluster."
  value       = module.gke_cluster.cluster_ca_certificate
  sensitive   = true
}

output "repository_url" {
  description = "The full URL of the repository, used for docker login/push/pull."
  value       = module.docker_repo.repository_url
}  
