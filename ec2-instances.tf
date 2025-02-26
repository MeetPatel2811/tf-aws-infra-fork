resource "aws_instance" "web_instance" {
  ami                    = var.custom_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(values(aws_subnet.public), 0).id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  disable_api_termination     = false
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  tags = {
    Name = var.instance_name
  }
}
