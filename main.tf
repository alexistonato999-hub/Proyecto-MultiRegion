module "VPC_Region_A" {
  source = "./modulos/vpc"
  providers = {aws = aws.Region-Activa-A}
  cidr_block= "172.16.0.0/16"
  Region_name = "Region-Activa"
}

module "VPC_Region_B" {
  source = "./modulos/vpc"
  providers = {aws = aws.Region-Pasiva-B}
  cidr_block= "10.20.0.0/16"
  Region_name = "Region-Pasiva"
}

# Fase 7: Conexion entre VPCs
resource "aws_vpc_peering_connection" "virginia_to_london" {
  provider      = aws.Region-Activa-A
  peer_vpc_id   = module.VPC_Region_B.vpc_id
  vpc_id        = module.VPC_Region_A.vpc_id
  peer_region   = "eu-west-2"
  auto_accept   = false

  tags = {
    Name = "Peering-Virginia-Londres"
  }
}

resource "aws_vpc_peering_connection_accepter" "london_accept" {
  provider                  = aws.Region-Pasiva-B
  vpc_peering_connection_id = aws_vpc_peering_connection.virginia_to_london.id
  auto_accept               = true

  tags = {
    Name = "Peering-Aceptado-Londres"
  }
}

# Fase 8: Configuracion de healt checks con Amazon Route 53
resource "aws_route53_health_check" "virginia_health" {
  provider          = aws.Region-Activa-A
  fqdn              = module.VPC_Region_A.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = { Name = "Monitor-Virginia" }
}

# Zona Hospedada (Pruebas)
resource "aws_route53_zone" "main" {
  provider = aws.Region-Activa-A
  name = "tutesis.com"
}

resource "aws_route53_record" "primary" {
  provider = aws.Region-Activa-A
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.tutesis.com"
  type    = "A"

  alias {
    name                   = module.VPC_Region_A.alb_dns_name
    zone_id                = module.VPC_Region_A.alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "Virginia-Active"
  health_check_id = aws_route53_health_check.virginia_health.id
}

resource "aws_route53_record" "secondary" {
  provider = aws.Region-Pasiva-B
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.tutesis.com"
  type    = "A"

  alias {
    name                   = module.VPC_Region_B.alb_dns_name
    zone_id                = module.VPC_Region_B.alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "London-Passive"
}

# Fase 9: Distribución de CloudFront y asociacion a ALBs
resource "aws_cloudfront_distribution" "main_distribution" {
  provider = aws.Region-Activa-A
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribución Global para Sistema de Respaldo Multi-Región"
  default_root_object = "index.html"

  origin {
    domain_name = module.VPC_Region_A.alb_dns_name
    origin_id   = "ALB-Virginia"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # añadir el certificado SSL
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = module.VPC_Region_B.alb_dns_name
    origin_id   = "ALB-London"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Virginia" 

    forwarded_values {
      query_string = true
      cookies { forward = "all" }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Entorno = "Produccion"
  }
}