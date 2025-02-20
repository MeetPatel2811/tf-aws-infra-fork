locals {
  public_subnets = flatten([
    for vpc_key, vpc in aws_vpc.vpc : [
      for idx, cidr in var.public_subnet_cidrs[vpc_key] : {
        vpc_key           = vpc_key
        vpc_id            = vpc.id
        cidr_block        = cidr
        availability_zone = var.availability_zones[idx]
        name              = "${var.name_prefix}-public-${vpc.id}-${idx + 1}"
      }
    ]
  ])

  private_subnets = flatten([
    for vpc_key, vpc in aws_vpc.vpc : [
      for idx, cidr in var.private_subnet_cidrs[vpc_key] : {
        vpc_key           = vpc_key
        vpc_id            = vpc.id
        cidr_block        = cidr
        availability_zone = var.availability_zones[idx]
        name              = "${var.name_prefix}-private-${vpc.id}-${idx + 1}"
      }
    ]
  ])
}

resource "aws_subnet" "public" {
  for_each = { for idx, subnet in local.public_subnets : "${subnet.vpc_key}-${idx}" => subnet }

  vpc_id                  = each.value.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name   = each.value.name
    VpcKey = each.value.vpc_key // Optional: for clarity in the console
  }
}

resource "aws_subnet" "private" {
  for_each = { for idx, subnet in local.private_subnets : "${subnet.vpc_key}-${idx}" => subnet }

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name   = each.value.name
    VpcKey = each.value.vpc_key // Optional: for clarity in the console
  }
}
