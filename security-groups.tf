resource "aws_security_group" "app_sg" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for EC2 instances hosting web applications"
  vpc_id      = aws_vpc.vpc["main"].id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Remove the direct public ingress for HTTP/HTTPS on the application port.
  # Instead, allow the application port only from the load balancer SG.
  ingress {
    description     = "Allow Application Port from LB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }
}
