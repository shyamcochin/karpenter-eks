# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.default_tags,
    {
      Name                                          = "${var.project}-${var.env}-${var.app}-vpc"
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    }
  )
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.default_tags,
    {
      Name                                          = "${var.project}-${var.env}-${var.app}-public-subnet-${count.index + 1}"
      "kubernetes.io/role/elb"                      = 1
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    }
  )
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.default_tags,
    {
      Name                                          = "${var.project}-${var.env}-${var.app}-private-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb"             = "1"
      "karpenter.sh/discovery"                      = local.cluster_name
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    }
  )
}

resource "aws_subnet" "isolated" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-isolated-subnet-${count.index + 1}"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-igw"
    }
  )
}

resource "aws_eip" "nat" {
  count  = var.create_nat ? 1 : 0
  domain = "vpc"

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.create_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-nat-gateway"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-public-rt"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.create_nat ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-private-rt"
    }
  )
}

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-isolated-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "isolated" {
  count          = 2
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# Default Network ACL
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-default-nacl"
    }
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# Default Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-${var.env}-${var.app}-default-sg"
    }
  )
}


# # Network ACLs
# resource "aws_network_acl" "public" {
#   vpc_id     = aws_vpc.main.id
#   subnet_ids = aws_subnet.public[*].id

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   ingress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name = "${var.project}-${var.env}-${var.app}-public-nacl"
#   }
# }

# resource "aws_network_acl" "private" {
#   vpc_id     = aws_vpc.main.id
#   subnet_ids = aws_subnet.private[*].id

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   ingress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name = "${var.project}-${var.env}-${var.app}-private-nacl"
#   }
# }

# resource "aws_network_acl" "isolated" {
#   vpc_id     = aws_vpc.main.id
#   subnet_ids = aws_subnet.isolated[*].id

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   ingress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name = "${var.project}-${var.env}-${var.app}-isolated-nacl"
#   }
# }
