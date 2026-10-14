terraform {
  backend "s3" {
    bucket = "sheriff-tf-backend"
    key = "nat/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}