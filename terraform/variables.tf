variable "project_id" {
  description = "The GCP project ID where all infra will be deployed"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
}

variable "project_services_to_enable" {
  description = "List of Google Cloud APIs required for the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",         # GCE (for VPC, Firewall, GKE nodes)
    "servicenetworking.googleapis.com", # For PSA Peering Connection
    "sqladmin.googleapis.com",
    "container.googleapis.com",       # GKE Cluster, Node Pools
    "iam.googleapis.com",             # Service Account creation
    "iamcredentials.googleapis.com",  # Workload Identity token generation
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com", 
  ]
}

variable "network_name" {
  description = "The name for the VPC network"
  type        = string
  default     = "hello-app-vpc"
}

variable "db_instance_name" {
  description = "The name for the Cloud SQL PostgreSQL instance."
  type        = string
  default     = "hello-app-db-instance"
}

variable "db_initial_database_name" {
  description = "Name for the initial database."
  type        = string
  default     = "hello_app"
}

variable "db_app_gsa_name" {
  description = "Name of the Service Account for Cloud SQL"
  type        = string
  default     = "hello-app-user"
}

variable "db_database_flags" {
  description = "Database flags for Cloud SQL."
  type        = list(object({ name = string, value = string }))
  default = [
    { name = "cloudsql.iam_authentication", value = "on" }
  ]
}

variable "gke_cluster_name" {
  description = "The name for the GKE cluster."
  type        = string
  default     = "hello-app-cluster"
}

variable "gke_master_authorized_cidr_block" {
  description = "The CIDR block authorized to access the GKE master endpoint."
  type        = string
}

variable "gke_master_authorized_display_name" {
  description = "Display name for the GKE master authorized network."
  type        = string
  default     = "Management Access"
}

variable "gke_node_pools" {
  description = "Configuration for GKE node pools."
  type = list(object({
    name                 = string
    machine_type         = optional(string, "e2-medium")
    disk_size_gb         = optional(number, 100)
    disk_type            = optional(string, "pd-standard")
    initial_node_count   = optional(number, 1)
    min_node_count       = optional(number, 1)
    max_node_count       = optional(number, 3)
    preemptible          = optional(bool, false)
    spot                 = optional(bool, false)
    node_locations       = optional(list(string), [])
    node_labels          = optional(map(string), {})
    node_tags            = optional(list(string), [])
    node_taints = optional(list(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE
    })), [])
  }))
  default = [
    {
      # Provide explicit defaults matching the 'optional' defaults above
      name           = "default-pool"
      machine_type   = "e2-medium"
      disk_size_gb   = 100
      disk_type      = "pd-standard"
      initial_node_count = 1
      min_node_count = 1
      max_node_count = 3
      preemptible    = false
      spot           = false
      node_locations = []
      node_labels    = {
        "workload-type" = "general"
      }
      node_tags      = []
      node_taints    = []
    }
  ]
}

variable "vpc_gke_subnet_cidr" {
  description = "The primary IP CIDR range for the GKE subnet."
  type        = string
  default     = "10.1.0.0/24"
}

variable "vpc_gke_subnet_name" {
  description = "The primary IP CIDR range for the GKE subnet."
  type        = string
  default     = "hello-app-gke-subnet"
}

variable "vpc_psa_cidr" {
  description = "The IP CIDR range reserved for Private Service Access (e.g., Cloud SQL)."
  type        = string
  default     = "10.2.0.0/24"
}

variable "vpc_psa_range_name" {
  description = "The name for the Private Service Access IP range."
  type        = string
  default     = "psa-range"
}

variable "vpc_gke_pods_cidr" {
  description = "The secondary IP CIDR range for GKE Pods."
  type        = string
  default     = "10.20.0.0/20"
}

variable "vpc_gke_pods_range_name" {
  description = "The name for the GKE Pods secondary IP range."
  type        = string
  default     = "gke-pods-range"
}

variable "vpc_gke_services_cidr" {
  description = "The secondary IP CIDR range for GKE Services."
  type        = string
  default     = "10.30.0.0/20"
}

variable "vpc_gke_services_range_name" {
  description = "The name for the GKE Services secondary IP range."
  type        = string
  default     = "gke-services-range"
}

variable "gke_kubernetes_version" {
  description = "Desired Kubernetes version for the GKE cluster control plane and nodes."
  type        = string
  default     = "1.32"
}
