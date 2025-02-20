// Create a public route table for each VPC
resource "aws_route_table" "public" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = {
    Name = "${var.public_route_table_name}-${each.value.id}"
  }
}

// Create a route in each public route table to allow internet access
resource "aws_route" "public_internet_access" {
  for_each = aws_vpc.vpc

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = var.public_route_dest_cidr
  gateway_id             = aws_internet_gateway.igw[each.key].id
}

// Associate public subnets with the appropriate public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  // Extract the vpc_key from the for_each key: "vpc_key-index"
  route_table_id = aws_route_table.public[split("-", each.key)[0]].id
}

// Create a private route table for each VPC
resource "aws_route_table" "private" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = {
    Name = "${var.private_route_table_name}-${each.value.id}"
  }
}

// Associate private subnets with the appropriate private route table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id
  // Extract the vpc_key from the for_each key: "vpc_key-index"
  route_table_id = aws_route_table.private[split("-", each.key)[0]].id
}
