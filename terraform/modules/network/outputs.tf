output "network_id" {
  description = "The self-link of the VPC network."
  value       = google_compute_network.vpc_network.id
}

output "network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.vpc_network.name
}

output "gke_subnet_id" {
  description = "The self-link of the GKE subnet."
  value       = google_compute_subnetwork.gke_subnet.id
}

output "gke_subnet_name" {
  description = "The name of the GKE subnet."
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_region" {
  description = "The region of the GKE subnet."
  value       = google_compute_subnetwork.gke_subnet.region
}

output "gke_pods_ip_cidr_range_name" {
  description = "The secondary range name for GKE Pods."
  value       = var.gke_pods_ip_cidr_range_name
}

output "gke_services_ip_cidr_range_name" {
  description = "The secondary range name for GKE Services."
  value       = var.gke_services_ip_cidr_range_name
}

