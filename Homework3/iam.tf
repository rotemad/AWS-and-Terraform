# Set up s3 bucket for the webservers logs
resource "aws_s3_bucket" "web-logs" {
  bucket = "web-servers-logs"
  force_destroy = true
}

# Create IAM rule, policy and profile  

resource "aws_iam_instance_profile" "ec2-S3-profile" {
  name = "ec2-to-S3-profile"
  role = aws_iam_role.ec2-assume.name
}

resource "aws_iam_role_policy" "ec2-S3-policy" {
  name = "ec2-to-S3-policy"
  role = aws_iam_role.ec2-assume.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ec2-assume" {
  name = "ec2-assume"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      Name = "ec2-assume-rule"
  }
}
