resource "aws_instance" "web_instance" {
  ami                    = var.custom_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(values(aws_subnet.public), 0).id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Attach the IAM instance profile for S3 access.
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name

  disable_api_termination     = false
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    echo "Hello World!"

    # Clear the .env file
    sudo truncate -s 0 /opt/csye6225/webapp/.env

    # Now write the new content
    sudo echo "DB_NAME=${var.db_name}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_HOST=${aws_db_instance.csye6225_rds_instance.address}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_PASSWORD=${var.db_password}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DB_USER=${var.db_user}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "PORT=${var.app_port}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "DIALECT=${var.dialect}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "S3_BUCKET_NAME=${aws_s3_bucket.s3_bucket.id}" | sudo tee -a /opt/csye6225/webapp/.env
    sudo echo "AWS_REGION=${var.region}" | sudo tee -a /opt/csye6225/webapp/.env
  EOT

  tags = {
    Name = var.instance_name
  }
}
