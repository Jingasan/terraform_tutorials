terraform {
  required_version = ">= 0.15"

  required_providers {
    aws = ">=3.44.0"
  }

  # backend "s3" {
  #   bucket                  = "s3-tfstate-bucket"
  #   key                     = "terraform.tfstate"
  #   region                  = "ap-northeast-1"
  #   shared_credentials_file = "$HOME/.aws/credentials"
  #   profile                 = "default"
  # }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"
}