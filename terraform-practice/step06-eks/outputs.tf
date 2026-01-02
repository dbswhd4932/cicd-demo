# ============================================
# 출력값 정의
# ============================================

# VPC 정보
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

# EKS 클러스터 정보
output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API 서버 엔드포인트"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS 클러스터 버전"
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.main.arn
}

# kubectl 설정 명령어
output "kubectl_config_command" {
  description = "kubeconfig 설정 명령어"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

# Node Group 정보
output "node_group_name" {
  description = "EKS Node Group 이름"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_status" {
  description = "EKS Node Group 상태"
  value       = aws_eks_node_group.main.status
}
