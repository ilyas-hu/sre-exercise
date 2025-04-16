# Main VPC Network
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false 
}

# Subnet for GKE Cluster
resource "google_compute_subnetwork" "gke_subnet" {
  project                  = var.project_id
  name                     = var.gke_subnet_name
  ip_cidr_range            = var.gke_subnet_ip_cidr_range
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true 

  secondary_ip_range {
    range_name    = var.gke_pods_ip_cidr_range_name
    ip_cidr_range = var.gke_pods_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = var.gke_services_ip_cidr_range_name
    ip_cidr_range = var.gke_services_ip_cidr_range
  }

  depends_on = [google_compute_network.vpc_network]
}

# Reserve IP Range for Private Service Access (Cloud SQL)
resource "google_compute_global_address" "private_service_access_range" {
  project       = var.project_id
  name          = var.psa_ip_cidr_range_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  network       = google_compute_network.vpc_network.id
  address       = split("/", var.psa_ip_cidr_range)[0] # Extract the address part
  prefix_length = tonumber(split("/", var.psa_ip_cidr_range)[1]) # Extract the prefix length

  depends_on = [google_compute_network.vpc_network]
}

# Establish Private Service Access Connection
resource "google_service_networking_connection" "psa_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access_range.name]

  depends_on = [
    google_compute_global_address.private_service_access_range
  ]
}

# Firewall Rule: Allow GKE Pods to Cloud SQL (PostgreSQL Port 5432)
resource "google_compute_firewall" "allow_gke_to_sql" {
  project     = var.project_id
  name        = "${var.network_name}-allow-gke-to-sql"
  network     = google_compute_network.vpc_network.name 
  direction   = "EGRESS"                                
  priority    = 1000 # Standard priority

  # Specify the destination range (Cloud SQL lives here)
  destination_ranges = [var.psa_ip_cidr_range]

  # Specify the source range (GKE Pods live here)
  source_ranges = [var.gke_pods_ip_cidr_range]

  # Define allowed protocol and port
  allow {
    protocol = "tcp"
    ports    = ["5432"] # PostgreSQL port
  }

  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "allow_gke_health_checks" {
  project     = var.project_id
  name        = "${var.network_name}-allow-gke-lb-health-checks"
  network     = google_compute_network.vpc_network.name
  direction   = "INGRESS"
  priority    = 1000

  # Allow traffic from Google Cloud health checkers
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"] 

  # Target GKE nodes (using subnet range)  
  destination_ranges = [var.gke_subnet_ip_cidr_range]

  allow { 
    protocol = "tcp"
    ports    = ["8000", "80"]
  }
}
