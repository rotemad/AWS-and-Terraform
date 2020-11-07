# Get the AMI data
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Create the webservers
resource "aws_instance" "web-servers" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.gen_key.key_name
  count                       = 2
  subnet_id                   = aws_subnet.homework-public-subnet[count.index].id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.public-sg.id]
  user_data = var.user_data
  tags = {
    Name    = "web-server-${count.index + 1}"
    Owner   = "Rotem-a"
    Purpose = "Homework-task"
  }
}  

# Create the DBs
resource "aws_instance" "db-servers" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.gen_key.key_name
  count                       = 2
  subnet_id                   = aws_subnet.homework-private-subnet[count.index].id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.private-sg.id]
  tags = {
    Name    = "db-server-${count.index + 1}"
    Owner   = "Rotem-a"
    Purpose = "Homework-task"
  }
}  

# Create keys for the instances
resource "tls_private_key" "gen_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "gen_key" {
  key_name   = "gen_key"
  public_key = tls_private_key.gen_key.public_key_openssh
}

resource "local_file" "gen_key" {
  sensitive_content  = tls_private_key.gen_key.private_key_pem
  filename           = "gen_key.pem"
}

# Create the Load-balancer
resource "aws_elb" "web-loadbalancer" {
  name               = "web-servers-elb"
  #availability_zones = ["us-east-1a","us-east-1b"]
  subnets = aws_subnet.homework-public-subnet[*].id
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = aws_instance.web-servers[*].id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "web-servers-elb"
  }
}