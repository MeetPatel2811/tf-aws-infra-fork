resource "aws_instance" "web_instance" {
  ami                         = var.custom_ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = element(values(aws_subnet.public), 0).id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.web_instance_profile.name
  disable_api_termination     = false
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    # Configure environment variables
    sudo truncate -s 0 /opt/csye6225/webapp/.env
    sudo echo "DB_NAME=${var.db_name}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_HOST=${aws_db_instance.csye6225_rds_instance.address}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_PASSWORD=${var.db_password}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_USER=${var.db_user}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "PORT=${var.app_port}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DIALECT=${var.dialect}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "S3_BUCKET_NAME=${aws_s3_bucket.s3_bucket.id}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "AWS_REGION=${var.region}" | sudo tee -a /opt/csye6225/webapp/.env

    # Configure CloudWatch Agent
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
      "namespace": "CSYE6225/EC2/CloudWatch",
        
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

    # Start the CloudWatch Agent
    sudo systemctl restart amazon-cloudwatch-agent

    # Reload systemd configuration and restart the application service
    sudo systemctl daemon-reload
    sudo systemctl restart csye6225.service

  EOT

  tags = {
    Name = var.instance_name
  }
}