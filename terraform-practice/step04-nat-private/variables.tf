# ============================================
# 변수 정의 (프로덕션 레벨)
# ============================================

# 프로젝트 기본 설정
variable "project_name" {
  description = "프로젝트 이름 (리소스 이름에 사용)"
  type        = string
  default     = "step04"
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
  default     = "devops-team"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# 네트워크 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR 목록"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# NAT Gateway 설정
variable "enable_nat_gateway" {
  description = "NAT Gateway 활성화 여부 (비용 발생)"
  type        = bool
  default     = true
}

# VPC Flow Logs 설정
variable "enable_flow_logs" {
  description = "VPC Flow Logs 활성화 여부"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Flow Logs 보관 기간 (일)"
  type        = number
  default     = 14
}
