# High Availability Web Application with AWS, Docker & GitHub Actions

## What I built

I built a highly available web application environment locally using **Floci**, an AWS-compatible environment.

The project started as an AWS architecture exercise and grew into a DevOps project where I also added Docker and GitHub Actions CI/CD.

The main idea was to keep the application servers private, put an Application Load Balancer in front of them, use an Auto Scaling Group for the application tier, and automate the application build and deployment process.

> **Important:** The infrastructure in this repository was built and tested locally using Floci. It was not deployed to a live AWS account.


## Architecture


                         Internet
                            |
                            v
                +-----------------------+
                | Application Load      |
                | Balancer :80          |
                +-----------------------+
                            |
                            v
                +-----------------------+
                | Target Group :8081    |
                +-----------------------+
                       /          \
                      /            \
                     v              v
             +-------------+  +-------------+
             | EC2 / ASG   |  | EC2 / ASG   |
             | Nginx:8081  |  | Nginx:8081  |
             | AZ1         |  | AZ2         |
             +-------------+  +-------------+


### Network layout


VPC: 10.0.0.0/16

AZ1
├── Public Subnet  10.0.1.0/24
│   └── ALB / NAT
└── Private Subnet 10.0.3.0/24
    └── Application Server

AZ2
├── Public Subnet  10.0.2.0/24
│   └── ALB / NAT
└── Private Subnet 10.0.4.0/24
    └── Application Server


## Infrastructure I created

### VPC

I created a custom VPC with:


10.0.0.0/16


The VPC was divided into public and private subnets across two Availability Zones.

### Public subnets

The public subnets use a route table with:

0.0.0.0/0 → Internet Gateway
`

This allows internet-facing resources to communicate with the internet.

### Private subnets

The private subnets use:


0.0.0.0/0 → NAT Gateway


The application servers are placed in these private subnets instead of exposing them directly to the internet.

### Internet Gateway

I created and attached an Internet Gateway to the VPC and used it for the public subnet route.

### NAT Gateways

I created one NAT Gateway for each Availability Zone.


Private AZ1 → NAT AZ1 → Internet
Private AZ2 → NAT AZ2 → Internet


This gives the private instances an outbound path while keeping them out of the public-facing tier.



## Security Groups

I created separate security groups for the ALB and application servers.

### ALB Security Group

The ALB accepts HTTP traffic:


TCP 80
Source: 0.0.0.0/0


### Application Security Group

The application tier uses:


TCP 8081


Traffic from the ALB security group is allowed to reach the application servers.

A VPC CIDR rule for port 8081 was also required for the local Floci networking behavior.



## Application

The first version of the application was a simple Nginx-based web page.

The application returned responses such as:


Hello from Application Server 1
Hello from Application Server 2


Later, the Dockerized version served:


Hello from Dockerized Application


The application is intentionally simple because the focus of this project is the infrastructure and deployment workflow around it.



## EC2 and User Data

I used Ubuntu 24.04 EC2 instances with:


AMI: ami-ubuntu2404-amd64
Instance type: t3.micro


I used EC2 User Data to automatically install and configure the application instead of manually configuring each instance.

The application ultimately listens on:


8081


---

## Problem I faced: Nginx could not use port 80

One of the main problems I ran into was:


nginx: [emerg] bind() to 0.0.0.0:80 failed
(98: Address already in use)


At first I expected Nginx to run on the normal HTTP port 80.

I investigated the Floci EC2 container and found that port 80 was already being used by Floci's metadata service.

I changed the application to use port 8081 instead.

The final path became:


Client
  ↓
ALB :80
  ↓
Target Group :8081
  ↓
Nginx :8081


This solved the conflict without rebuilding the whole environment.



## Application Load Balancer

I created an Application Load Balancer as the public entry point.

The listener is:


HTTP :80


The ALB forwards requests to the target group on port 8081.

The target group performs HTTP health checks against the application.



## Target Group and Health Checks

The target group was configured with:


Protocol: HTTP
Port: 8081
Health check path: /


During troubleshooting, some targets initially showed:


Target.FailedHealthChecks


Instead of assuming the ALB was broken, I tested the application directly on the EC2 port forwarders.

The direct tests returned:


Hello from Auto Scaling Application Server


I then checked target registration and health and registered the ASG instances on port 8081.

After the fix, both application instances became healthy targets.



## Auto Scaling Group

I created a Launch Template and Auto Scaling Group for the application tier.

The ASG configuration was:


Minimum: 2
Desired: 2
Maximum: 4


The instances were launched into the two private subnets.

The final ASG instances became healthy targets behind the ALB.



## Docker

After completing the infrastructure, I containerized the application.

The Dockerfile uses Nginx as the base image:

dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80


The image can be built locally with:

bash
docker build -t high-availability-app:latest ./app


and run with:

bash
docker run -d \
  --name high-availability-app \
  -p 8081:80 \
  high-availability-app:latest


The container serves the application on port 80 internally.



## GitHub Actions CI

I added GitHub Actions to automatically test the Docker application.

The CI pipeline does the following:


Git push
   ↓
Checkout repository
   ↓
Build Docker image
   ↓
Run container
   ↓
Test application


The test checks that the expected application response is returned.

This means a change pushed to `main` is automatically validated instead of relying only on manual testing.



## GitHub Container Registry

The CI/CD workflow also publishes the Docker image to GitHub Container Registry.

The image is tagged using:


latest
Git commit SHA


Example:


ghcr.io/asthak-2505/high-availability-app:latest


This gives the application image a consistent location and makes deployments reproducible by image version.



## Continuous Deployment

I configured a **self-hosted GitHub Actions runner** on my laptop because Floci is running locally.

The deployment flow is:


Git push
   ↓
GitHub Actions
   ↓
Build
   ↓
Test
   ↓
Push Docker image to GHCR
   ↓
Self-hosted runner
   ↓
Docker pull
   ↓
Start updated container
   ↓
Health check


The deployment script pulls the latest image, removes the previous deployment container, starts the new container, and checks the application response.



## Why a self-hosted runner?

The Floci endpoint runs on my local machine:


http://localhost:4566


A normal GitHub-hosted runner cannot access services running on my laptop's localhost.

Using a self-hosted runner allows the deployment job to execute on the same machine where Floci is running.



## Troubleshooting the CI pipeline

The Docker image initially failed to run inside GitHub Actions because the Buildx action built the image but did not load it into the runner's local Docker image store.

The workflow was updated to use:

yaml
load: true


After that, the test container could use the image successfully.

I also encountered a GHCR tagging problem because Docker image repository names must be lowercase.

The image name was changed from the mixed-case GitHub username to:


ghcr.io/asthak-2505/high-availability-app


After those changes, the CI pipeline completed successfully.



## Verification

The infrastructure was verified using AWS CLI commands against the local Floci endpoint.

The final Auto Scaling instances were:


i-0dae2f78081466abb
i-2332238e50bc10166


Both became healthy targets on port 8081.

The final application test through the ALB returned:


Hello from Auto Scaling Application Server


The Docker CI/CD pipeline also successfully built, tested, published, and deployed the Dockerized application locally.



## Repository structure


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


## Technologies used

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



## What I learned from this project

This project helped me practice the full path from infrastructure creation to application delivery.

I worked with:

* VPC and subnet design
* Public vs private networking
* Route tables
* Internet Gateway and NAT Gateway
* Security Groups
* EC2 provisioning
* User Data
* Load balancing
* Target health checks
* Launch Templates
* Auto Scaling
* Docker
* GitHub Actions
* Container image publishing
* Self-hosted runners
* Deployment automation
* Troubleshooting using logs, direct connectivity tests, and AWS CLI

The biggest practical lesson was that getting the architecture right is only part of the work. I also had to verify each layer independently and troubleshoot problems such as port conflicts, unhealthy targets, Docker image loading, and container registry naming.



## Limitations

This project uses Floci rather than real AWS infrastructure.

Because of that, some AWS behavior can differ from production AWS, especially around:

* EC2 networking
* port forwarding
* Auto Scaling reconciliation
* target registration
* service internals

For that reason, this repository should be considered a **hands-on AWS/DevOps local implementation**, not a production AWS deployment.



## Future improvements

The next improvements I plan to add are:

* Terraform for declarative Infrastructure as Code
* Better application health endpoints
* Automated scaling/failure tests
* Monitoring and logging
* More complete application deployment automation
