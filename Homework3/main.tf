terraform {
backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    profile = "rotemad"
    }
}
module "VPC" {
  source = "./modules/VPC"
}