# Birthday Greeting App

## Overview

This application is a simple FastAPI service designed to store user date of births and provide greetings based on upcoming birthdays. (see main [README.md](../../README.md)).

The core functionality includes:
* Saving/updating a user's date of birth via a PUT request.
* Retrieving a personalized birthday greeting via a GET request.
* Basic health check and root endpoints.

## Tech Stack

* **Framework:** [FastAPI](https://fastapi.tiangolo.com/)
* **Database:** PostgreSQL (via Cloud SQL in deployment, local container for development)
* **ORM:** [SQLAlchemy](https://www.sqlalchemy.org/)
* **Migrations:** [Alembic](https://alembic.sqlalchemy.org/en/latest/)
* **DB Driver:** [psycopg2-binary](https://pypi.org/project/psycopg2-binary/)
* **Server:** [Uvicorn](https://www.uvicorn.org/)
* **Testing:** [pytest](https://docs.pytest.org/), [pytest-asyncio](https://pytest-asyncio.readthedocs.io/), [HTTPX](https://www.python-httpx.org/)
* **Containerization:** Docker, Docker Compose (for local dev)
* **Language:** Python 3.13

## Local Development Setup

Instructions for running the application locally using Docker Compose.

**Prerequisites:**

* Docker Engine
* Docker Compose

**Steps:**

1.  **Clone:** Clone the parent repository (`SRE-EXERCISE`).
2.  **Navigate:** Change directory to `birthday-app`:
    ```bash
    cd SRE-EXERCISE/birthday-app
    ```
3.  **Environment File:** Create a `.env` file in the `birthday-app` directory by copying `.env.example` and update values as required. These credentials are used by the local `docker-compose.yml` setup.
    ```dotenv
    # .env file for local development
    DB_CONNECTION_MODE=local
    DB_USER=hello_user
    DB_PASSWORD=secret_password
    DB_HOST=db
    DB_PORT=5432
    DB_NAME=hello_db
    ```
4.  **Build Containers:**
    ```bash
    docker-compose build
    ```
5.  **Start Services:** Start the FastAPI app and PostgreSQL database containers in detached mode.
    ```bash
    docker-compose up -d
    ```
6.  **Run Database Migrations:** Apply Alembic migrations to the local database container.
    ```bash
    docker-compose exec app alembic upgrade head
    ```
7.  **Access Application:** The API should now be running at [http://localhost:8000](http://localhost:8000). You can access the interactive docs at [http://localhost:8000/docs](http://localhost:8000/docs).
8.  **Run Tests:** Execute the test suite within the running container.
    ```bash
    docker-compose exec app pytest -v
    ```
9.  **Stop Services:**
    ```bash
    docker-compose down
    ```

## Deployment

* **Platform:** Google Kubernetes Engine (GKE)
* **Database:** Cloud SQL for PostgreSQL (using Private IP)
* **Registry:** Google Artifact Registry (for Docker images)
* **Connectivity:** Application connects to the database via the Cloud SQL Auth Proxy sidecar using Workload Identity and IAM database authentication (passwordless).
* **Exposure:** The application is exposed via the Kubernetes Gateway API.
* **Automation:** Deployment is handled via GitHub Actions workflows defined in the `.github/workflows` directory (see main [README.md](../../README.md) for CI/CD details).
* **Manual Steps:** Note that initial database permissions for the application's service account need to be granted manually after infrastructure setup (see main [README.md](../../README.md)).

## API Endpoints

* `PUT /hello/{username}`: Saves/updates the user's date of birth.
* `GET /hello/{username}`: Returns a birthday greeting.
* `GET /`: Welcome message.
* `GET /health`: Health check endpoint.
