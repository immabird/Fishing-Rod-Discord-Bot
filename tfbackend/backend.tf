terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "http" {
    address = "http://localhost:8080/TerraformBackendState"
  }
}

provider "aws" {
  region     = "us-east-2"
}
