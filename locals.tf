provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name_prefix    = "wigor-techtask"
  region  = "eu-central-1"
  region2 = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  
  container_name = "ecsdemo-frontend"
  container_port = 8080

  tags = {
    Name       = local.name_prefix
  }
}
