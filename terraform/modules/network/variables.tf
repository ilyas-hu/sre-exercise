variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "network_name" {
  description = "Name for the VPC network"
  type        = string
}

variable "gke_subnet_name" {
  description = "The name for the GKE subnet."
  type        = string
}

variable "gke_subnet_ip_cidr_range" {
  description = "The primary IP range for the GKE subnet (for nodes)."
  type        = string
}

variable "proxy_subnet_name" {
  description = "The name for the GKE subnet."
  type        = string
  default     = "gke-proxy-only-subnet"
}

variable "proxy_subnet_ip_cidr_range" {
  description = "The primary IP range for the GKE subnet (for nodes)."
  type        = string
  default     = "10.40.0.0/24"
}

variable "gke_pods_ip_cidr_range_name" {
  description = "The name for the GKE Pods secondary IP range."
  type        = string
}

variable "gke_pods_ip_cidr_range" {
  description = "The secondary IP range for GKE Pods."
  type        = string
}

variable "gke_services_ip_cidr_range_name" {
  description = "The name for the GKE Services secondary IP range."
  type        = string
}

variable "gke_services_ip_cidr_range" {
  description = "The secondary IP range for GKE Services."
  type        = string
}

variable "psa_ip_cidr_range_name" {
  description = "The name for the Private Service Access IP range."
  type        = string
}

variable "psa_ip_cidr_range" {
  description = "The IP range reserved for Private Service Access (e.g., Cloud SQL private IP). Must be /24 or larger for Cloud SQL."
  type        = string
}