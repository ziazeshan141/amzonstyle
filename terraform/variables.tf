variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "node_instance_type" {
  description = "EKS managed node instance type"
  type        = string
}

variable "desired_nodes" {
  description = "Desired number of nodes"
  type        = number
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
}

variable "ecr_repositories" {
  description = "ECR repository names"
  type        = list(string)
}

variable "admin_principal_arn" {
  description = "IAM principal allowed to administer the EKS cluster"
  type        = string
}
