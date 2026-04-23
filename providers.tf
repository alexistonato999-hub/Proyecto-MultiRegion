terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "Region-Activa-A"
  region = "us-east-1"
}

provider "aws" {
  alias  = "Region-Pasiva-B"
  region = "eu-west-2" 
}