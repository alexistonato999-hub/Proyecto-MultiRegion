variable "project_name" {
  type    = string
  default = "Tesis-MultiRegion"
}

variable "tipo_instancia" {
  type    = string
  default = "t3.micro"
}

variable "db_name" {
  type    = string
}

variable "db_user" {
  type    = string
}

variable "db_password" {
  type      = string
  sensitive = true 
}