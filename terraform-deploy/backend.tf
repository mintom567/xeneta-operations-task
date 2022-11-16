terraform {
  backend "s3" {
    bucket = "xeneta-rates-tf-state"
    key    = "rates/terraform.tfstate"
    region = var.aws_region
  }
}