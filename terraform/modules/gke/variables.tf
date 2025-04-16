variable "project_id" {
  description = "The GCP project ID where the GKE cluster will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for the GKE cluster (should match the VPC region)."
  type        = string
}

variable "cluster_name" {
  description = "The name for the GKE cluster."
  type        = string
  default     = "gke-cluster"
}

variable "network_id" {
  description = "The self-link of the VPC network to deploy the cluster in."
  type        = string
}

variable "subnet_id" {
  description = "The self-link of the GKE subnet to deploy the cluster in."
  type        = string
}

variable "pods_range_name" {
  description = "The secondary range name for GKE Pods within the subnet."
  type        = string
}

variable "services_range_name" {
  description = "The secondary range name for GKE Services within the subnet."
  type        = string
}

variable "kubernetes_version" {
  description = "The GKE version for the control plane and nodes"
  type        = string
  default     = "1.32"
}

variable "enable_network_policy" {
  description = "Enable Network Policy enforcement"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the cluster."
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Configure GKE nodes with private IPs only."
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Configure the GKE control plane endpoint to be private."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted control plane endpoint (required if enable_private_endpoint is true). Must be a /28 range and not overlap."
  type        = string
  default     = ""
}

variable "master_authorized_networks" {
  description = "List of authorized networks for Kubernetes API server access. Required if enable_private_endpoint is false."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# --- Node Pool Configuration ---
variable "node_pools" {
  description = "A list of objects defining node pools to create."
  type = list(object({
    name           = string
    machine_type   = optional(string, "e2-medium")
    disk_size_gb   = optional(number, 100)
    disk_type      = optional(string, "pd-standard")
    initial_node_count = optional(number, 1)
    min_node_count = optional(number, 1)
    max_node_count = optional(number, 3)
    preemptible    = optional(bool, false) 
    spot           = optional(bool, false)
    node_locations = optional(list(string), [])
    node_labels    = optional(map(string), {})
    node_tags      = optional(list(string), [])
    node_taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = [
    { name = "default-pool" } # Provide at least one default pool config
  ]
}

variable "node_service_account_email" {
  description = "Optional. Email of an existing service account to use for nodes. If null, a dedicated SA will be created."
  type        = string
  default     = null
}
