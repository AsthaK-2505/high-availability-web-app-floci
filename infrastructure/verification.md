# Project Verification

## Auto Scaling Group

Auto Scaling Group: project-asg
Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 4

## Healthy Application Targets

Target 1: i-0dae2f78081466abb — port 8081 — healthy
Target 2: i-2332238e50bc10166 — port 8081 — healthy

## Direct Application Tests

Server 1:
Hello from Auto Scaling Application Server

Server 2:
Hello from Auto Scaling Application Server

## ALB Test

ALB listener: HTTP :80
Target Group: project-targets
Backend port: 8081

Successful response:

Hello from Auto Scaling Application Server

## Final Result

The Application Load Balancer successfully reached healthy EC2 instances managed by the Auto Scaling Group.
