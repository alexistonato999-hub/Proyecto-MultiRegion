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
  profile = "Cloud-Infrastructure-Engineer"
}

provider "aws" {
  alias  = "Region-Pasiva-B"
  region = "eu-west-2"
  profile = "Cloud-Infrastructure-Engineer" 
}