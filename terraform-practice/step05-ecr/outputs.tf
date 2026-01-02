# ============================================
# 출력값 정의
# ============================================

output "repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.app.arn
}

output "repository_name" {
  description = "ECR Repository 이름"
  value       = aws_ecr_repository.app.name
}

output "registry_id" {
  description = "ECR Registry ID (AWS 계정 ID)"
  value       = aws_ecr_repository.app.registry_id
}

# Docker 로그인 명령어
output "docker_login_command" {
  description = "ECR 로그인 명령어"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Docker Push 예시
output "docker_push_example" {
  description = "이미지 Push 예시"
  value       = "docker tag myapp:latest ${aws_ecr_repository.app.repository_url}:v1.0.0 && docker push ${aws_ecr_repository.app.repository_url}:v1.0.0"
}

# ============================================
# CodeCommit 출력값
# ============================================

output "codecommit_app_clone_url_https" {
  description = "애플리케이션 코드 저장소 HTTPS Clone URL"
  value       = aws_codecommit_repository.app.clone_url_http
}

output "codecommit_app_clone_url_ssh" {
  description = "애플리케이션 코드 저장소 SSH Clone URL"
  value       = aws_codecommit_repository.app.clone_url_ssh
}

output "codecommit_k8s_clone_url_https" {
  description = "K8s 매니페스트 저장소 HTTPS Clone URL"
  value       = aws_codecommit_repository.k8s.clone_url_http
}

output "codecommit_k8s_clone_url_ssh" {
  description = "K8s 매니페스트 저장소 SSH Clone URL"
  value       = aws_codecommit_repository.k8s.clone_url_ssh
}
