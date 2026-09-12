# High Availability Web Application - Floci Infrastructure

## VPC
- VPC CIDR: 10.0.0.0/16
- VPC ID: vpc-75133edf

## Subnets
- Public AZ1: subnet-fc67623a — 10.0.1.0/24
- Public AZ2: subnet-fffe9910 — 10.0.2.0/24
- Private AZ1: subnet-be8c4ae2 — 10.0.3.0/24
- Private AZ2: subnet-d00357ef — 10.0.4.0/24

## Internet and NAT
- Internet Gateway: igw-1dcda70e
- NAT Gateway AZ1: nat-20d11cab31722eb71
- NAT Gateway AZ2: nat-7f9c4ff6db392d447
- Public subnets use the Internet Gateway for internet-bound traffic.
- Private subnets use NAT gateways for outbound traffic.

## Security Groups
- ALB Security Group: sg-925f76ef8d9e87772
- Application Security Group: sg-6c62d3a1a7b9c5e23
- ALB allows HTTP port 80.
- Application servers use port 8081.

## Application Load Balancer
- Name: project-alb
- Listener: HTTP :80
- DNS: project-alb-22a76e5efbd84d92.elb.localhost.floci.io

## Target Group
- Name: project-targets
- Protocol: HTTP
- Application port: 8081
- Health check path: /

## Application Servers
- Nginx runs on port 8081 because Floci reserves port 80 for its metadata service.
- Auto Scaling Group instances are running the application.
- Server 1: i-0dae2f78081466abb
- Server 2: i-2332238e50bc10166

## Launch Template
- Launch Template: lt-46349fa93031d6a33
- AMI: ami-ubuntu2404-amd64
- Instance type: t3.micro
- User Data installs Nginx and configures it for port 8081.

## Auto Scaling Group
- Name: project-asg
- Minimum: 2
- Desired: 2
- Maximum: 4
- Private subnets: subnet-be8c4ae2, subnet-d00357ef

## Verified Result
Both Auto Scaling instances became healthy targets and the ALB returned:

Hello from Auto Scaling Application Server

## Architecture Flow
Internet -> ALB :80 -> Target Group :8081 -> Auto Scaling Group -> Private EC2 -> Nginx :8081

## Floci Note
This project is an AWS-compatible local implementation using Floci, not a live AWS deployment.
