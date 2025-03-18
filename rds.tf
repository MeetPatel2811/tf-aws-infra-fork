resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS security group allowing traffic only from the application security group"
  vpc_id      = aws_vpc.vpc["main"].id

  ingress {
    description     = "Allow DB access from application SG"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_db_parameter_group" "rds_param_group" {
  name        = "csye6225-param-group"
  family      = var.db_parameter_group_family
  description = "Custom parameter group for csye6225 database"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "csye6225-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags = {
    Name = "csye6225-subnet-group"
  }
}

resource "aws_db_instance" "csye6225_rds_instance" {
  identifier             = "csye6225"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = var.db_storage_type
  username               = var.db_user
  password               = var.db_password
  db_name                = var.db_name
  parameter_group_name   = aws_db_parameter_group.rds_param_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  tags = {
    Name = "csye6225-rds"
  }
}
