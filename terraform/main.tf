data "aws_availability_zones" "available" { state = "available" }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0"
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  public_subnet_tags = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.0"
  cluster_name = var.cluster_name
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_groups = {
    default = {
      min_size = 2
      max_size = 4
      desired_size = 2
      instance_types = var.instance_types
    }
  }
}

resource "aws_ecr_repository" "services" {
  for_each = toset([
    "api-gateway","auth-service","user-service","product-service","catalog-service","search-service","cart-service","order-service","payment-service","inventory-service","shipping-service","review-service","recommendation-service","notification-service","frontend"
  ])
  name = "amazon-microservices/${each.key}"
  image_scanning_configuration { scan_on_push = true }
}
