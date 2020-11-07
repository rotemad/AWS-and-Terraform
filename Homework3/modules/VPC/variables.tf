variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "private_cidr_block" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "public_cidr_block" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "route_tables_names" {
  type    = list(string)
  default = ["public", "private-a", "private-b"]
}

data "http" "my_ip" {
  url = "http://ipv4.icanhazip.com"
}