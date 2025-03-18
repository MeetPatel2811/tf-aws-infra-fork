provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "random" {}

provider "local" {}
