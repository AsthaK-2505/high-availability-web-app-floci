# High Availability Web Application using AWS and Floci

## About the Project

I built this project to practice designing a highly available web application using AWS-style infrastructure without deploying resources to a real AWS account.

I used **Floci** to run the AWS-compatible environment locally and used the **AWS CLI** to create and configure the infrastructure.

The main goal was to understand how networking, load balancing, private application servers, health checks, and Auto Scaling work together.

> **Note:** This is a local AWS-compatible implementation using Floci. It is not a deployment to a live AWS account.


## Architecture

                         Internet
                            |
                            v
                Application Load Balancer
                         HTTP :80
                            |
                            v
                      Target Group
                         HTTP :8081
                       /           \
                      /             \
                     v               v
              EC2 / ASG #1     EC2 / ASG #2
                 Nginx              Nginx
                  :8081              :8081
                     \               /
                      \             /
                       Auto Scaling Group
                    Min: 2 | Desired: 2 | Max: 4


The application servers are placed in private subnets, while the ALB provides the public entry point.



## Network Design

The VPC uses:

VPC: 10.0.0.0/16


Two Availability Zones were used.


AZ1
├── Public Subnet   10.0.1.0/24
└── Private Subnet  10.0.3.0/24

AZ2
├── Public Subnet   10.0.2.0/24
└── Private Subnet  10.0.4.0/24


The public subnets use an Internet Gateway for internet-bound traffic.

The private subnets use NAT gateways for outbound connectivity.


Private AZ1 → NAT Gateway AZ1 → Internet
Private AZ2 → NAT Gateway AZ2 → Internet


I used one NAT gateway per Availability Zone so that each private subnet has its own outbound path.

---

## AWS Components Used

* VPC
* Public and private subnets
* Route tables
* Internet Gateway
* NAT Gateways
* Security Groups
* EC2
* Nginx
* Application Load Balancer
* Target Group
* Launch Template
* Auto Scaling Group

---

## Security Groups

Two security groups were created.

### ALB Security Group

The ALB security group allows:


TCP 80 from 0.0.0.0/0


This allows HTTP requests to reach the public load balancer.

### Application Security Group

The application security group allows application traffic on:


TCP 8081


The main application access is intended to come from the ALB security group.

An additional VPC CIDR rule was also required for local Floci networking.

---

## Application Servers

The application tier uses Ubuntu EC2 instances.

Each instance automatically installs Nginx using EC2 User Data.

The application listens on:


8081


The original design attempted to use port 80, but this caused a problem in the Floci environment.

---

## Problem I Faced: Port 80 Conflict

One of the main troubleshooting issues in this project happened when Nginx was configured to listen on port 80.

Nginx failed with:


bind() to 0.0.0.0:80 failed
Address already in use


Instead of rebuilding the environment, I investigated the EC2 container and Floci processes.

The investigation showed that Floci was already using port 80 for its metadata service.

### Resolution

I changed the application architecture to use:


ALB listener: 80
Target Group: 8081
Nginx: 8081


This allowed the public interface to remain on normal HTTP port 80 while avoiding the port conflict inside the Floci EC2 environment.

---

## Application Load Balancer

The ALB acts as the single public entry point.


Client
  |
  v
ALB :80
  |
  v
Target Group :8081
  |
  +----> Application Server
  |
  +----> Application Server


The Target Group performs HTTP health checks on the application servers.

Only healthy targets should receive application traffic.

---

## Auto Scaling Group

The application tier was moved from manually created EC2 instances to an Auto Scaling Group.

Configuration:


Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 4


The ASG launches instances using a Launch Template.

The Launch Template defines the AMI, instance type, security group, and User Data used to configure the application server.

---

## Troubleshooting the ASG Targets

After the Auto Scaling Group launched its instances, the new targets initially appeared as unhealthy.

I tested the instances directly through their Floci port forwarders.

The application returned successfully from both instances:


Hello from Auto Scaling Application Server


I then checked the Target Group health and target registration, registered the instances explicitly on port `8081`, and re-tested the ALB.

The ALB then successfully returned the application response.

This helped me isolate the issue layer by layer:


EC2
 ↓
Application port
 ↓
Target Group
 ↓
Health Check
 ↓
ALB


---

## Verification

The final Auto Scaling instances were:


i-0dae2f78081466abb
i-2332238e50bc10166


Both became healthy targets on port `8081`.

The Auto Scaling Group was configured as:


Min: 2
Desired: 2
Max: 4


The final ALB test successfully returned:


Hello from Auto Scaling Application Server


---

## End-to-End Request Flow


Internet
   |
   v
Application Load Balancer :80
   |
   v
Target Group :8081
   |
   +-------------------+
   |                   |
   v                   v
EC2 Instance 1      EC2 Instance 2
Nginx :8081         Nginx :8081
   |                   |
   +---------+---------+
             |
             v
      Application Response


---

## Repository Structure


high-availability-web-app-floci/
│
├── README.md
├── .gitignore
├── docker-compose.yml
│
└── infrastructure/
    ├── architecture.md
    ├── setup-commands.sh
    └── verification.md


### `setup-commands.sh`

Contains the AWS CLI commands used while building the infrastructure, including VPC, subnet, routing, NAT, security groups, EC2, ALB, Target Group, Launch Template, and Auto Scaling configuration.

### `architecture.md`

Contains the architecture and resource details from the completed Floci environment.

### `verification.md`

Contains the final verification results, including healthy targets and successful ALB traffic.

---

## Tools and Technologies

* Linux
* Docker
* Floci
* AWS CLI
* Git
* GitHub
* Shell scripting
* AWS VPC
* EC2
* Application Load Balancer
* Target Groups
* Auto Scaling
* Nginx

---

## What I Learned

Through this project I practiced:

* Designing a VPC across multiple Availability Zones
* Understanding public vs private subnet routing
* Using Internet Gateways and NAT Gateways
* Separating ALB and application security groups
* Launching and configuring EC2 instances with User Data
* Using an Application Load Balancer and Target Group
* Understanding health checks
* Using Launch Templates and Auto Scaling Groups
* Debugging networking and application connectivity issues
* Using Git and GitHub with SSH
* Reproducing AWS-style infrastructure locally

---

## Limitations

This project uses Floci instead of a live AWS account.

Because of that, some AWS services and behaviors can differ from real AWS, especially around:

* EC2 networking
* port forwarding
* Auto Scaling behavior
* target registration
* service internals

The project is therefore intended as a hands-on AWS architecture and DevOps learning project implemented in a local environment.

---

## Future Improvements

Planned improvements for this project include:

* Dockerizing the application
* Adding GitHub Actions CI/CD
* Adding automated tests
* Adding container security scanning
* Converting the infrastructure to Terraform
* Adding monitoring and logging
* Testing automated failure recovery and scaling
