# Cloud & Edge Computing Project: Strange Blog DevOps

**Student:** Matteo Battilori
**Course:** Cloud and Edge Computing  
**University:** Università degli studi di Modena e Reggio Emilia  
**Academic Year:** 2025/2026

---

## Project Overview

This project focuses on the **modernization and cloud-native transformation** of a legacy web application ("Strange Blog"). 

Starting from a strictly monolithic and "suboptimal on purpose" codebase, the goal was not to rewrite the application logic, but to build a robust **Cloud & Edge infrastructure** around it. The project demonstrates the application of Containerization, Orchestration, and Automation principles.

### Architecture & DevOps Enhancements

The original application has been containerized and orchestrated using **Docker** and **Kubernetes**. Key implemented features include:

* **Containerization (Docker):**
    * Created a production-ready `Dockerfile` based on `python:3.9-slim`.
    * Implemented **Shift-Left Quality Gates**: The build process automatically runs a validation script (`check_markdown_validity.sh`) to reject invalid content *before* the image is created.
    * **Self-Healing Entrypoint**: A custom `entrypoint.sh` script handles dynamic configuration and ensures the database is reachable and migrated before starting the app.

* **Orchestration (Kubernetes):**
    * **Stateless Architecture**: The Flask application is deployed as a stateless `Deployment`, allowing horizontal scaling (tested with multiple replicas).
    * **Persistence**: Database state is decoupled using `PersistentVolumeClaim` (PVC), ensuring data survives pod restarts.
    * **Service Discovery**: Internal DNS resolution (`db` service) decouples the application from specific database IP addresses.
    * **Secret Management**: Sensitive data (DB passwords) are managed via Kubernetes `Secrets`, not hardcoded in manifests.

---

## How to Run the Project

### Prerequisites
* Docker
* Kubernetes Cluster (Minikube, K3s, or similar)
* `kubectl` CLI

### 1. Build the Docker Image
To build the image locally (this will also trigger the markdown validity check):

```bash
docker-compose up --build
```

### 1.1 Access Local Application (Docker)
Once the container is running via Docker Compose, the application is exposed on port 8080.
To view the web interface, open your browser and navigate to:

```bash
http://localhost:8080
``` 
or 
```bash
http://127.0.0.1:8080
```

### 2. Deploy to Kubernetes

Apply the manifests to your cluster.

```bash
kubectl apply -f k8s/
```

### 3. Verify Deployment

Check the status of the pods and services:

```bash
kubectl get pods
kubectl get services
```

### 4. Access the Application
The Kubernetes Service is configured as a NodePort exposed on port 30080.
To view the web interface, open your browser and navigate to:

```bash
http://<AWS_instance_public_IP>:30080
```

> **Important:**: Ensure that the AWS Security Group (firewall) associated with your instance allows inbound traffic on TCP port 30080.

### 5. Test Horizontal Scaling

To demonstrate the **stateless architecture**, you can manually scale the application deployment to handle more traffic. Run the following command to increase the number of pods:

```bash
kubectl scale deployment flask-devops --replicas=3
```

> **Note:** Due to local environment resource constraints (CPU/RAM), it is recommended to set a **maximum of 3 replicas**.

Verify that the new replicas are starting up correctly:

```bash
kubectl get pods -w
```

---

## Repository Structure

* `app.py` / `wsgi.py`: Main application entry points.
* `posts/` / `static/` / `templates/`: Original Legacy Application source code and assets.
* `requirements.txt`: Python dependencies list.
* `Dockerfile`: Definition for the container image.
* `docker-compose.yml`: Local development orchestration.
* `entrypoint.sh`: Boot script for DB waiting and migrations.
* `check_markdown_validity.sh`: CI/CD script for content validation.
* `k8s/`: Kubernetes YAML manifests (Deployments, Services, Secrets, PVC).
* `.github/workflows/pipeline.yml`: CI/CD GitHub pipeline definition.
