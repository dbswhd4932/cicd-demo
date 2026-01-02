# ============================================
# 변수 정의 파일
# ============================================
# 변수 타입: string, number, bool, list, map, object
# ============================================

# 문자열(string) 변수
variable "project_name" {
  description = "s3-terraform"
  type        = string
  default     = "yoon"
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  default     = "dev"

  # 유효성 검증 (선택사항)
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
  default     = "yoonjong"
}

# 불리언(bool) 변수
variable "enable_versioning" {
  description = "S3 버전 관리 활성화 여부"
  type        = bool
  default     = true
}

# 숫자(number) 변수 - 예시
variable "instance_count" {
  description = "인스턴스 개수"
  type        = number
  default     = 1
}

# 리스트(list) 변수 - 예시
variable "allowed_ips" {
  description = "허용된 IP 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# 맵(map) 변수 - 예시
variable "extra_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
