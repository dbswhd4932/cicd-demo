# ============================================
# 변수 정의
# ============================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "cicd-tf"
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "가용영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# EKS 설정
variable "cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  description = "워커 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "워커 노드 Desired 개수"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "워커 노드 최소 개수"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "워커 노드 최대 개수"
  type        = number
  default     = 3
}
