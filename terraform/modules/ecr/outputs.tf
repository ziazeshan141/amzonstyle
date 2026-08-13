output "repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.services :
    name => repository.repository_url
  }
}

output "repository_arns" {
  value = {
    for name, repository in aws_ecr_repository.services :
    name => repository.arn
  }
}