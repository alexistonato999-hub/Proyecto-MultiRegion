terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}
# Fase 10: Computo capa web y capa de aplicacion
resource "aws_launch_template" "web_server_lt" {
  name_prefix   = "LT-WEB-${var.Region_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true 
    security_groups             = [var.sg_alb_id] #
  }

  user_data = base64encode("# Para la instalación de QGIS Mapserver")
}

resource "aws_autoscaling_group" "asg_web" {
  name                = "ASG-WEB-${var.Region_name}"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  target_group_arns   = [var.tg_web_arn]
  vpc_zone_identifier = var.public_subnets 

  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "app_server_lt" {
  name_prefix   = "LT-APP-${var.Region_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.sg_app_id] 
  }

  user_data = base64encode("#Para la instalación lógica QGIS")
}

resource "aws_autoscaling_group" "asg_app" {
  name                = "ASG-APP-${var.Region_name}"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = var.private_subnets 

  launch_template {
    id      = aws_launch_template.app_server_lt.id
    version = "$Latest"
  }
}