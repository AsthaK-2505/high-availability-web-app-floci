# High Availability Web Application with AWS, Docker & GitHub Actions

## Overview

I built and validated a highly available web application architecture locally using **Floci**, an AWS-compatible local environment.

The project combines AWS-style infrastructure with Docker and GitHub Actions to practice the complete DevOps workflow:

**VPC → ALB → Target Group → Auto Scaling → Application**

and

**GitHub → GitHub Actions → Docker → GHCR → Self-hosted deployment**

> **Note:** This project was built and tested locally using Floci. It was not deployed to a live AWS account.

---

## Architecture

```text
                         Internet
                            |
                            v
                +-----------------------+
                | Application Load      |
                | Balancer :80          |
                +-----------+-----------+
                            |
                            v
                +-----------------------+
                | Target Group :8081    |
                +-----------+-----------+
                            |
                   +--------+--------+
                   |                 |
                   v                 v
             +-----------+     +-----------+
             | EC2 / ASG |     | EC2 / ASG |
             |    AZ1    |     |    AZ2    |
             | Nginx     |     | Nginx     |
             |   :8081   |     |   :8081   |
             +-----------+     +-----------+
```

### Network layout

```text
VPC: 10.0.0.0/16

AZ1
├── Public Subnet   10.0.1.0/24
└── Private Subnet  10.0.3.0/24

AZ2
├── Public Subnet   10.0.2.0/24
└── Private Subnet  10.0.4.0/24
```

Public subnets use the **Internet Gateway** for internet-bound traffic.

Private subnets use **NAT Gateways** for outbound connectivity.

I used one NAT Gateway per Availability Zone.

---

## Infrastructure

The project includes:

* Custom VPC
* Two Availability Zones
* Public and private subnets
* Route tables
* Internet Gateway
* Two NAT Gateways
* Security Groups
* EC2 instances
* Application Load Balancer
* Target Group
* Launch Template
* Auto Scaling Group

### Auto Scaling configuration

```text
Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 4
```

The application servers are placed in private subnets across the two Availability Zones.

---

## Security

I separated the load balancer and application security groups.

### ALB

```text
HTTP :80
Source: 0.0.0.0/0
```

### Application tier

```text
HTTP :8081
Source: ALB Security Group
```

A VPC CIDR rule for port 8081 was also required for local Floci networking.

The main design goal was:

```text
Internet
   ↓
ALB
   ↓
Private application servers
```

rather than exposing the EC2 application servers directly to the internet.

---

## Application

The initial application was a simple Nginx web application.

The servers returned responses such as:

```text
Hello from Application Server 1
Hello from Application Server 2
```

The Dockerized version serves:

```text
Hello from Dockerized Application
```

The application is intentionally small because the main focus of this project is the infrastructure and deployment workflow.

---

# Troubleshooting

## 1. Nginx port 80 conflict

The first Nginx configuration attempted to use port 80.

It failed with:

```text
nginx: [emerg] bind() to 0.0.0.0:80 failed
(98: Address already in use)
```

I investigated the Floci EC2 environment and found that Floci was already using port 80 for its metadata service.

### Fix

I moved Nginx to port 8081 and updated the dependent configuration.

The final request path became:

```text
Client
  ↓
ALB :80
  ↓
Target Group :8081
  ↓
Nginx :8081
```

This allowed me to keep the public ALB on the normal HTTP port while avoiding the Floci port conflict.

---

## 2. Unhealthy ALB targets

After the Auto Scaling Group launched new instances, the targets initially reported:

```text
Target.FailedHealthChecks
```

Instead of rebuilding the environment, I tested the application directly through the Floci port forwarders.

Both application instances responded successfully.

I then checked target registration and health-check configuration and explicitly registered the ASG instances on port 8081.

After the change, both targets became healthy and the ALB returned:

```text
Hello from Auto Scaling Application Server
```

---

## Docker

I containerized the application using Nginx.

### Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

Build the image:

```bash
docker build -t high-availability-app:latest ./app
```

Run it locally:

```bash
docker run -d \
  --name high-availability-app \
  -p 8081:80 \
  high-availability-app:latest
```

The container listens on port 80 internally, while the host publishes it on port 8081.

---

## CI/CD with GitHub Actions

I added GitHub Actions to automate the Docker workflow.

```text
Git push
   ↓
GitHub Actions
   ↓
Build Docker image
   ↓
Run container
   ↓
Test application
   ↓
Push image to GHCR
   ↓
Self-hosted runner
   ↓
Deploy locally
   ↓
Verify application
```

The CI pipeline builds the Docker image, starts a test container, and verifies the expected application response.

The workflow also publishes the image to **GitHub Container Registry (GHCR)**.

Example image:

```text
ghcr.io/asthak-2505/high-availability-app:latest
```

The image is also tagged using the Git commit SHA.

---

## Why a self-hosted runner?

Floci runs on my local machine:

```text
http://localhost:4566
```

A normal GitHub-hosted runner cannot directly access services running on my laptop's localhost.

I therefore configured a **self-hosted GitHub Actions runner** on my machine so the deployment job can execute locally.

---

## CI/CD Troubleshooting

### Docker image was not available to the test container

The Docker Buildx action initially built the image but did not load it into the runner's local Docker image store.

I fixed this by adding:

```yaml
load: true
```

to the build step.

### GHCR image naming error

The first image tag used the mixed-case GitHub username and failed because Docker repository names must be lowercase.

I changed it to:

```text
ghcr.io/asthak-2505/high-availability-app
```

After that, the image could be published successfully.

---

## Verification

The final Auto Scaling Group was configured with:

```text
Min: 2
Desired: 2
Max: 4
```

The final application instances became healthy targets on port 8081.

The ALB successfully returned:

```text
Hello from Auto Scaling Application Server
```

The Docker CI/CD workflow also successfully built, tested, published, and locally deployed the Dockerized application.

---

## Repository Structure

```text
high-availability-web-app-floci/
│
├── README.md
├── .gitignore
├── docker-compose.yml
│
├── app/
│   ├── Dockerfile
│   └── index.html
│
├── infrastructure/
│   ├── architecture.md
│   ├── setup-commands.sh
│   └── verification.md
│
├── scripts/
│   └── deploy-local.sh
│
└── .github/
    └── workflows/
        └── ci-cd.yml
```

---

## Technologies

* Linux
* Docker
* Git
* GitHub
* GitHub Actions
* GitHub Container Registry
* AWS CLI
* Floci
* VPC
* EC2
* Application Load Balancer
* Target Groups
* Auto Scaling
* Security Groups
* NAT Gateway
* Internet Gateway
* Nginx
* Shell scripting

---

## What I learned

This project gave me hands-on practice with:

* VPC and subnet design
* Public vs private network architecture
* Route tables
* Internet Gateway and NAT Gateway
* Security Groups
* EC2 provisioning
* User Data
* ALB and Target Groups
* Health checks
* Launch Templates
* Auto Scaling
* Docker
* GitHub Actions
* GHCR
* Self-hosted runners
* Deployment automation
* Infrastructure troubleshooting

A major lesson from the project was that building the architecture is only part of the work. I also had to test each layer independently and troubleshoot real issues involving ports, target health, Docker image handling, and container registry naming.

---

## Limitations

This implementation uses **Floci instead of live AWS**.

Because Floci is a local AWS-compatible environment, some behavior can differ from production AWS, particularly around EC2 networking, port forwarding, Auto Scaling reconciliation, and service internals.

The Docker CI/CD deployment currently runs through the local self-hosted runner. It does not replace the existing ASG instances with Docker containers.

---

## Future Improvements

* Convert infrastructure to Terraform
* Add a proper application health endpoint
* Add automated failure and recovery testing
* Add monitoring and centralized logging
* Improve the application beyond the current static web page
* Extend CI/CD into a fully integrated application deployment workflow
