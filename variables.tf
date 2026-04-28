# --- CONFIGURACIÓN GLOBAL ---
variable "project_name" {
  type    = string
  default = "Tesis-MultiRegion"
}

# --- CÓMPUTO ---
variable "tipo_instancia" {
  type    = string
  default = "t3.micro"
}

# --- BASE DE DATOS ---
variable "db_name" {
  type    = string
  default = "db_tesis"
}

variable "db_user" {
  type    = string
}

variable "db_password" {
  type      = string
  sensitive = true # Protege la contraseña en los logs de la terminal
}