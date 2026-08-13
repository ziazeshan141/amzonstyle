variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "ebs_csi_role_arn" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "desired_nodes" {
  type = number
}

variable "min_nodes" {
  type = number
}

variable "max_nodes" {
  type = number
}

variable "admin_principal_arn" {
  description = "IAM principal that will administer the EKS cluster"
  type        = string
}