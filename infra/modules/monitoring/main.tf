
# Get the current region
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region

  is_nitro_instance = can(regex("^(t3|t4g|m5|m5a|m5ad|m5d|m5dn|m5n|m5zn|c5|c5a|c5ad|c5d|c5n|r5|r5a|r5ad|r5b|r5d|r5dn|r5n|x1e|z1d|a1|u-|x2|i3|i3en|i4i|d3|d3en|f1|g3|g4|g5|p2|p3|p4|inf)", var.instance_type))
  root_device       = local.is_nitro_instance ? "/dev/nvme0n1p1" : "/dev/xvda1"
}

# SNS topic
resource "aws_sns_topic" "main" {
  name         = "${var.base_name}-topic"
  display_name = "CloudWatch Alerts for ${var.base_name}"
  tags = merge(var.tags, {
    Purpose = "Monitoring-alerts"
  })
}

# Subscribe to the created topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.main.arn
  endpoint  = var.notification_email
  protocol  = "email"
}

# --- CloudWatch alarms ---
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "${var.base_name}-high_cpu"
  alarm_description         = "This metric monitors ASG CPU utilization"
  evaluation_periods        = 2
  namespace                 = "AWS/EC2"
  metric_name               = "CPUUtilization"
  statistic                 = "Average"
  period                    = 120 # Two minutes
  threshold                 = 50
  comparison_operator       = "GreaterThanThreshold"
  alarm_actions             = [aws_sns_topic.main.arn, var.scale_up_policy_arn]
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.main.arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = merge(var.tags, {
    Name = "${var.base_name}-high-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.base_name}-low-cpu"
  alarm_description   = "This metric monitors ASG CPU utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  period              = 120
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  threshold           = 30
  statistic           = "Average"
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  alarm_actions = [aws_sns_topic.main.arn, var.scale_down_policy_arn]
  ok_actions    = [aws_sns_topic.main.arn]
  tags = merge(var.tags, {
    Name = "${var.base_name}-low-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name                = "${var.base_name}-high-memory"
  alarm_description         = "This metric monitors ASG memory utilization"
  evaluation_periods        = 2
  namespace                 = "CWAgent"
  metric_name               = "mem_used_percent"
  statistic                 = "Average"
  period                    = 120
  threshold                 = 50
  comparison_operator       = "GreaterThanThreshold"
  alarm_actions             = [aws_sns_topic.main.arn, var.scale_up_policy_arn]
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.main.arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = merge(var.tags, {
    Name = "${var.base_name}-high-memory-alarm"
  })
}


resource "aws_cloudwatch_metric_alarm" "disk_usage" {
  alarm_name                = "${var.base_name}-high-disk-usage"
  alarm_description         = "This metric monitors ASG disk utilization"
  evaluation_periods        = 2
  namespace                 = "CWAgent"
  metric_name               = "disk_used_percent"
  statistic                 = "Average"
  period                    = 300
  threshold                 = 80
  comparison_operator       = "GreaterThanThreshold"
  alarm_actions             = [aws_sns_topic.main.arn]
  insufficient_data_actions = []
  ok_actions                = [aws_sns_topic.main.arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
    device               = "/dev/xvda1"
    fstype               = "ext4"
    path                 = "/"
  }
  tags = merge(var.tags, {
    Name = "${var.base_name}-high-disk-usage"
  })
}

resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name                = "${var.base_name}-instance-status-check"
  alarm_description         = "This metric monitors instace status check failures"
  evaluation_periods        = 2
  namespace                 = "AWS/EC2"
  metric_name               = "StatusCheckFailed_Instance"
  statistic                 = "Maximum"
  period                    = 60
  threshold                 = 0
  comparison_operator       = "GreaterThanThreshold"
  alarm_actions             = [aws_sns_topic.main.arn]
  insufficient_data_actions = []
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = merge(var.tags, {
    Name = "${var.base_name}-instance-status-check"
  })
}

resource "aws_cloudwatch_metric_alarm" "system_status_check" {
  alarm_name          = "${var.base_name}-system-status-check"
  alarm_description   = "This metric monitors ec2 system status check"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.main.arn]
  ok_actions          = []

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-system-status-check"
  })
}

resource "aws_cloudwatch_metric_alarm" "network_in" {
  alarm_name          = "${var.base_name}-high-network-in"
  alarm_description   = "This metric monitors high network input"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 100000000 # 100MB in bytes
  alarm_actions       = [aws_sns_topic.main.arn]
  ok_actions          = []

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = merge(var.tags, {
    Name = "${var.base_name}-network-in"
  })
}


# CloudWatch Dashboard for Auto Scaling Group
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.base_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.autoscaling_group_name],
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", var.autoscaling_group_name],
            [".", "disk_used_percent", ".", ".", "device", local.root_device, "fstype", "ext4", "path", "/"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ASG Resource Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.autoscaling_group_name],
            [".", "NetworkOut", ".", "."],
            [".", "NetworkPacketsIn", ".", "."],
            [".", "NetworkPacketsOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "Network Performance"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", var.autoscaling_group_name],
            [".", "StatusCheckFailed_Instance", ".", "."],
            [".", "StatusCheckFailed_System", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "Status Checks"
          period  = 300
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupMinSize", "AutoScalingGroupName", var.autoscaling_group_name],
            [".", "GroupMaxSize", ".", "."],
            [".", "GroupDesiredCapacity", ".", "."],
            [".", "GroupInServiceInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "Auto Scaling Group Metrics"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}