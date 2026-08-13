output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.main.arn
}

output "cluster_security_group_id" {
  value = var.cluster_security_group_id
}

output "node_group_name" {
  value = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  value = var.node_role_arn
}