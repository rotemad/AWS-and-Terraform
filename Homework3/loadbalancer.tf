# Create the Load-balancer
resource "aws_lb" "web-lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.VPC.public-subnets-for-lb
  security_groups    = module.VPC.public-sg

  /*access_logs {
    bucket  = aws_s3_bucket.web-logs.bucket
    prefix  = "lb-web-logs"
    enabled = true
  }*/

  tags = {
    Name = "web-lb"
  }
}

resource "aws_lb_listener" "web-lb" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-lb-target-group.arn
  }
}

resource "aws_lb_target_group" "web-lb-target-group" {
  name     = "web-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.VPC.vpc-id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
  }
  health_check {
    enabled = true
    path    = "/"
  }

  tags = {
    Name = "web-lb"
  }
}

resource "aws_lb_target_group_attachment" "web-servers-target" {
  count            = length(aws_instance.web-servers)
  target_group_arn = aws_lb_target_group.web-lb-target-group.id
  target_id        = aws_instance.web-servers.*.id[count.index]
  port             = 80
}

/*# S3 bucket for the LB logs
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "web-logs" {
  bucket = "web-servers-logs"
  force_destroy = true
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::web-servers-logs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}/*