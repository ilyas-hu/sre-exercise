terraform {
  required_version = "~> 1.11.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }
  backend "gcs" { 
    # Configuration must be passed via -backend-config during init
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required Project Services/APIs first
module "project_services" {
  source = "./modules/project_services"

  project_id    = var.project_id
  apis_list = var.project_services_to_enable
  disable_services_on_destroy = false 
}

module "vpc_network" {
  source       = "./modules/network"
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name

  gke_subnet_name          = var.vpc_gke_subnet_name
  gke_subnet_ip_cidr_range = var.vpc_gke_subnet_cidr
  psa_ip_cidr_range        = var.vpc_psa_cidr
  gke_pods_ip_cidr_range   = var.vpc_gke_pods_cidr
  gke_pods_ip_cidr_range_name = var.vpc_gke_pods_range_name
  gke_services_ip_cidr_range = var.vpc_gke_services_cidr
  gke_services_ip_cidr_range_name = var.vpc_gke_services_range_name
  psa_ip_cidr_range_name = var.vpc_psa_range_name

  depends_on = [ 
    module.project_services 
  ]
}

module "postgres_db" {
  source = "./modules/database" 

  project_id     = var.project_id
  region         = var.region
  instance_name  = var.db_instance_name
  network_id     = module.vpc_network.network_id

  app_gsa_name   = var.db_app_gsa_name
  database_name  = var.db_initial_database_name
  db_database_flags = var.db_database_flags

  depends_on = [ 
    module.project_services,
    module.vpc_network
  ]
}

module "gke_cluster" {
  source = "./modules/gke"

  project_id = var.project_id
  region     = var.region 

  cluster_name = var.gke_cluster_name

  network_id          = module.vpc_network.network_id
  subnet_id           = module.vpc_network.gke_subnet_id
  pods_range_name     = module.vpc_network.gke_pods_ip_cidr_range_name
  services_range_name = module.vpc_network.gke_services_ip_cidr_range_name

  master_authorized_networks = [
    {
      cidr_block   = var.gke_master_authorized_cidr_block
      display_name = var.gke_master_authorized_display_name
    }
  ]

  node_pools = var.gke_node_pools

  depends_on = [ 
    module.project_services,
    module.vpc_network,
    module.postgres_db
  ]
}

module "docker_repo" {
  source = "./modules/artifact_registry" 

  project_id    = var.project_id
  location      = var.region
  repository_id = "hello-app-repo"
  description   = "Docker images for the Birthday App"

  depends_on = [ 
    module.project_services
  ]
}
