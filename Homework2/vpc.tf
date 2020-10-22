# VPC:
resource "aws_vpc" "homework-vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "homework-vpc"
  }
}

# Public and private subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "homework-public-subnet" {
  vpc_id            = aws_vpc.homework-vpc.id
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.public_cidr_block[count.index]
  tags = {
    Name = "homework-public-subnet ${count.index + 1}"
  }
}
resource "aws_subnet" "homework-private-subnet" {
  vpc_id            = aws_vpc.homework-vpc.id
  count             = 2
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

# NAT gateway
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.homework-public-subnet[0].id
  depends_on    = [aws_internet_gateway.homework-gw]
  tags = {
    Name = "homework-nat-gw"
  }
}

# Routeing
resource "aws_route_table" "public-subnet-route" {
  vpc_id = aws_vpc.homework-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.homework-gw.id
  }
  tags = {
    "Name" = "public-subnet-route"
  }
}

resource "aws_route_table" "private-subnet-route" {
  vpc_id = aws_vpc.homework-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    "Name" = "private-subnet-route"
  }
}

resource "aws_route_table_association" "to-public-subnet-route" {
  count = length(var.public_cidr_block)
  subnet_id = aws_subnet.homework-public-subnet[count.index].id
  route_table_id = aws_route_table.public-subnet-route.id
}

# Create a secutiry group with HTTP,SSH and ICMP allowed:
resource "aws_security_group" "homework-sg" {
  name   = "homework-sg"
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