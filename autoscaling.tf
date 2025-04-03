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
  name                = "${var.name_prefix}-asg"
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "AutoScalingGroup"
    value               = "csye6225_asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name_prefix}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
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
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Alarm when CPU exceeds 5%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "Alarm when CPU falls below 3%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
