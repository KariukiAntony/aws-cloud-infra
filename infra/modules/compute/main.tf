# Application Load Balancer
resource "aws_lb" "main" {
  name                       = "${var.base_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.enable_alb_deletion_protection
  tags = merge(var.tags, {
    Name = "${var.base_name}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.base_name}-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 2
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.tags, {
    Name = "${var.base_name}-tg"
  })
}



# ALB Listener(HTTPS)
resource "aws_lb_listener" "main_https" {
  count = var.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-ln-https"
  })
}

# Launch template profile
resource "aws_iam_instance_profile" "main_profile" {
  name = "${var.base_name}-ec2-profile"
  role = var.ec2_cloudwatch_role
}


# The launch template.
resource "aws_launch_template" "main" {
  name_prefix            = "${var.base_name}-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    name = aws_iam_instance_profile.main_profile.name
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  user_data = base64encode(templatefile(var.template_data_script, {
    app_name       = "var.app_name"
    environment    = "var.environment"
    log_group_name = "CloudWatchLogGroup."
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.base_name}-appserver"
    })
  }
  tags = var.tags
}

# AutoScaling group
resource "aws_autoscaling_group" "main" {
  name                = "${var.base_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  target_group_arns   = [aws_lb_target_group.main.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.base_name}-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
    iterator = tag
  }

  instance_refresh {
    strategy = "Rolling"
  }
}

# Scaling policies.
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.base_name}-scale-up"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scaling_adjustment
  policy_type            = "SimpleScaling" # The default.
  cooldown               = 300             # Amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start.
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.base_name}-scale-down"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = tonumber("-${var.scaling_adjustment}")
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}