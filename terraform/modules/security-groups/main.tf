# -----------------------------
# EKS Cluster Security Group
# -----------------------------

resource "aws_security_group" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-sg"

  description = "Security group for EKS control plane"

  vpc_id = var.vpc_id

  ingress {
    description = "HTTPS from VPC"

    protocol = "tcp"

    from_port = 443
    to_port   = 443

    cidr_blocks = [
      var.vpc_cidr
    ]
  }

  egress {
    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  }
}

# -----------------------------
# EKS Node Security Group
# -----------------------------

resource "aws_security_group" "nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-sg"

  description = "Security group for EKS worker nodes"

  vpc_id = var.vpc_id

  ingress {
    description = "Node to node communication"

    protocol = "-1"

    from_port = 0
    to_port   = 0

    self = true
  }

  ingress {
    description = "Cluster to worker nodes"

    protocol = "tcp"

    from_port = 1025
    to_port   = 65535

    cidr_blocks = [
      var.vpc_cidr
    ]
  }

  ingress {
    description = "Kubernetes API"

    protocol = "tcp"

    from_port = 443
    to_port   = 443

    cidr_blocks = [
      var.vpc_cidr
    ]
  }

  egress {
    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-node-sg"
  }
}