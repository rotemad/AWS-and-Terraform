variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "rotemad"
}

variable "user_data" {
  default = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install awscli nginx -y
              instanceId=$(curl http://169.254.169.254/latest/meta-data/local-hostname) 
              echo $instanceId > /var/www/html/index.nginx-debian.html 
              sudo systemctl start nginx.service
              sudo systemctl enable nginx.service
              (crontab -l 2>/dev/null; echo " @hourly awscli s3 cp /var/log/nginx/access.log s3://web-logs/$instanceId-log.txt") | crontab -
              EOF
}