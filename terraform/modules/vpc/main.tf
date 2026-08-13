resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# -----------------------------
# Public Subnets
# -----------------------------

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  availability_zone = var.availability_zones[count.index]

  cidr_block = "10.0.${count.index + 1}.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
  }
}

# -----------------------------
# Private Subnets
# -----------------------------

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  availability_zone = var.availability_zones[count.index]

  cidr_block = "10.0.${count.index + 11}.0/24"

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"

    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
  }
}

# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

# -----------------------------
# NAT Gateway EIPs
# -----------------------------

resource "aws_eip" "nat" {
  count = length(var.availability_zones)

  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }
}

# -----------------------------
# NAT Gateways
# -----------------------------

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[count.index].id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  }
}

# -----------------------------
# Private Route Tables
# -----------------------------

resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  }
}

resource "aws_route" "private_nat" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.private[count.index].id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id = aws_subnet.private[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}