# Create the webservers
resource "aws_instance" "web-servers" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.gen_key.key_name
  count                       = 2
  subnet_id                   = module.VPC.public-subnets
  associate_public_ip_address = "true"
  vpc_security_group_ids      = module.VPC.public-sg
  user_data                   = var.user_data

  tags = {
    Name    = "web-server-${count.index + 1}"
    Owner   = "Rotem-a"
    Purpose = "Homework-task"
  }
}

/*# Create the DBs
resource "aws_instance" "db-servers" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.gen_key.key_name
  count                       = 2
  subnet_id                   = module.VPC.private-subnets
  associate_public_ip_address = "false"
  vpc_security_group_ids      = module.VPC.private-sg

  tags = {
    Name    = "db-server-${count.index + 1}"
    Owner   = "Rotem-a"
    Purpose = "Homework-task"
  }
}*/

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
  sensitive_content = tls_private_key.gen_key.private_key_pem
  filename          = "gen_key.pem"
}