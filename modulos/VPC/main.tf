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

# Fase 3: Diseño de las puertas de enlace IGW y NATGW 
resource "aws_internet_gateway" "igw_subnet_public" {
  vpc_id        = aws_vpc.main.id

  tags = {
    Name = "IGW-${var.Region_name}"
  }
}

resource "aws_eip" "nat_eip" {
  domain        = "vpc"

  tags = {
    Name = "ELASTIC-IP-NAT-GW-${var.Region_name}"
  }
}

resource "aws_nat_gateway" "natgw_subnet_private" {
  subnet_id     = aws_subnet.public_web[0].id
  allocation_id = aws_eip.nat_eip.id

  tags = {
    Name = "NAT-GW-${var.Region_name}"
  }
}

# Fase 4 Configuracion de tablas de enrutamiento
resource "aws_route_table" "rt_igw" {
  vpc_id         = aws_vpc.main.id

  route {
    cidr_block   = "0.0.0.0/0"
    gateway_id   = aws_internet_gateway.igw_subnet_public.id
  }
  tags = {
    Name = "Route-Table-IGW-${var.Region_name}"
  }
}

resource "aws_route_table_association" "association_subnet_public" {
  count          = 2
  subnet_id      = aws_subnet.public_web[count.index].id
  route_table_id = aws_route_table.rt_igw.id
}

resource "aws_route_table" "rt_nat_gw" {
  vpc_id           = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_subnet_private.id
  }
  tags = {
    Name = "Route-Table-NAT-GW-${var.Region_name}"
  }
}

resource "aws_route_table_association" "association_privateapp" {
  count            = 2
  subnet_id        = aws_subnet.private_app[count.index].id
  route_table_id   = aws_route_table.rt_nat_gw.id
}

resource "aws_route_table_association" "association_privatedb" {
  count            = 2
  subnet_id        = aws_subnet.private_db[count.index].id
  route_table_id   = aws_route_table.rt_nat_gw.id
}