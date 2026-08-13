output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "ecr_repository_urls" { value = { for k, v in aws_ecr_repository.services : k => v.repository_url } }
