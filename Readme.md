# SRE Exercise - Birthday Greeting Application

## Problem Statement

This project implements a simple HTTP API service that stores users' dates of birth and returns a message indicating how many days are left until their next birthday, or a happy birthday message. The goal is to design, build, test, and create an automated deployment for this service on Google Cloud Platform (GCP), following Site Reliability Engineering (SRE) best practices.

## Solution Overview & Architecture

The solution consists of:

1.  **Application:** A Python web application built using the **FastAPI** framework, served by **Uvicorn**. It exposes RESTful endpoints for managing user birthday information. Code is located in the `birthday-app/` directory.
2.  **Database:** A **Cloud SQL PostgreSQL** instance configured for high availability (Regional) and using a **Private IP address** for enhanced security. Database schema migrations are managed by **Alembic**.
3.  **Compute Platform:** **Google Kubernetes Engine (GKE)** hosts the containerized application. A VPC-native public cluster is used.
4.  **Containerization:** The application is containerized using **Docker**. Images are stored in **Google Artifact Registry**.
5.  **Connectivity:** The application connects to the Cloud SQL database securely via the **Cloud SQL Auth Proxy** running as a sidecar container. Authentication uses **Workload Identity** and passwordless **IAM Database Authentication**.
6.  **Exposure:** The application is exposed externally via the **Kubernetes Gateway API**, managed by GKE's native Gateway controller (provisioning a Google Cloud Load Balancer).
7.  **Infrastructure as Code (IaC):** All GCP infrastructure (VPC, GKE, Cloud SQL, Artifact Registry, IAM, etc.) are defined and managed using **Terraform** with a modular structure. Code is located in the `terraform/` directory.
8.  **CI/CD:** Automated build, test (local setup), infrastructure deployment, and application deployment are handled by **GitHub Actions** workflows defined in `.github/workflows/`.

**(Suggestion: Insert a simple architecture diagram here showing GCLB -> GKE -> Pod (App + Proxy) -> VPC Network -> PSA -> Cloud SQL)**

## Design Decisions

* **GCP & GKE:** Chosen for robust managed Kubernetes, integration with other GCP services (Cloud SQL, AR, IAM), and scalability. A public cluster was chosen to simplify CI/CD runner access for this exercise.
* **Cloud SQL (Postgres, Private IP, IAM Auth):** Provides a managed, reliable database service. Using Private IP and the Proxy sidecar with IAM authentication significantly enhances security by eliminating public database endpoints and database passwords for the application. Regional configuration provides high availability.
* **FastAPI:** A modern, high-performance Python framework with automatic data validation and API documentation generation.
* **Terraform (Modular):** Standard IaC tool for repeatable and version-controlled infrastructure. A modular approach enhances reusability and maintainability.
* **GitHub Actions (Separate Workflows):** Provides CI/CD integrated with the source code repository. Separate workflows for infrastructure (`terraform/`) and application (`birthday-app/`) allow for independent deployment triggers and better separation of concerns. Terraform outputs are passed via a GCS bucket.
* **Kubernetes Gateway API:** The modern, standard Kubernetes API for configuring L7 ingress and traffic routing, offering more features and flexibility than the older Ingress resource.
* **Alembic & K8s Job:** Alembic provides standard Python DB schema migrations. Running migrations via a Kubernetes Job ensures they are applied consistently within the target cluster environment before the application deployment is finalized.

## Repository Structure

* `./birthday-app/`: Contains the FastAPI application code, Dockerfile, Kubernetes manifests, tests, and local development setup. See [birthday-app/README.md](./birthday-app/README.md) for details.
* `./terraform/`: Contains the Terraform code for provisioning all GCP infrastructure, organized into modules. See [terraform/README.md](./terraform/README.md) for details.
* `.github/workflows/`: Contains the GitHub Actions workflow definitions for CI/CD.

## Local Development

Instructions for building and running the application, database, and tests locally using Docker Compose can be found in [birthday-app/README.md](./birthday-app/README.md#local-development-setup).

## Infrastructure Setup (Terraform)

Instructions for provisioning the necessary GCP infrastructure using Terraform can be found in [terraform/README.md](./terraform/README.md#local-usage).

## CI/CD Process

This repository uses GitHub Actions for automated workflows:

1.  **Infrastructure (`infrastructure.yaml`):**
    * Triggers on pushes to `main` affecting the `terraform/` directory.
    * Authenticates to GCP using a Service Account Key (stored as `GCP_SA_KEY` secret).
    * Runs `terraform init`, `validate`, `plan`, `apply`.
    * Stores Terraform outputs in a JSON file in a GCS bucket (defined by `TF_OUTPUT_BUCKET` secret and `TF_OUTPUT_PATH` variable).

2.  **Application (`application.yaml`):**
    * Triggers on pushes to `main` affecting the `birthday-app/` directory.
    * Authenticates to GCP using the same Service Account Key.
    * Downloads the latest Terraform outputs from the GCS bucket.
    * Builds and pushes a multi-platform Docker image to Artifact Registry (tagged with Git SHA).
    * Connects `kubectl` to the GKE cluster.
    * Runs the `update_manifests.sh` script to populate Kubernetes YAML templates with TF outputs and the image tag.
    * Applies Kubernetes resources in sequence: Namespace, ConfigMap, ServiceAccount -> Migration Job -> Waits for Job Completion -> Deployment, Service, Gateway, HTTPRoute.

## Deployment

Deployment to GKE is handled automatically by the `application.yaml` CI/CD workflow described above.

**Manual Pre-step:** Before the first deployment (or if the database is recreated), the necessary permissions need to be granted *inside* the PostgreSQL database for the application's IAM user. Connect to the crea Cloud SQL instance, using console or glcoud command, reset the super user password if needed. make sure the user name is correct as created by terraform.

3.  **Grant Required Permissions:**
```sql
-- Grant the ability to use the public schema
GRANT USAGE ON SCHEMA public TO "hello-app-user-sqlsa@sre-exercise.iam";
-- Grant the ability to create tables in the public schema
GRANT CREATE ON SCHEMA public TO "hello-app-user-sqlsa@sre-exercise.iam";
-- Grant standard data manipulation permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "hello-app-user-sqlsa@sre-exercise.iam";
```

The Kubernetes manifests defining the deployment, service, migration job, gateway, etc., are located in `birthday-app/k8s/`.

## Networking & Security

* **Network Segregation:** The Cloud SQL database uses a Private IP address accessible only from within the VPC network via Private Service Access.
* **Application Access:** GKE Nodes run within a dedicated subnet. Application access is controlled via the Kubernetes Gateway and underlying Google Cloud Load Balancer firewall rules.
* **Database Authentication:** Uses passwordless IAM Database Authentication via the Cloud SQL Auth Proxy sidecar and GKE Workload Identity.
* **GKE Security:**
    * Workload Identity enabled.
    * Network Policy enforcement enabled (requires defining `NetworkPolicy` resources).
    * Control plane access restricted via Master Authorized Networks (configured in Terraform).
    * Dedicated service accounts used for GKE nodes and Terraform automation.
* **Secrets:** Database credentials are not used by the application (IAM Auth). Service Account keys for CI/CD are stored in GitHub Secrets.

## Testing

Unit and integration tests for the FastAPI application are located in `birthday-app/tests/`. They can be run locally using Docker Compose as described in the [birthday-app/README.md](./birthday-app/README.md#local-development-setup).
