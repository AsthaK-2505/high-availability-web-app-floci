	 VPC_ID=$(aws ec2 create-vpc \
	   --cidr-block 10.0.0.0/16 \
	   --query 'Vpc.VpcId' \
	   --output text)
	 # ============================================================
	 # SUBNETS
	 # ============================================================
	 PUBLIC_SUBNET_AZ1=$(aws ec2 create-subnet \
	   --vpc-id "$VPC_ID" \
	   --cidr-block 10.0.1.0/24 \
	   --availability-zone us-east-1a \
	   --query 'Subnet.SubnetId' \
	   --output text)
	 PUBLIC_SUBNET_AZ2=$(aws ec2 create-subnet \
	   --vpc-id "$VPC_ID" \
	   --cidr-block 10.0.2.0/24 \
	   --availability-zone us-east-1b \
	   --query 'Subnet.SubnetId' \
	   --output text)
	 PRIVATE_SUBNET_AZ1=$(aws ec2 create-subnet \
	   --vpc-id "$VPC_ID" \
	   --cidr-block 10.0.3.0/24 \
	   --availability-zone us-east-1a \
	   --query 'Subnet.SubnetId' \
	   --output text)
	 PRIVATE_SUBNET_AZ2=$(aws ec2 create-subnet \
	   --vpc-id "$VPC_ID" \
	   --cidr-block 10.0.4.0/24 \
	   --availability-zone us-east-1b \
	   --query 'Subnet.SubnetId' \
	   --output text)
	 # ============================================================
	 # INTERNET GATEWAY
	 # ============================================================
	 IGW_ID=$(aws ec2 create-internet-gateway \
	   --query 'InternetGateway.InternetGatewayId' \
	   --output text)
	 aws ec2 attach-internet-gateway   --internet-gateway-id "$IGW_ID"   --vpc-id "$VPC_ID"
	 # ============================================================
	 # PUBLIC ROUTE TABLE
	 # ============================================================
	 PUBLIC_RTB_ID=$(aws ec2 create-route-table \
	   --vpc-id "$VPC_ID" \
	   --query 'RouteTable.RouteTableId' \
	   --output text)
	 aws ec2 create-route   --route-table-id "$PUBLIC_RTB_ID"   --destination-cidr-block 0.0.0.0/0   --gateway-id "$IGW_ID"
	 aws ec2 associate-route-table   --route-table-id "$PUBLIC_RTB_ID"   --subnet-id "$PUBLIC_SUBNET_AZ1"
	 aws ec2 associate-route-table   --route-table-id "$PUBLIC_RTB_ID"   --subnet-id "$PUBLIC_SUBNET_AZ2"
	 # ============================================================
	 # NAT AZ1
	 # ============================================================
	 EIP_AZ1=$(aws ec2 allocate-address \
	   --domain vpc \
	   --query 'AllocationId' \
	   --output text)
	 NAT_AZ1=$(aws ec2 create-nat-gateway \
	   --subnet-id "$PUBLIC_SUBNET_AZ1" \
	   --allocation-id "$EIP_AZ1" \
	   --query 'NatGateway.NatGatewayId' \
	   --output text)
	 aws ec2 wait nat-gateway-available   --nat-gateway-ids "$NAT_AZ1"
	 # ============================================================
	 # NAT AZ2
	 # ============================================================
	 EIP_AZ2=$(aws ec2 allocate-address \
	   --domain vpc \
	   --query 'AllocationId' \
	   --output text)
	 NAT_AZ2=$(aws ec2 create-nat-gateway \
	   --subnet-id "$PUBLIC_SUBNET_AZ2" \
	   --allocation-id "$EIP_AZ2" \
	   --query 'NatGateway.NatGatewayId' \
	   --output text)
	 aws ec2 wait nat-gateway-available   --nat-gateway-ids "$NAT_AZ2"
	 # ============================================================
	 # PRIVATE ROUTE TABLE AZ1
	 # ============================================================
	 PRIVATE_RTB_AZ1=$(aws ec2 create-route-table \
	   --vpc-id "$VPC_ID" \
	   --query 'RouteTable.RouteTableId' \
	   --output text)
	 aws ec2 create-route   --route-table-id "$PRIVATE_RTB_AZ1"   --destination-cidr-block 0.0.0.0/0   --nat-gateway-id "$NAT_AZ1"
	 aws ec2 associate-route-table   --route-table-id "$PRIVATE_RTB_AZ1"   --subnet-id "$PRIVATE_SUBNET_AZ1"
	 # ============================================================
	 # PRIVATE ROUTE TABLE AZ2
	 # ============================================================
	 PRIVATE_RTB_AZ2=$(aws ec2 create-route-table \
	   --vpc-id "$VPC_ID" \
	   --query 'RouteTable.RouteTableId' \
	   --output text)
	 aws ec2 create-route   --route-table-id "$PRIVATE_RTB_AZ2"   --destination-cidr-block 0.0.0.0/0   --nat-gateway-id "$NAT_AZ2"
	 aws ec2 associate-route-table   --route-table-id "$PRIVATE_RTB_AZ2"   --subnet-id "$PRIVATE_SUBNET_AZ2"
	 echo
	 echo "============================================================"
	 echo "NETWORK CREATED"
	 echo "============================================================"
	 echo "VPC=$VPC_ID"
	 echo "PUBLIC_AZ1=$PUBLIC_SUBNET_AZ1"
	 echo "PUBLIC_AZ2=$PUBLIC_SUBNET_AZ2"
	 echo "PRIVATE_AZ1=$PRIVATE_SUBNET_AZ1"
	 echo "PRIVATE_AZ2=$PRIVATE_SUBNET_AZ2"
	 echo "IGW=$IGW_ID"
	 echo "NAT_AZ1=$NAT_AZ1"
	 echo "NAT_AZ2=$NAT_AZ2"
	 echo "============================================================"
	 set -e
	 # ============================================================
	 # FLOCI / AWS CLI
	 # ============================================================
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 # ============================================================
	 # USE THE VPC CREATED IN THE PREVIOUS PHASE
	 # ============================================================
	 echo "VPC=$VPC_ID"
	 echo "PRIVATE_AZ1=$PRIVATE_SUBNET_AZ1"
	 echo "PRIVATE_AZ2=$PRIVATE_SUBNET_AZ2"
	 # ============================================================
	 # 1. ALB SECURITY GROUP
	 # ============================================================
	 ALB_SG_ID=$(aws ec2 create-security-group \
	   --group-name project-alb-sg \
	   --description "Security group for Application Load Balancer" \
	   --vpc-id "$VPC_ID" \
	   --query 'GroupId' \
	   --output text)
	 echo "ALB_SG_ID=$ALB_SG_ID"
	 # Internet -> ALB HTTP
	 aws ec2 authorize-security-group-ingress   --group-id "$ALB_SG_ID"   --protocol tcp   --port 80   --cidr 0.0.0.0/0
	 # ============================================================
	 # 2. APPLICATION SECURITY GROUP
	 # ============================================================
	 APP_SG_ID=$(aws ec2 create-security-group \
	   --group-name project-app-sg \
	   --description "Security group for private application servers" \
	   --vpc-id "$VPC_ID" \
	   --query 'GroupId' \
	   --output text)
	 echo "APP_SG_ID=$APP_SG_ID"
	 # ALB -> Application
	 aws ec2 authorize-security-group-ingress   --group-id "$APP_SG_ID"   --protocol tcp   --port 8081   --source-group "$ALB_SG_ID"
	 # Floci local networking
	 aws ec2 authorize-security-group-ingress   --group-id "$APP_SG_ID"   --protocol tcp   --port 8081   --cidr 10.0.0.0/16
	 # ============================================================
	 # 3. SERVER 1 USERDATA
	 # ============================================================
	 USER_DATA_1=$(cat <<'EOF' | base64 -w 0
	 #!/bin/bash
	 set -e
	 export DEBIAN_FRONTEND=noninteractive
	 apt-get update -y
	 apt-get install -y nginx
	 echo "Hello from Application Server 1" > /var/www/html/index.html
	 sed -i 's/listen 80 default_server;/listen 8081 default_server;/' /etc/nginx/sites-available/default
	 sed -i 's/listen \[::\]:80 default_server;/listen [::]:8081 default_server;/' /etc/nginx/sites-available/default
	 nginx -t
	 nginx
	 EOF
	 )
	 # ============================================================
	 # 4. SERVER 2 USERDATA
	 # ============================================================
	 USER_DATA_2=$(cat <<'EOF' | base64 -w 0
	 #!/bin/bash
	 set -e
	 export DEBIAN_FRONTEND=noninteractive
	 apt-get update -y
	 apt-get install -y nginx
	 echo "Hello from Application Server 2" > /var/www/html/index.html
	 sed -i 's/listen 80 default_server;/listen 8081 default_server;/' /etc/nginx/sites-available/default
	 sed -i 's/listen \[::\]:80 default_server;/listen [::]:8081 default_server;/' /etc/nginx/sites-available/default
	 nginx -t
	 nginx
	 EOF
	 )
	 # ============================================================
	 # 5. CREATE EC2 SERVER 1
	 # ============================================================
	 SERVER1_ID=$(aws ec2 run-instances \
	   --image-id ami-ubuntu2404-amd64 \
	   --instance-type t3.micro \
	   --subnet-id "$PRIVATE_SUBNET_AZ1" \
	   --security-group-ids "$APP_SG_ID" \
	   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=project-server-1}]' \
	   --user-data "$USER_DATA_1" \
	   --query 'Instances[0].InstanceId' \
	   --output text)
	 echo "SERVER1_ID=$SERVER1_ID"
	 # ============================================================
	 # 6. CREATE EC2 SERVER 2
	 # ============================================================
	 SERVER2_ID=$(aws ec2 run-instances \
	   --image-id ami-ubuntu2404-amd64 \
	   --instance-type t3.micro \
	   --subnet-id "$PRIVATE_SUBNET_AZ2" \
	   --security-group-ids "$APP_SG_ID" \
	   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=project-server-2}]' \
	   --user-data "$USER_DATA_2" \
	   --query 'Instances[0].InstanceId' \
	   --output text)
	 echo "SERVER2_ID=$SERVER2_ID"
	 # ============================================================
	 # 7. WAIT FOR BOTH EC2 INSTANCES
	 # ============================================================
	 aws ec2 wait instance-running   --instance-ids "$SERVER1_ID" "$SERVER2_ID"
	 # Give UserData time to install Nginx
	 sleep 15
	 # ============================================================
	 # 8. VERIFY
	 # ============================================================
	 aws ec2 describe-instances   --instance-ids "$SERVER1_ID" "$SERVER2_ID"   --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,State.Name,SubnetId,Architecture]'   --output table
	 # ============================================================
	 # 9. SHOW FLOCI PORT FORWARDERS
	 # ============================================================
	 echo
	 echo "FLOCI EC2 PORT FORWARDERS:"
	 docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep 'floci-ec2-fwd' || true
	 echo
	 echo "============================================================"
	 echo "PHASE 3 + 4 COMPLETE"
	 echo "============================================================"
	 echo "ALB_SG_ID=$ALB_SG_ID"
	 echo "APP_SG_ID=$APP_SG_ID"
	 echo "SERVER1_ID=$SERVER1_ID"
	 echo "SERVER2_ID=$SERVER2_ID"
	 echo "============================================================"
	 set -e
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 # ============================================================
	 # PROJECT IDs FROM PREVIOUS PHASES
	 # ============================================================
	 echo "VPC=$VPC_ID"
	 echo "PUBLIC_AZ1=$PUBLIC_SUBNET_AZ1"
	 echo "PUBLIC_AZ2=$PUBLIC_SUBNET_AZ2"
	 echo "ALB_SG=$ALB_SG_ID"
	 echo "SERVER1=$SERVER1_ID"
	 echo "SERVER2=$SERVER2_ID"
	 # ============================================================
	 # 1. CREATE TARGET GROUP
	 # ============================================================
	 TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
	   --name project-targets \
	   --protocol HTTP \
	   --port 8081 \
	   --vpc-id "$VPC_ID" \
	   --target-type instance \
	   --health-check-protocol HTTP \
	   --health-check-port 8081 \
	   --health-check-path / \
	   --matcher HttpCode=200 \
	   --query 'TargetGroups[0].TargetGroupArn' \
	   --output text)
	 echo "TARGET_GROUP_ARN=$TARGET_GROUP_ARN"
	 # ============================================================
	 # 2. REGISTER EC2 SERVERS
	 # ============================================================
	 aws elbv2 register-targets   --target-group-arn "$TARGET_GROUP_ARN"   --targets     Id="$SERVER1_ID",Port=8081     Id="$SERVER2_ID",Port=8081
	 echo "EC2 servers registered."
	 # ============================================================
	 # 3. CREATE APPLICATION LOAD BALANCER
	 # ============================================================
	 ALB_ARN=$(aws elbv2 create-load-balancer \
	   --name project-alb \
	   --subnets "$PUBLIC_SUBNET_AZ1" "$PUBLIC_SUBNET_AZ2" \
	   --security-groups "$ALB_SG_ID" \
	   --scheme internet-facing \
	   --type application \
	   --query 'LoadBalancers[0].LoadBalancerArn' \
	   --output text)
	 echo "ALB_ARN=$ALB_ARN"
	 # ============================================================
	 # 4. WAIT FOR ALB
	 # ============================================================
	 while true; do     ALB_STATE=$(aws elbv2 describe-load-balancers \
	       --load-balancer-arns "$ALB_ARN" \
	       --query 'LoadBalancers[0].State.Code' \
	       --output text);      echo "ALB state: $ALB_STATE";      if [ "$ALB_STATE" = "active" ]; then         break;     fi;      sleep 3; done
	 # ============================================================
	 # 5. CREATE HTTP LISTENER
	 # ============================================================
	 LISTENER_ARN=$(aws elbv2 create-listener \
	   --load-balancer-arn "$ALB_ARN" \
	   --protocol HTTP \
	   --port 80 \
	   --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
	   --query 'Listeners[0].ListenerArn' \
	   --output text)
	 echo "LISTENER_ARN=$LISTENER_ARN"
	 # ============================================================
	 # 6. GET ALB DNS
	 # ============================================================
	 ALB_DNS=$(aws elbv2 describe-load-balancers \
	   --load-balancer-arns "$ALB_ARN" \
	   --query 'LoadBalancers[0].DNSName' \
	   --output text)
	 echo
	 echo "============================================================"
	 echo "LOAD BALANCER CREATED"
	 echo "============================================================"
	 echo "ALB_DNS=$ALB_DNS"
	 echo "TARGET_GROUP=$TARGET_GROUP_ARN"
	 echo "LISTENER=$LISTENER_ARN"
	 echo "============================================================"
	 # ============================================================
	 # 7. TEST USING THE ALB HOSTNAME
	 # ============================================================
	 echo
	 echo "Testing ALB..."
	 curl -sS --max-time 10   -H "Host: $ALB_DNS"   http://localhost:8080
	 echo
	 set -e
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 SERVER1_ID=i-d99dda9fc28839f2b
	 SERVER2_ID=i-e928a378bc975f0b0
	 FWD1="floci-ec2-fwd-${SERVER1_ID}-80"
	 FWD2="floci-ec2-fwd-${SERVER2_ID}-80"
	 echo "Waiting for Floci EC2 port forwarders..."
	 for i in {1..30}; do     if docker ps --format '{{.Names}}' | grep -qx "$FWD1" &&        docker ps --format '{{.Names}}' | grep -qx "$FWD2"; then         echo "Both EC2 forwarders are ready.";         break;     fi;     sleep 2; done
	 echo
	 echo "================ EC2 FORWARDERS ================"
	 docker ps   --filter "name=$FWD1"   --filter "name=$FWD2"   --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	 echo
	 echo "================ FLOCI EC2 LOGS ================"
	 docker logs --tail 150 floci-floci-1 2>&1 | grep -E "$SERVER1_ID|$SERVER2_ID|UserData|user-data|nginx|8081|Published EC2|error|failed" | tail -50 || true
	 echo
	 echo "================ ALB TEST ================"
	 ALB_DNS=$(aws elbv2 describe-load-balancers \
	   --names project-alb \
	   --query 'LoadBalancers[0].DNSName' \
	   --output text)
	 echo "ALB DNS: $ALB_DNS"
	 curl -sS --max-time 15   -H "Host: $ALB_DNS"   http://localhost:8080
	 echo
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 ALB_DNS="project-alb-22a76e5efbd84d92.elb.localhost.floci.io"
	 echo "========== ALB LOAD BALANCING TEST =========="
	 for i in {1..10}; do   echo -n "Request $i: ";   curl -s -H "Host: $ALB_DNS" http://localhost:8080;   echo; done
	 echo "========== TARGET REGISTRATION =========="
	 aws elbv2 describe-target-groups   --names project-targets   --query 'TargetGroups[0].{Port:Port,Protocol:Protocol,HealthPath:HealthCheckPath}'   --output table
	 echo
	 echo "========== REGISTERED SERVERS =========="
	 aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --query 'TargetHealthDescriptions[].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}'   --output table 2>&1 || true
	 echo
	 echo "========== FLOCI EC2 FORWARDERS =========="
	 docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Status}}' | grep 'floci-ec2-fwd' || true
	 echo
	 echo "========== SERVER IDs =========="
	 echo "Server 1: $SERVER1_ID"
	 echo "Server 2: $SERVER2_ID"
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 VPC="vpc-75133edf"
	 PRIVATE_AZ1="subnet-be8c4ae2"
	 PRIVATE_AZ2="subnet-d00357ef"
	 APP_SG_ID="sg-6c62d3a1a7b9c5e23"
	 TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:000000000000:targetgroup/project-targets/3ab58916320f49ec"
	 LAUNCH_TEMPLATE_NAME="project-launch-template"
	 ASG_NAME="project-asg"
	 echo "========== 1. CREATE USER DATA =========="
	 cat > user-data.sh <<'EOF'
	 #!/bin/bash
	 apt-get update -y
	 apt-get install -y nginx
	 sed -i 's/listen 80 default_server;/listen 8081 default_server;/' /etc/nginx/sites-available/default
	 sed -i 's/listen \\[::\\]:80 default_server;/listen [::]:8081 default_server;/' /etc/nginx/sites-available/default
	 cat > /var/www/html/index.html <<'HTML'
	 Hello from Auto Scaling Application Server
	 HTML
	 nginx -t
	 nginx
	 EOF
	 USER_DATA=$(base64 -w0 user-data.sh)
	 echo "========== 2. CREATE LAUNCH TEMPLATE =========="
	 cat > launch-template-data.json <<EOF
	 {
	   "ImageId": "ami-ubuntu2404-amd64",
	   "InstanceType": "t3.micro",
	   "SecurityGroupIds": ["$APP_SG_ID"],
	   "UserData": "$USER_DATA"
	 }
	 EOF
	 aws ec2 describe-launch-templates   --launch-template-names "$LAUNCH_TEMPLATE_NAME"   --query 'LaunchTemplates[0].LaunchTemplateId'   --output text 2>/dev/null || true
	 if ! aws ec2 describe-launch-templates   --launch-template-names "$LAUNCH_TEMPLATE_NAME"   --query 'LaunchTemplates[0].LaunchTemplateId'   --output text 2>/dev/null | grep -q '^lt-'; then   aws ec2 create-launch-template     --launch-template-name "$LAUNCH_TEMPLATE_NAME"     --version-description "Nginx application server"     --launch-template-data file://launch-template-data.json; fi
	 LAUNCH_TEMPLATE_ID=$(aws ec2 describe-launch-templates \
	   --launch-template-names "$LAUNCH_TEMPLATE_NAME" \
	   --query 'LaunchTemplates[0].LaunchTemplateId' \
	   --output text)
	 echo
	 echo "Launch Template: $LAUNCH_TEMPLATE_ID"
	 echo
	 echo "========== 3. CREATE AUTO SCALING GROUP =========="
	 if ! aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names "$ASG_NAME"   --query 'AutoScalingGroups[0].AutoScalingGroupName'   --output text 2>/dev/null | grep -q "^$ASG_NAME$"; then   aws autoscaling create-auto-scaling-group     --auto-scaling-group-name "$ASG_NAME"     --launch-template "LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version=\$Latest"     --min-size 2     --desired-capacity 2     --max-size 4     --vpc-zone-identifier "$PRIVATE_AZ1,$PRIVATE_AZ2"     --target-group-arns "$TARGET_GROUP_ARN"; else   echo "ASG already exists: $ASG_NAME"; fi
	 echo
	 echo "========== 4. ASG CONFIGURATION =========="
	 aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names "$ASG_NAME"   --query 'AutoScalingGroups[0].{
	     Name:AutoScalingGroupName,
	     Min:MinSize,
	     Desired:DesiredCapacity,
	     Max:MaxSize,
	     Subnets:VPCZoneIdentifier,
	     TargetGroups:TargetGroupARNs
	   }'   --output table
	 echo
	 echo "========== 5. ASG INSTANCES =========="
	 aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names "$ASG_NAME"   --query 'AutoScalingGroups[0].Instances[].{
	     Instance:InstanceId,
	     State:LifecycleState,
	     Health:HealthStatus,
	     AZ:AvailabilityZone
	   }'   --output table
	 rm -f user-data.sh launch-template-data.json
	 echo
	 echo "========== AUTO SCALING SETUP COMPLETE =========="
	 echo "Launch Template : $LAUNCH_TEMPLATE_ID"
	 echo "Auto Scaling    : $ASG_NAME"
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 echo "========== EC2 SERVERS =========="
	 aws ec2 describe-instances   --instance-ids "$SERVER1_ID" "$SERVER2_ID"   --query 'Reservations[].Instances[].{
	     ID:InstanceId,
	     State:State.Name,
	     Type:InstanceType,
	     PrivateIP:PrivateIpAddress,
	     Subnet:SubnetId,
	     AZ:Placement.AvailabilityZone
	   }'   --output table
	 echo
	 echo "========== TARGET HEALTH =========="
	 aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --query 'TargetHealthDescriptions[].{
	     Instance:Target.Id,
	     Port:Target.Port,
	     State:TargetHealth.State
	   }'   --output table
	 echo
	 echo "========== ALB =========="
	 aws elbv2 describe-load-balancers   --names project-alb   --query 'LoadBalancers[0].{
	     Name:LoadBalancerName,
	     State:State.Code,
	     DNS:DNSName
	   }'   --output table
	 echo
	 echo "========== ASG =========="
	 aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names project-asg   --query 'AutoScalingGroups[0].{
	     Name:AutoScalingGroupName,
	     Min:MinSize,
	     Desired:DesiredCapacity,
	     Max:MaxSize,
	     Instances:Instances
	   }'   --output json
	 echo
	 echo "========== FINAL ALB TEST =========="
	 curl -s -H "Host: $ALB_DNS" http://localhost:8080
	 echo
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 echo "========== ASG INSTANCES =========="
	 aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names project-asg   --query 'AutoScalingGroups[0].Instances[].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}'   --output table
	 echo
	 echo "========== CURRENT TARGETS =========="
	 timeout 10s aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --query 'TargetHealthDescriptions[].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}'   --output table 2>&1 || echo "Target health command timed out"
	 echo
	 echo "========== FLOCI EC2 FORWARDERS =========="
	 docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Status}}' | grep 'floci-ec2-fwd' || true
	 echo
	 echo "========== DIRECT SERVER TEST =========="
	 for PORT in 30000 30001; do   echo -n "localhost:$PORT -> ";   timeout 5s curl -s http://localhost:$PORT || echo "no response"; done
	 echo
	 echo "========== ALB TEST =========="
	 echo -n "ALB -> "
	 timeout 5s curl -s -H "Host: $ALB_DNS" http://localhost:8080 || echo "no response"
	 echo
	 echo "========== ASG SERVER DIRECT TEST =========="
	 for PORT in 30002 30003; do   echo;   echo "Testing localhost:$PORT ...";   timeout 5s curl -s http://localhost:$PORT || echo "NO RESPONSE"; done
	 echo
	 echo "========== ASG SERVER CONTAINERS =========="
	 docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'i-0dae2f78081466abb|i-2332238e50bc10166' || true
	 echo
	 echo "========== FLOCI LOGS FOR ASG SERVERS =========="
	 docker logs --tail 200 floci-floci-1 2>&1 | grep -E 'i-0dae2f78081466abb|i-2332238e50bc10166|UserData|user-data|8081|nginx' | tail -80 || true
	 echo
	 echo "========== TARGET HEALTH =========="
	 timeout 10s aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --output table 2>&1 || true
	 echo "========== TEST ASG SERVER 1 =========="
	 echo -n "30002 -> "
	 timeout 5s curl -s http://localhost:30002 || echo "NO RESPONSE"
	 echo
	 echo "========== TEST ASG SERVER 2 =========="
	 echo -n "30003 -> "
	 timeout 5s curl -s http://localhost:30003 || echo "NO RESPONSE"
	 echo
	 echo "========== FLOCI LOGS =========="
	 docker logs --tail 300 floci-floci-1 2>&1 | grep -E 'i-0dae2f78081466abb|i-2332238e50bc10166|nginx|UserData|8081' | tail -100 || true
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 echo "========== RE-REGISTER ASG TARGETS =========="
	 aws elbv2 register-targets   --target-group-arn "$TARGET_GROUP_ARN"   --targets     Id=i-0dae2f78081466abb,Port=8081     Id=i-2332238e50bc10166,Port=8081
	 echo
	 echo "========== WAIT FOR HEALTH CHECK =========="
	 sleep 15
	 echo
	 echo "========== TARGET HEALTH =========="
	 timeout 10s aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --query 'TargetHealthDescriptions[].{
	     Instance:Target.Id,
	     Port:Target.Port,
	     State:TargetHealth.State,
	     Reason:TargetHealth.Reason,
	     Description:TargetHealth.Description
	   }'   --output table || true
	 echo
	 echo "========== ALB TEST =========="
	 timeout 5s curl -s -H "Host: $ALB_DNS" http://localhost:8080 || true
	 echo
	 export AWS_ENDPOINT_URL=http://localhost:4566
	 export AWS_ACCESS_KEY_ID=test
	 export AWS_SECRET_ACCESS_KEY=test
	 export AWS_DEFAULT_REGION=us-east-1
	 export AWS_PAGER=""
	 OLD_SERVER1="i-d99dda9fc28839f2b"
	 OLD_SERVER2="i-e928a378bc975f0b0"
	 echo "========== 1. REMOVE OLD SERVERS FROM TARGET GROUP =========="
	 aws elbv2 deregister-targets   --target-group-arn "$TARGET_GROUP_ARN"   --targets     Id=$OLD_SERVER1     Id=$OLD_SERVER2
	 echo
	 echo "========== 2. TERMINATE OLD SERVERS =========="
	 aws ec2 terminate-instances   --instance-ids "$OLD_SERVER1" "$OLD_SERVER2"   --query 'TerminatingInstances[].{Instance:InstanceId,Previous:PreviousState.Name,Current:CurrentState.Name}'   --output table
	 echo
	 echo "========== 3. WAIT FOR CLEANUP =========="
	 sleep 10
	 echo
	 echo "========== 4. ASG =========="
	 aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names project-asg   --query 'AutoScalingGroups[0].{
	     Name:AutoScalingGroupName,
	     Min:MinSize,
	     Desired:DesiredCapacity,
	     Max:MaxSize,
	     Instances:Instances[].InstanceId
	   }'   --output json
	 echo
	 echo "========== 5. TARGET GROUP =========="
	 timeout 10s aws elbv2 describe-target-health   --target-group-arn "$TARGET_GROUP_ARN"   --query 'TargetHealthDescriptions[].{
