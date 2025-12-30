# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# ECR
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

# CodeCommit
output "codecommit_app_clone_url_http" {
  description = "CodeCommit App Repository Clone URL (HTTPS)"
  value       = aws_codecommit_repository.app.clone_url_http
}

output "codecommit_k8s_clone_url_http" {
  description = "CodeCommit K8s Repository Clone URL (HTTPS)"
  value       = aws_codecommit_repository.k8s.clone_url_http
}

# EKS
output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.main.endpoint
}

# kubectl 설정 명령어
output "configure_kubectl" {
  description = "kubectl 설정 명령어"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

# ECR 로그인 명령어
output "ecr_login_command" {
  description = "ECR 로그인 명령어"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}

# AWS 계정 ID
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
