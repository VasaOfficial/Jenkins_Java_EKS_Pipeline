module "vpc" {
  source = "./modules/vpc"
}

module "security_groups" {
  source = "./modules/security_groups"
}

module "ec2" {
  source = "./modules/ec2"
}

module "eks" {
  source = "./modules/eks"
}