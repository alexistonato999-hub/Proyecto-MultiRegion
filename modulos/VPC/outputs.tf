output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID de la VPC para asociar el Peering y otros recursos regionales"
}
output "public_subnet_ids" {
  value       = aws_subnet.public_web[*].id
  description = "IDs de subredes públicas donde reside el ALB"
}
output "private_app_subnet_ids" {
  value       = aws_subnet.private_app[*].id
  description = "IDs de subredes privadas para las instancias EC2 (Capa de Aplicación)"
}
output "security_group_alb_id" {
  value       = aws_security_group.sg_alb.id
  description = "SG de la web"
}
output "security_group_app_id" {
  value       = aws_security_group.sg_app.id
  description = "SG de la App para que el módulo de Cómputo pueda recibir tráfico del ALB"
}
output "security_group_db_id" {
  value       = aws_security_group.sg_db.id
  description = "SG de la DB para permitir conexiones desde la capa de aplicación"
}
output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Nombre DNS del balanceador; entrada vital para CloudFront y Route 53"
}
output "alb_zone_id" {
  value       = aws_lb.alb.zone_id
  description = "ID de zona del ALB, necesario para crear registros tipo ALIAS en Route 53"
}
output "target_group_arn" {
  value       = aws_lb_target_group.app_tg.arn
  description = "ARN del Target Group para que el Auto Scaling Group sepa dónde registrar las instancias"
}