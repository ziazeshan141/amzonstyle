aws_region  = "ap-south-1"

project_name = "microservices"

environment = "dev"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

eks_cluster_version = "1.33"

node_instance_type = "t3.medium"

desired_nodes = 3

min_nodes = 2

max_nodes = 5

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