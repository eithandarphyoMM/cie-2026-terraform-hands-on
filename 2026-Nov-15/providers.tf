terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.29.0"
    }
  }
}

provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

# provider "aws" {
#   alias  = "tokyo"
#   region = "ap-northeast-1"
# }