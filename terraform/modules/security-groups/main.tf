resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for the EKS control plane"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  }
}

# Cluster API access from worker nodes
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow EKS nodes to reach the Kubernetes API"
}

# Node kubelet/API traffic from the cluster control plane
resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
  description                  = "Allow control plane to reach worker node ports"
}

# Node-to-node communication
resource "aws_vpc_security_group_ingress_rule" "nodes_from_nodes" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "Allow worker nodes to communicate with each other"
}

# Cluster egress
resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.eks_cluster.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow EKS control plane outbound traffic"
}

# Node egress
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.eks_nodes.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow EKS nodes outbound traffic"
}
