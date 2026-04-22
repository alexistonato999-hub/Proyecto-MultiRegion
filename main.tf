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