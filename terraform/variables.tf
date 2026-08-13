variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "amazon-microservices-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
