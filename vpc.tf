resource "aws_vpc" "vpc" {
  for_each = var.vpc_names

   cidr_block = var.vpc_cidrs1[each.key]

  tags = {
    Name = each.value
  }
}
