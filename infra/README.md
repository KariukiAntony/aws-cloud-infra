
# Architecture
## Infra Structure
```bash
infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf(remote state)
├── providers.tf
├── terraform.tfvars.example
├── .terraformignore
├── README.md
├── modules/
│   ├── networking/
│   │   ├── main.tf(VPC + Subnets + IGW + NAT + EIP + RouteTables)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── dns-ssl/
│   │   ├── main.tf (Route53 + ACM)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── cdn/
│   │   ├── main.tf (CloudFront)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/
│   │   ├── main.tf (ALB + Target Group + ASG + Launch Template + EC2)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── data/
│   │   ├── main.tf (RDS)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── storage/
│   │   ├── main.tf (S3)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security/
│   │   ├── main.tf (Security Groups + IAM + Key Pairs)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── monitoring/
│   │   ├── main.tf (CloudWatchAlarms + SNS + CloudWatch Dashboard)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── bastion/
│       ├── main.tf (Bastion Host)
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
```
## Modules
## Networking Module Components
<img src="../docs/networking.svg" alt="Terraform-aws-architecture"/>

   1. **VPC**
      - This resource enables us to create an isolated virtual network within AWS. It gives us full control of networking in the cloud.
   2. **Subnets**
      - Subnets are subdivisions of the vpc that segment our network into smaller, manageable pieces. Each subnet resides in a single availability zone for high availability. We have two subnets:
       - **Public subnets:** These subnets routes to an internet gateway allowing resources deployed in them to access the internet ie `(eg.,bastion hosts, load balancers)`
       - **Private subnets:** These subnets does not have direct route to the internet gateway. We are using them to deploy resources that shouldn't be publicly available `(eg, application servers and databases)`

   3. **Internet Gateway**
       - This resource provides internet access to the vpc. It's attached to the vpc and allows biderectional internet traffic for resources in public subnets.
   4. **Nat Gateway**
      - This resource enables outbound internet access to resources deployed in private subnets while preventing inbound connections from the internet.
   5. **Elastic IP**
      - This resource provides a static ip address that can be associated with NAT gateways, Load balancers and EC2 instances that need constistent public ips.
   6. **Route tables**
      - This resource define how network traffic is directed within the vpc and to external networks. we typically have:
      - **Public route table**
         - Routes traffic to the internet gateway
         - This project uses only one route table for all public subnets since they all share the same routing rules.
      - **Private route tables**
          - route traffic to NAT gateway for internet access.
   7. **Routes**
      - These are individual routing rules within route tables that specify destination CIDR blocks and target gateways or instances.


### DNS-SSL Module Components
<img src="../docs/dns_ssl.svg" alt="Terraform-aws-architecture"/>

  1. **Route53**
     - This resource enables us to centrally manage the **DNS records** of our domain within a **hosted zone.**
     -  It provides features such as **Alias Records** which enables use to point our domain to other **AWS Resources**
   2. **ACM**
      - This resources lets you easily provision, manage, and deploy **SSL/TLS certificates** for use with AWS services.
      - In this app, we are provisioning two certificates.
        - 1. **Cloudfront:** This ensures a secure, encrypted connection between end **user's browser and the CloudFront edge location**
        - 2. **ALB:** ensures a secure, encrypted communication between **CloudFront edge location and Application Load Balancer.**
      - Since cloudfront is not in the same region as the ALB, that's why we have two certificates.

### CDN Module Components
  1. **CloudFront**
     - CloudFront is a Content Delivery Network (CDN) that delivers content to users with low latency and high transfer speeds.
     - In this architecture, it serves two purposes:
        - **Content Delivery:** It serves the static content hosted in the S3 bucket directly from the edge location closest to the end user
        - **Caching:** It stores a copy of the content at the edge, so subsequent requests for the same content don't need to travel all the way back to the S3 bucket

### Compute Module Components
  1. **Application Load Balancer**
     - **An Application Load Balancer (ALB)** is a smart traffic manager that works at the application layer (Layer 7).
     - It distributes incoming web traffic (HTTP/HTTPS) across multiple targets, in this architecture, EC2 instances
  2. **Target Group**
     - A Target Group is a logical grouping of resources that an ALB routes traffic to
     - The ALB continuously monitors the health of all targets within the group and only forwards traffic to healthy ones, ensuring high availability.
  3. **Auto Scaling Group**
     - An **Auto Scaling Group (ASG)** is a collection of EC2 instances that are treated as a logical unit for scaling and management.
     - In this architecture, it ensures that the desired instances are always running to handle out application load.
  4. **Launch Template**
     - A launch template is a saved configuration for launching EC2 instances
     - In this architecture, It acts as a blueprint for our ASG, specifying all the details needed to create an instance, such as the AMI ID, instance type, security groups, and user data

### Security Module Components
<img src="../docs/security.svg" alt="Terraform-aws-architecture"/>

  1. **Security Groups**
     - Security groups act as a **virtual firewall** for our instances to control all inbound and outbound traffic. They operate at the instance level and are stateful.
     - This module houses the security groups for different resources, such as the **ALB**, which controls traffic from **CloudFront**, and **EC2** instances.

   2. **IAM Roles and Policies**
      - This module centralizes and manages all the **IAM roles and policies** that the application's resources require.
      - Centralizing them in one module simplifies management, improves security, and ensures consistency across the infrastructure.
   3. **Key pairs**
      - This resource creates the key pair, allowing us to connect to a bastion host in a public subnet via SSH. From the bastion host, we can then use the same key pair to securely connect to other instances located in a private subnets.

### Monitoring Module Components
  1. **SNS topic**
     - This is the central communication channel where **CloudWatch Alarms** publish messages
     - Once we subscribe to it via email, we are able to receive these messages from the topic
   2. **CloudWatch Alarms**
      - Alarms are used to monitor resource **metrics** and trigger an action based on a specified metric and threshold
      - In this case(Auto Scaling Group), they monitor resource utilization, such as **CPU Utilization** and **Memory Used** and trigger actions like sending notifications to an SNS topic or scaling the group's instances in or out
   3. **CloudWatch Dashboard**
      - This resource enables us to visualize key metrics and alarms from across your entire AWS environment, giving us a real-time snapshot of the infrastructure's health and performance.
      - It puts all the relevant data in one place, saving use the headache of having to jump from different services and regions to check the metrics.
### Bastion Module Components
  1. **EC2 Instance**
     - This instance enables use to connect to other instances running in private subnets securely.
     - To connect to the instances, we are using `ssh agent forwarding` which provides more security that copying the ssh private key to the bastion host.
     - Here are the steps:
        - ```bash
          eval "$(ssh-agent -s)" # start the ssh agent
          ssh-add ~/path-to-private-key # Add the private key to use for authentication
          ssh -A ubuntu@bastion-host # Connect to bastion host with local agent being forwarded.
          ```