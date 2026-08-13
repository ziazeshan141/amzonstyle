module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

module "ecr" {
  source = "./modules/ecr"

  project_name  = var.project_name
  environment   = var.environment
  repositories  = var.ecr_repositories
}

module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_version = var.eks_cluster_version

  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_security_group_id = module.security_groups.cluster_security_group_id
  node_security_group_id    = module.security_groups.node_security_group_id

  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
  ebs_csi_role_arn = module.iam.ebs_csi_role_arn

  node_instance_type = var.node_instance_type

  desired_nodes = var.desired_nodes
  min_nodes     = var.min_nodes
  max_nodes     = var.max_nodes

  admin_principal_arns = var.admin_principal_arns
}
