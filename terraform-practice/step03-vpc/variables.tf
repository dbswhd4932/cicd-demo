# ============================================
# 변수 정의
# ============================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "step03"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}
