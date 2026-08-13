output "cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_role_name" {
  description = "EKS cluster IAM role name"
  value       = aws_iam_role.eks_cluster.name
}

output "node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = aws_iam_role.eks_nodes.arn
}

output "node_role_name" {
  description = "EKS node IAM role name"
  value       = aws_iam_role.eks_nodes.name
}

output "ebs_csi_role_arn" {
  description = "EBS CSI Pod Identity IAM role ARN"
  value       = aws_iam_role.ebs_csi.arn
}
