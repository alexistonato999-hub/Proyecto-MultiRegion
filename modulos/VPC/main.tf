terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "VPC-${var.Region_name}"
    Proyecto    = "Tesis-MultiRegion"
    Entorno     = "Produccion"
  }
}

# Fase 2: Diseño de Subredes Publicas y Privadas
resource "aws_subnet" "public_web" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  

  tags = {
    Name = "Subnet-Public-${count.index + 1}-${var.Region_name}"
  }
}

resource "aws_subnet" "private_app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Subnet-App-${count.index + 1}-${var.Region_name}"
  }
}

resource "aws_subnet" "private_db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Subnet-DB-${count.index + 1}-${var.Region_name}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

