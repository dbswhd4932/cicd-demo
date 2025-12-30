# 프로젝트 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "cicd-demo"
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  default     = "dev"
}

# AWS 설정
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# EKS 설정
variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_type" {
  description = "EKS 노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "EKS 노드 개수"
  type        = number
  default     = 2
}

# 네트워크 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}
