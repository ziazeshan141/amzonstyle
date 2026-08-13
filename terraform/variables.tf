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
  description = "EC2 instance type for EKS nodes"
  type        = string
}

variable "desired_nodes" {
  description = "Desired worker nodes"
  type        = number
}

variable "min_nodes" {
  description = "Minimum worker nodes"
  type        = number
}

variable "max_nodes" {
  description = "Maximum worker nodes"
  type        = number
}

variable "ecr_repositories" {
  description = "ECR repositories"
  type        = list(string)
}