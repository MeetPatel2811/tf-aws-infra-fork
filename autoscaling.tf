resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = var.custom_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(<<-EOT
    #!/bin/bash
    sudo truncate -s 0 /opt/csye6225/webapp/.env
    sudo echo "DB_NAME=${var.db_name}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_HOST=${aws_db_instance.csye6225_rds_instance.address}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_PASSWORD=${var.db_password}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_USER=${var.db_user}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "PORT=${var.app_port}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DIALECT=${var.dialect}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "S3_BUCKET_NAME=${aws_s3_bucket.s3_bucket.id}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "AWS_REGION=${var.region}" | sudo tee -a /opt/csye6225/webapp/.env

    sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOL
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/csye6225.log",
                "log_group_name": "csye6225-app-logs",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      },
      "metrics": {
        "namespace": "CSYE62257/EC2/CloudWatch",
        "metrics_collected": {
          "statsd": {
            "service_address": ":8125",
            "metrics_collection_interval": 10,
            "metrics_aggregation_interval": 60
          }
        }
      }
    }
    EOL

    sudo systemctl restart amazon-cloudwatch-agent
    sudo systemctl daemon-reload
    sudo systemctl restart csye6225.service
  EOT
  )
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.web_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

  tags = {
    Name = "${var.name_prefix}-launch-template"
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.name_prefix}-asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"
  vpc_zone_identifier       = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "AutoScalingGroup"
    value               = "csye6225_asg"
    propagate_at_launch = true
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.asg_min_healthy_percentage
      instance_warmup        = var.asg_instance_warmup
    }
    triggers = ["launch_template"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn    = aws_lb_target_group.web_target_group.arn
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name_prefix}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  depends_on             = [aws_autoscaling_attachment.asg_attachment]
  cooldown               = var.cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name_prefix}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.cooldown
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_high_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Alarm when CPU exceeds ${var.cpu_high_threshold}%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_low_period
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "Alarm when CPU falls below ${var.cpu_low_threshold}%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
