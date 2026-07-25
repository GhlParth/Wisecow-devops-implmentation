# Wisecow DevOps Implementation Guide

This document provides a detailed overview of the containerization, Kubernetes deployment, CI/CD pipeline, and system automation scripts implemented for the Wisecow application.

---

## Table of Contents
1. [Overview](#1-overview)
2. [Project Structure](#2-project-structure)
3. [Containerization (Dockerization)](#3-containerization-dockerization)
4. [Kubernetes Deployment (Kind Cluster)](#4-kubernetes-deployment-kind-cluster)
5. [TLS / HTTPS Implementation](#5-tls--https-implementation)
6. [CI/CD Pipeline (GitHub Actions)](#6-cicd-pipeline-github-actions)
7. [System Automation & Monitoring Scripts](#7-system-automation--monitoring-scripts)

---

## 1. Overview
The goal of this project is to dockerize and deploy the **Wisecow** application—a shell-based web server serving cowsay wisdom—on a local **Kind** Kubernetes cluster. The application is secured via **TLS (HTTPS)**, deployed using a fully automated **GitHub Actions CI/CD pipeline**, and monitored using custom **automation scripts**.

---

## 2. Project Structure
```text
wisecow/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD Pipeline
├── certs/
│   ├── tls.crt                # TLS SSL Certificate
│   └── tls.key                # TLS SSL Private Key
├── k8s/
│   ├── deployment.yaml        # K8s Deployment Manifest
│   ├── ingress.yaml           # K8s Ingress (TLS & Routing)
│   └── service.yaml           # K8s Service (ClusterIP)
├── scripts/
│   ├── app_checker.sh         # Uptime check script (HTTP status)
│   └── system_monitor.sh      # System metrics monitor script (CPU, Mem, Disk)
├── tests/
│   └── test_wisecow.sh        # Unit testing script
├── .gitignore                 # Files and folders to ignore in Git
├── Dockerfile                 # Application Docker config
├── kind-config.yaml           # Kind cluster Ingress ports mapping
├── README.md                  # Project overview
├── IMPLEMENTATION.md          # Complete implementation guide (This file)
└── wisecow.sh                 # Application entrypoint script
```

---

## 3. Containerization (Dockerization)
A clean, lightweight Docker image was built using `debian:12-slim` to ensure mirror stability and a small image footprint.

### Dockerfile Highlights
- Installs necessary system packages: `fortune-mod`, `cowsay`, and `netcat-openbsd`.
- Adds `/usr/games` to the system `PATH` environment variable so `cowsay` and `fortune` commands resolve automatically.
- Copies the `wisecow.sh` script, sets execution permissions, and exposes port `4499`.

### Local Build & Execution
To build and run the container locally:
```bash
# Build the image
docker build -t wisecow:latest .

# Run the container mapping port 4499
docker run -d -p 4499:4499 --name wisecow wisecow:latest
```
Access the application locally at `http://localhost:4499`.

---

## 4. Kubernetes Deployment (Kind Cluster)
To support NGINX Ingress and route local HTTPS traffic, the cluster was bootstrapped with a specific configuration mapping host ports to the control-plane node.

### Local Setup Steps

#### Step 4.1: Boot the Kind Cluster
Use the provided `kind-config.yaml` to create the cluster:
```bash
kind create cluster --name wisecow-cluster --config kind-config.yaml
```

#### Step 4.2: Load Image to Kind
Ensure the cluster has access to your local docker image without pulling from Docker Hub:
```bash
kind load docker-image wisecow:latest --name wisecow-cluster
```

#### Step 4.3: Install NGINX Ingress Controller
Deploy the NGINX Ingress controller preconfigured for Kind:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress controller readiness
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
```

#### Step 4.4: Map Hostname
Map the DNS host to your local loopback IP in `/etc/hosts`:
```bash
echo "127.0.0.1 wisecow.local" | sudo tee -a /etc/hosts
```

---

## 5. TLS / HTTPS Implementation
To secure the application, a local SSL/TLS certificate was integrated:

1. **Deploy TLS Secret in K8s**:
   Feed the certificate and key files into the cluster namespace:
   ```bash
   kubectl create secret tls wisecow-tls --cert=certs/tls.crt --key=certs/tls.key
   ```
2. **Apply Ingress Manifest**:
   Applying `k8s/ingress.yaml` routes traffic coming to `https://wisecow.local` to the ClusterIP Service, terminating TLS using the secret.
   ```bash
   kubectl apply -f k8s/
   ```
3. **Verify secure connection**:
   Use `curl` ignoring self-signed CA warning:
   ```bash
   curl -k -v https://wisecow.local/
   ```

---

## 6. CI/CD Pipeline (GitHub Actions)
The CI/CD pipeline is configured in `.github/workflows/ci-cd.yml`. It has two phases:

### Phase 1: Continuous Integration (`ci-pipeline`)
Runs on standard GitHub Actions cloud runners (`ubuntu-latest`):
- **Build**: Validates Bash syntax check and setup.
- **Unit Testing**: Installs `cowsay`, `fortune-mod`, and `netcat` on the runner, then executes `./tests/test_wisecow.sh`.
- **Registry Push**: Logs into Docker Hub using repository secrets (`DOCKER_HUB_USERNAME` and `DOCKER_HUB_ACCESS_TOKEN`).
- **Unique Versioning**: Dynamically tags the image using the incremental GitHub Actions run number (e.g. `v1.0.12`) and `latest`.
- **Push**: Pushes the tagged images to Docker Hub.

### Phase 2: Continuous Deployment & Verification (`cd-pipeline-test`)
Runs automatically upon a successful build to validate deployment:
- Creates an ephemeral Kind Kubernetes cluster inside the GitHub Actions runner.
- Builds and loads the latest image into the virtual cluster.
- Installs the NGINX Ingress controller and configures the `wisecow-tls` secret.
- Applies all deployment, service, and ingress manifests (`kubectl apply -f k8s/`).
- Verifies HTTPS routing and TLS certificate handshake end-to-end inside the pipeline using curl.

---

## 7. System Automation & Monitoring Scripts
Two Bash automation scripts are located in the `scripts/` directory:

### 7.1 System Health Monitor (`scripts/system_monitor.sh`)
Monitors the host system parameters and triggers console alerts and log writes if predefined thresholds are exceeded:
- **CPU Threshold**: >80% usage
- **Memory Threshold**: >80% usage
- **Disk Usage**: >80% on root partition (`/`)
- **Process Count**: >500 running processes
- **Log Location**: `system_health.log`

Run command:
```bash
./scripts/system_monitor.sh
```

### 7.2 Application Health Checker (`scripts/app_checker.sh`)
Queries the application web server and logs the status based on HTTP status codes:
- Checks `https://wisecow.local`.
- Logs `[SUCCESS] Application is UP. HTTP Status: 200` to `app_health.log`.
- Logs `[ERROR] Application is DOWN! HTTP Status: <status_code>` to `app_health.log` if connection fails or status is not 200.

Run command:
```bash
./scripts/app_checker.sh
```
