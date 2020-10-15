#Variables definition:
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_ssh_key" {}
variable "home_ip" {}
variable "key_name" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key  
  region = "eu-west-1"
}

#Create the EC2 instance:
resource "aws_instance" "homework" {
  ami           = "ami-0bb3fad3c0286ebd5" #Amazon Linux 2 AMI
  instance_type = "t2.medium"
  key_name = var.key_name
  count = 2
  subnet_id = aws_subnet.homework-subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.homework-sg.id]
  root_block_device {
      volume_size = "15"
  }
  ebs_block_device {
      device_name = "/dev/sdb"
      volume_size = "10"
      volume_type = "gp2" #is defualt anyway - but just for the record 
      encrypted = "true"
  }
    tags = {
    Name = "homework-${count.index + 1}"
    Owner = "Rotem-a"
    Purpose = "Homework-task"
  }
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file(var.aws_ssh_key) 
    host     = self.public_ip
}
  provisioner "remote-exec" {
    inline = [
        "sudo amazon-linux-extras install nginx1 -y",
        "sudo bash -c 'echo \"OpsSchool RULES\" > /usr/share/nginx/html/index.html'",
        "sudo systemctl start nginx.service"
    ]
  }
}

#Create a dediteced VPC for this environment:
resource "aws_vpc" "homework-vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "homework-vpc"
  }
}

#Create a subnet and associate it to the above VPC:
resource "aws_subnet" "homework-subnet" {
  vpc_id = aws_vpc.homework-vpc.id
  cidr_block = "10.10.1.0/24"
  tags = {
    Name = "homework-subnet"
  }
}

#Create internet gateway
resource "aws_internet_gateway" "homework-gw" {
  vpc_id = aws_vpc.homework-vpc.id
  tags = {
    Name = "homework-gateway"
  }
}

#Create a routing table and associate it to the relevant subnet
resource "aws_default_route_table" "homework-route" {
  default_route_table_id = aws_vpc.homework-vpc.default_route_table_id
  tags = {
    "Name" = "homework-route-table"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.homework-gw.id
  }
}

#Create a secutiry group with ports HTTP,SSH and ICMP allowed:
resource "aws_security_group" "homework-sg" {
  name        = "homework-sg"
  vpc_id      = aws_vpc.homework-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.home_ip
  }
   ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.home_ip
  }
   ingress {
    description = "Allow ICMP"
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = var.home_ip
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