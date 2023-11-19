# eco-friendly-fleet-management

## Overview

This repository represents a Project to create flexible infrastructure for an eco-friendly car-sharing service that automatically adapts to varying usage demands while keeping costs in check. I will be using Terraform to provision the different resources that are required such as VPCs, Subnets, Security groups, Autoscaling groups, Load balancers, EC2 instances etc.

## Description

The scripts in this repository will automate the deployment of a scalable and highly available web application architecture on Amazon Web Services (AWS). The infrastructure includes:

- **Network Setup:** Creates a Virtual Private Cloud (VPC), subnets in different availability zones, and associates them with a custom route table and an internet gateway for internet access.

- **Security Configuration:** Establishes security groups controlling inbound and outbound traffic to EC2 instances.

- **Instance Configuration:** Sets up launch configurations for EC2 instances running an Apache web server and generates an HTML page displaying instance metadata.

- **Auto Scaling and Load Balancing:** Implements an Auto Scaling Group (ASG) and an Application Load Balancer (ALB) for distributing traffic among instances.

## Prerequisites

- Install Terraform on your local machine. ([Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- Configure AWS credentials with appropriate permissions. ([AWS Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html))

## Usage

1. Clone this repository:

    ```bash
    git clone https://github.com/olatunji-weber/eco-friendly-fleet-management.git
    cd .\eco-friendly-fleet-management\
    ```

2. Initialize Terraform and apply the configuration:

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

## Cleanup

To avoid incurring charges, ensure to destroy the resources after use:

```bash
terraform destroy
```
