resource "aws_eks_cluster" "main" {
  name = "${var.project_name}-${var.environment}-eks"

  version = var.cluster_version

  role_arn = var.cluster_role_arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids = var.private_subnet_ids

    security_group_ids = [
      var.cluster_security_group_id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-eks"
  }
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name

  addon_name = "eks-pod-identity-agent"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name

  node_group_name = "${var.project_name}-${var.environment}-nodes"

  node_role_arn = var.node_role_arn

  subnet_ids = var.private_subnet_ids

  instance_types = [
    var.node_instance_type
  ]

  capacity_type = "ON_DEMAND"

  disk_size = 30

  scaling_config {
    desired_size = var.desired_nodes

    min_size = var.min_nodes

    max_size = var.max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    environment = var.environment
    workload    = "microservices"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nodes"
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}

# -----------------------------
# VPC CNI
# -----------------------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name

  addon_name = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# -----------------------------
# CoreDNS
# -----------------------------

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name

  addon_name = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# -----------------------------
# kube-proxy
# -----------------------------

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name

  addon_name = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name

  addon_name = "aws-ebs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_pod_identity_association.ebs_csi
  ]
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name

  role_arn = var.ebs_csi_role_arn

  service_account = "ebs-csi-controller-sa"

  namespace = "kube-system"

  depends_on = [
    aws_eks_addon.pod_identity
  ]
}