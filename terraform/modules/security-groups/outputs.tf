output "cluster_security_group_id" {
  description = "EKS control plane security group ID"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_security_group_arn" {
  description = "EKS control plane security group ARN"
  value       = aws_security_group.eks_cluster.arn
}

output "node_security_group_id" {
  description = "EKS worker node security group ID"
  value       = aws_security_group.eks_nodes.id
}

output "node_security_group_arn" {
  description = "EKS worker node security group ARN"
  value       = aws_security_group.eks_nodes.arn
}
