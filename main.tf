provider "aws" {
  region = "us-west-2"
}

#What this code does in summary

#A VPC is created in us-west-2 region
#2 subnets are created in different availability zones
#launch configuration for the EC2 instances is created
#An Internet Gateway is created
#Autoscaling group to manage the EC2 instances is created
#Security group to control the traffic that is allowed to reach the EC2 instances is created
#Application Load Balancer to distribute traffic between the EC2 instances is created
#Target group to manage the EC2 instances in oder to ensure that capacity is maintained at a specified level is created
#Target group attachment to attach the EC2 instances to the target group is created
#ALB listener to listen for traffic on a specific port and forward it to the target group is also created

# create vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  #10.0.0.0/16 means we have 65,536 IP addresses available to us in this VPC
  #Ip range is from 10.0.0.0 - 10.0.255.255
  tags = {
    Name = "eco_friendly_vpc"
  }

}
#end of vpc creation

#internet gateway is used to allow traffic to enter and leave the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#subnet is used to divide the VPC into smaller networks
resource "aws_subnet" "subnet_az1" {
  cidr_block = "10.0.1.0/24"
  #10.0.1.0/24 has a range from 10.0.1.0 - 10.0.1.255
  availability_zone = "us-west-2a"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
  cidr_block = "10.0.2.0/24"
  #10.0.2.0/24 has a range from 10.0.2.0 - 10.0.2.255
  availability_zone = "us-west-2c"
  vpc_id            = aws_vpc.vpc.id
}
#end of subnet creation

# Creating a route table
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Define your routes here
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "CustomRouteTable"
  }
}

# Associating the route table with subnet_az1
resource "aws_route_table_association" "subnet_az1_assoc" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Associating the route table with subnet_az2
resource "aws_route_table_association" "subnet_az2_assoc" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.custom_route_table.id
}

#THE FUN BEGINS
#security group is used to control the traffic that is allowed to reach the EC2 instances
resource "aws_security_group" "sg" {
  name        = "eco-friendly-sg"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.vpc.id

  #Ingress is used to allow traffic to reach the EC2 instances
  ingress {
    from_port   = 80 #port 80 is used for HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443 #port 443 is used for HTTPS traffic
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22 #port 22 is used for SSH traffic
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Egress is used to allow traffic to leave the EC2 instances
  egress {
    from_port   = 0 #port 0 is used for all traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#ASG launch configuration is used to configure the EC2 instances that will be launched by the ASG
resource "aws_launch_configuration" "launch_config" {
  name     = "eco-friendly-launch-config"
  image_id = "ami-0efcece6bed30fd98"
  #ami-0efcece6bed30fd98 is the AMI ID for an ubuntu 18.04 EC2 instance
  instance_type               = "t2.micro"
  associate_public_ip_address = true # Add this line to assign public IPs to instances
  security_groups             = [aws_security_group.sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2

              # Fetch instance metadata using curl
              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

              # Generate HTML content using the fetched metadata
              cat <<HTML > /var/www/html/index.html
              <html>
              <head>
                <title>Eco Friendly Server Info</title>
                <style>
                  body {
                    font-family: Arial, sans-serif;
                    padding: 20px;
                  }
                  h1 {
                    color: #333;
                  }
                  p {
                    margin-bottom: 10px;
                  }
                  .info {
                    border: 1px solid #ccc;
                    padding: 10px;
                    margin-bottom: 20px;
                    border-radius: 5px;
                    background-color: #f9f9f9;
                  }
                </style>
              </head>
              <body>
                <h1>Welcome to the Eco Friendly Car Sharing Service!</h1>

                <div class="info">
                  <h2>Instance Details:</h2>
                  <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
                  <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
                  <p><strong>Public IP:</strong> $PUBLIC_IP</p>
                </div>

                <div class="info">
                  <h2>It's a Beautiful World.... 😀</h2>
                  <hr />
                  <h3>We'll drive you wherever you want to go. 🚗</h3>
                </div>

                <p>Designed by Olatunji Olayinka</p>
              </body>
              </html>
              HTML

              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF
}

#Auto Scaling group is used to manage the EC2 instances - in this particular case the ASG is being told to launch 3 instances, and spin up or deprovision instances according to demand, keeping in mind that the minimum number of instances can oly ever be 2 and the mazimum number allowed is 8.
resource "aws_autoscaling_group" "asg" {

  desired_capacity          = 3 #number of instances to launch
  max_size                  = 8 #max number of instances to launch
  min_size                  = 2
  vpc_zone_identifier       = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]
  launch_configuration      = aws_launch_configuration.launch_config.id
  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "web-server-instance"
    propagate_at_launch = true
  }

  # Ensure the ASG instances register with the Target Group
  lifecycle {
    create_before_destroy = true
  }
}

#ELB is used to distribute traffic between the EC2 instances
resource "aws_lb" "lb" {
  name                       = "eco-friendly-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.sg.id]
  enable_deletion_protection = false
  subnets                    = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]

}

#target group is a group of EC2 instances that the ELB will forward traffic to
resource "aws_lb_target_group" "target_group" {
  name     = "eco-friendly-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

#ELB listener is used to listen for traffic on a specific port and forward it to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"

  }
}
