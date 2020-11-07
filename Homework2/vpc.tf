# VPC:
resource "aws_vpc" "homework-vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "homework-vpc"
  }
}

# Public and private subnets
resource "aws_subnet" "homework-public-subnet" {
  vpc_id            = aws_vpc.homework-vpc.id
  count             = length(var.public_cidr_block)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.public_cidr_block[count.index]

  tags = {
    Name = "homework-public-subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "homework-private-subnet" {
  vpc_id            = aws_vpc.homework-vpc.id
  count             = length(var.private_cidr_block)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_cidr_block[count.index]

  tags = {
    Name = "homework-private-subnet ${count.index + 1}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "homework-gw" {
  vpc_id = aws_vpc.homework-vpc.id

  tags = {
    Name = "homework-gateway"
  }
}

# NAT gateways
resource "aws_eip" "nat_gateway" {
  vpc   = true
  count = length(var.public_cidr_block)

  # added tags to eips
  tags = {
    Name = "homework-eip ${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  count         = length(var.public_cidr_block)
  allocation_id = aws_eip.nat_gateway.*.id[count.index]
  subnet_id     = aws_subnet.homework-public-subnet.*.id[count.index]
  depends_on    = [aws_internet_gateway.homework-gw]

  tags = {
    Name = "homework-nat-gw ${count.index + 1}"
  }
}

# Routeing
resource "aws_route_table" "route_tables" {
  count  = length(var.route_tables_names)
  vpc_id = aws_vpc.homework-vpc.id

  tags = {
    Name = var.route_tables_names[count.index]
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.route_tables[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.homework-gw.id
}

resource "aws_route" "private" {
  count                  = length(var.private_cidr_block)
  route_table_id         = aws_route_table.route_tables.*.id[count.index + 1]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.*.id[count.index]
}


resource "aws_route_table_association" "to-public-subnet-route" {
  count          = length(var.public_cidr_block)
  subnet_id      = aws_subnet.homework-public-subnet[count.index].id
  route_table_id = aws_route_table.route_tables[0].id
}

resource "aws_route_table_association" "to-private-subnet-route" {
  count          = length(var.private_cidr_block)
  subnet_id      = aws_subnet.homework-private-subnet[count.index].id
  route_table_id = aws_route_table.route_tables[count.index + 1].id
}

# Create a public secutiry group with HTTP,SSH and ICMP allowed:
resource "aws_security_group" "public-sg" {
  name   = "homework-public-sg"
  vpc_id = aws_vpc.homework-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }
  ingress {
    description = "Allow ICMP"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "homework-sg"
  }
}

# Create a public private group with HTTP,SSH and ICMP allowed:
resource "aws_security_group" "private-sg" {
  name   = "homework-private-sg"
  vpc_id = aws_vpc.homework-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "homework-db-sg"
  }
}