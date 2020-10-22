output "web-servers-public" {
    value = aws_instance.web-servers.*.public_ip
}
output "web-servers-internal" {
    value = aws_instance.web-servers.*.private_ip
}
output "db-servers-internal" {
    value = aws_instance.web-servers.*.private_ip
}
