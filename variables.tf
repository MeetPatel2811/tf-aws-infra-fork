variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "demo"
}

variable "region" {
  description = "AWS region where all VPCs will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_names" {
  description = "Map of VPC names"
  type        = map(string)
  default = {
    main = "CSYE-VPC1"
  }
}

variable "vpc_cidrs" {
  description = "Map of CIDR blocks for the VPCs"
  type        = map(string)
  default = {
    main = "10.0.0.0/16"
  }
}

variable "public_subnet_cidrs" {
  description = "Map of lists of CIDRs for public subnets for each VPC"
  type        = map(list(string))
  default = {
    main = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  }
}

variable "private_subnet_cidrs" {
  description = "Map of lists of CIDRs for private subnets for each VPC"
  type        = map(list(string))
  default = {
    main = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
}

variable "internet_gateway_name" {
  description = "Name tag for the Internet Gateway"
  type        = string
  default     = "tf-aws-igw"
}

variable "public_route_table_name" {
  description = "Name tag for the public route table"
  type        = string
  default     = "tf-aws-public-rt"
}

variable "private_route_table_name" {
  description = "Name tag for the private route table"
  type        = string
  default     = "tf-aws-private-rt"
}

variable "public_route_dest_cidr" {
  description = "Destination CIDR block for the public route (typically 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_zones" {
  description = "List of availability zones to use for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "name_prefix" {
  description = "Prefix for naming resources to ensure uniqueness"
  type        = string
  default     = "csye"
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  default     = "csye-web-instance"
}

variable "custom_ami_id" {
  description = "Custom AMI ID built via Packer (using a default AMI for now)"
  type        = string
  default     = "ami-0dba2cb6798deb6d8"
}

variable "instance_type" {
  description = "EC2 instance type for the web application"
  type        = string
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume for the EC2 instance in GB"
  type        = number
  default     = 25
}

variable "root_volume_type" {
  description = "Type of the root volume for the EC2 instance (e.g., gp2)"
  type        = string
  default     = "gp2"
}

variable "app_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8080
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the instance"
  type        = string
  default     = "Cloud_App"
}
