
# Architecture
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
      - **Public route tables**
         - Routes traffic to the internet gateway
      - **Private route tables**
          - route traffic to NAT gateway for internet access.
   7. **Routes**
      - These are individual routing rules within route tables that specify destination CIDR blocks and target gateways or instances.


### DNS-SSL Module Components
<img src="../docs/dns_ssl.svg" alt="Terraform-aws-architecture"/>

### Security Module Components
<img src="../docs/security.svg" alt="Terraform-aws-architecture"/>