terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "http" {
    address = "http://localhost:8080/FishingRodBot"
  }
}

provider "aws" {
  region = "us-east-2"
}
