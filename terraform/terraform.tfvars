aws_region = "us-east-1"

project_name = "microservices"

environment = "dev"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

eks_cluster_version = "1.35"

node_instance_type = "t3.medium"

desired_nodes = 3

min_nodes = 2

max_nodes = 5

admin_principal_arns = [
  "arn:aws:iam::047385030300:user/Zeshan",
  "arn:aws:iam::047385030300:user/terraform"
]

ecr_repositories = [
  "auth-service",
  "user-service",
  "product-service",
  "cart-service",
  "order-service",
  "payment-service",
  "notification-service",
  "api-gateway",
  "frontend",
  "catalog-service",
  "inventory-service",
  "shipping-service",
  "recommendation-service",
  "review-service",
  "search-service"
]