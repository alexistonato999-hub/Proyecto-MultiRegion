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