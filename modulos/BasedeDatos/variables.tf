variable "Region_name" { type = string }
variable "vpc_id"      { type = string }
variable "db_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs de subredes privadas para la base de datos"
}
variable "db_sg_id" {
  type        = string
  description = "ID del Security Group para el tráfico de la DB"
}
variable "replicate_source_db" {
  type        = string
  default     = null
  description = "ARN de la instancia de DB origen (solo para réplicas)"
}
variable "db_user" {
  type    = string
  default = "admin_gis"
}
variable "db_name" {
  type    = string
  default = "gis_database"
}
variable "db_password" {
  type      = string
  sensitive = true
  default   = null
}