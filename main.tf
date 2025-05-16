provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source     = "./modules/vpc"
  project    = var.project
  aws_region = var.aws_region # ✅ 加這行
}

module "eip" {
  source = "./modules/eip"
}

module "nat" {
  source    = "./modules/nat"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_id
  eip_id    = module.eip.eip_id
}

module "route" {
  source         = "./modules/route"
  private_rt_id  = module.vpc.private_route_table_id
  nat_gateway_id = module.nat.nat_gateway_id
}

module "ec2" {
  source             = "./modules/ec2"
  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnet_id
  private_subnet_ids = module.vpc.private_subnet_ids
  manager_key_pair   = var.key_pair_name
}
