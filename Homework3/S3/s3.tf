resource "aws_s3_bucket" "terraform-state" {
  bucket = "my-terraform-state"

  versioning {
    enabled = true
  }  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform-state-lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Lock"  
  attribute {
    name = "Lock"
    type = "S"
  }
}