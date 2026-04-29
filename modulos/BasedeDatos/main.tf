terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}
#Fase 10: Configuracion de Instancias para las BD 
resource "aws_db_subnet_group" "db_group" {
  name       = "db-subnet-group-${lower(var.Region_name)}"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "DB-Subnet-Group-${var.Region_name}" }
}

resource "aws_db_instance" "gis_db" {
  identifier           = "db-gis-${lower(var.Region_name)}"
  engine               = "postgres"
  engine_version       = "15.4" 
  instance_class       = "db.t3.micro"
  allocated_storage     = 10
  replicate_source_db    = var.replicate_source_db 
  
  username               = var.replicate_source_db == null ? var.db_user : null
  password               = var.replicate_source_db == null ? var.db_password : null
  db_name                = var.replicate_source_db == null ? var.db_name : null
  
  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  
  vpc_security_group_ids = [var.db_sg_id]
  
  multi_az               = var.replicate_source_db == null ? true : false
  
  skip_final_snapshot  = true
  publicly_accessible  = false
}

output "db_instance_arn" {
  value       = aws_db_instance.gis_db.arn
  description = "ARN de la base de datos principal para la réplica"
}

output "db_instance_id" {
  value       = aws_db_instance.gis_db.id
  description = "ID de la instancia para seguimiento"
}
