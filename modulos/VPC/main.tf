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

# Fase 5 : Diseño y configuracion de los SG
resource "aws_security_group" "sg_alb" {
  name        = "SG-ALB-${var.Region_name}"
  description = "Grupo de seguridad para el ALB"
  vpc_id      = aws_vpc.main.id

  ingress  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  
  ingress  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-ALB-${var.Region_name}"
  }
}

resource "aws_security_group" "sg_app" {
  name         = "SG-APP-${var.Region_name}"
  description  = "Grupo de seguridad para la capa de aplicacion"
  vpc_id       = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "SG-APP-${var.Region_name}"
  }
}

resource "aws_security_group" "sg_db" {
  name         = "SG-DB-${var.Region_name}"
  description  = "Grupo de seguridad para la capa de base de datos"
  vpc_id       = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  } 

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "SG-DB-${var.Region_name}"
  }
}

# Fase 6 Configuracion de los Balanceadores de Carga
resource "aws_lb" "alb" {
  name               = "ALB-${var.Region_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = aws_subnet.public_web[*].id 
  enable_deletion_protection = false 

  tags = {
    Name = "ALB-${var.Region_name}"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "TG-App-${var.Region_name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name = "TG-App-${var.Region_name}"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

