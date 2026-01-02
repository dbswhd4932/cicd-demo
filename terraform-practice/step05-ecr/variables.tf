# ============================================
# 변수 정의
# ============================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "step05"
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

variable "image_count_to_keep" {
  description = "보관할 이미지 개수"
  type        = number
  default     = 10
}
