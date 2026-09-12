# High Availability Web Application using AWS-Compatible Infrastructure and Floci

## Overview

This project demonstrates a production-style highly available web application architecture using AWS-compatible services locally through Floci.

The project implements a multi-AZ network with public and private subnets, NAT gateways, security groups, an Application Load Balancer, a target group, EC2 application servers, a Launch Template, and an Auto Scaling Group.

> **Note:** This project runs locally using Floci. It demonstrates AWS concepts and architecture without deploying resources to a live AWS account.

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
                         /       \
                        /         \
                       v           v
                  EC2 / ASG    EC2 / ASG
                  Nginx:8081   Nginx:8081
                        \         /
                         \       /
                       Auto Scaling Group
                    Min: 2 | Desired: 2 | Max: 4


## Network Architecture


VPC: 10.0.0.0/16

AZ1
├── Public Subnet
│   └── ALB / NAT Gateway
└── Private Subnet
    └── EC2 Application Server

AZ2
├── Public Subnet
│   └── ALB / NAT Gateway
└── Private Subnet
    └── EC2 Application Server


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

## Traffic Flow


Client
  |
  v
ALB :80
  |
  v
Target Group :8081
  |
  +----> EC2 Instance 1
  |
  +----> EC2 Instance 2


The application servers run Nginx on port `8081`.

Floci reserves port `80` inside its EC2 container environment for its metadata service, so the application uses port `8081` while the ALB remains exposed on HTTP port `80`.

## Auto Scaling

The Auto Scaling Group is configured with:


Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 4


The instances are placed in the private subnets across the two availability zones.

## Security

The architecture separates the load balancer from the application tier.

Internet
   |
   v
ALB Security Group
   |
   v
Application Security Group
   |
   v
Private EC2 Instances


The application servers are not directly exposed to the internet.

## Verification

The final environment was tested successfully.

Both Auto Scaling instances became healthy targets:


i-0dae2f78081466abb
i-2332238e50bc10166


The ALB successfully returned:


Hello from Auto Scaling Application Server


## Technologies

* Linux
* Docker
* Floci
* AWS CLI
* Git
* GitHub
* VPC
* EC2
* ALB
* Auto Scaling
* Nginx
* Shell scripting

## Repository Structure


high-availability-web-app-floci/
├── docker-compose.yml
├── .gitignore
├── infrastructure/
│   └── architecture.md
└── README.md


## Learning Outcomes

This project helped demonstrate:

* VPC design
* Public vs private subnet architecture
* Routing
* Internet Gateway and NAT Gateway concepts
* Security Group design
* Load balancing
* EC2 application hosting
* Health checks
* Launch Templates
* Auto Scaling
* Git/GitHub workflow
* AWS-style infrastructure using a local emulator

## Important Limitation

Floci is being used as a local AWS-compatible environment, so some behavior can differ from real AWS services. The architecture and AWS concepts demonstrated here should therefore be understood as a local implementation rather than a production AWS deployment.
