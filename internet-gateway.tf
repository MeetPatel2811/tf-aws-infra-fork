resource "aws_internet_gateway" "igw" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = {
    Name = "${var.internet_gateway_name}-${each.value.id}"
  }
}
