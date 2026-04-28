variable "Region_name"     { type = string }
variable "ami_id"          { type = string }
variable "instance_type"   { type = string }
variable "public_subnets"  { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "sg_alb_id"       { type = string }
variable "sg_app_id"       { type = string }
variable "tg_web_arn"      { type = string }
variable "vpc_id" {
  type        = string
  description = "ID de la VPC para asociar los recursos de cómputo"
}