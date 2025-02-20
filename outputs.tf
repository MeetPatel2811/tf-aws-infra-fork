output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = [for v in aws_vpc.vpc : v.id]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for s in aws_subnet.private : s.id]
}
