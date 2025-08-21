
# ----- VPC -----
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  available_zones = data.aws_availability_zones.available.names
}

# Vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = var.enable_vpc_dns_hostname
  enable_dns_support   = var.enable_vpc_dns_support

  tags = merge(var.tags, {
    Name = "${var.base_name}-vpc"
  })
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.available_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.base_name}-public-${count.index + 1}"
    Type = "Public"
  })

  lifecycle {
    precondition {
      condition     = count.index < length(local.available_zones)
      error_message = "The number of public subnets must not exceed available zones: ${length(local.available_zones)}"
    }
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.available_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.base_name}-private-${count.index + 1}"
    Type = "Private"
  })

  lifecycle {
    precondition {
      condition     = count.index < length(local.available_zones)
      error_message = "The number of private subnets must not exceed available zones: ${length(local.available_zones)}"
    }
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.base_name}-igw"
  })
}

# Elastic IPs for NAT Gateways
# eip requires an internet gateway to exist prior to association.
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.base_name}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways(Each in every AZ)
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(var.tags, {
    Name = "${var.base_name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Table for all the public subnets(public subnets share the same routing rules)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-public-rt"
  })
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for Private subnets(each per subnet)
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-private-rt-${count.index + 1}"
  })


}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
