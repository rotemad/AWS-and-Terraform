output "vpc-id" {
    description = "The IDs of the vpc"
    value = concat(aws_vpc.homework-vpc.*.id, [""])[0]
}

output "public-subnets" {
    description = "The IDs of the public subnets"
    value = concat(aws_subnet.homework-public-subnet.*.id, [""])[0]
}

output "public-subnets-for-lb" {
    description = "The IDs of the public subnets"
    value = concat(aws_subnet.homework-public-subnet.*.id)
}

output "private-subnets" {
    description = "The IDs of the private subnets"
    value = concat(aws_subnet.homework-private-subnet.*.id, [""])[0]
}

output "private-sg" {
    description = "The ID of the private security group"
    value = concat(aws_security_group.private-sg.*.id)
}

output "public-sg" {
    description = "The ID of the private security group"
    value = concat(aws_security_group.public-sg.*.id)
}