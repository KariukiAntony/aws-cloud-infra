# ------ Data Sources -------
# Get cloudfront ip ranges.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# --- Bastion host ----
# Key pair
resource "aws_key_pair" "key" {
  key_name   = "${var.base_name}-key-pair"
  public_key = file(var.host_key_path)

  tags = merge(var.tags, {
    Name = "${var.base_name}-key-pair"
  })

}

# Bastion host security group
resource "aws_security_group" "bastion" {
  name        = "${var.base_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_host_allowed_cidr_blocks
  }

  ingress {
    description = "ICMP(ping) from allowed IPs"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.bastion_host_allowed_cidr_blocks
  }

  dynamic "ingress" {
    for_each = var.allow_bastion_host_http_traffic ? [1] : []
    content {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "ingress" {
    for_each = var.allow_bastion_host_https_traffic ? [1] : []
    content {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-bastion-sg"
  })
}

# ---- Private instances ---

# Private instance security group
resource "aws_security_group" "private" {
  name        = "${var.base_name}-private-sg"
  description = "Security group for private instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH Bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "ICMP(ping) from bastion host"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-private-sg"
  })
}

# ---- ALB -----
# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.base_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS only from CloudFront IP ranges"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "All traffic to target groups"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-alb-sg"
  })
}