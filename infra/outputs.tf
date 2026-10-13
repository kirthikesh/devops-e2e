output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repositories" {
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "external_secrets_role_arn" {
  value = module.external_secrets_irsa.iam_role_arn
}

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}
