resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.private_route_table_name
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.public_route_dest_cidr
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each      = { for idx, subnet in aws_subnet.public : idx => subnet.id }
  subnet_id     = each.value
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each      = { for idx, subnet in aws_subnet.private : idx => subnet.id }
  subnet_id     = each.value
  route_table_id = aws_route_table.private.id
}
