# ============================================
# Step 01: Terraform 기초
# ============================================
# 학습 목표:
# 1. Terraform 블록 구조 이해
# 2. Provider 설정 방법
# 3. 첫 번째 리소스(S3 버킷) 생성
# 4. terraform init, plan, apply, destroy 명령어 실습
# ============================================

# Terraform 설정 블록
# - required_version: 사용할 Terraform 버전 지정
# - required_providers: 사용할 Provider 정의
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Provider 소스 (hashicorp 공식)
      version = "~> 5.0"         # 5.x 버전 사용
    }
  }
}

# AWS Provider 설정
# - region: AWS 리전 지정
provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

# 첫 번째 리소스: S3 버킷
# 형식: resource "리소스타입" "리소스이름" { ... }
resource "aws_s3_bucket" "my_first_bucket" {
  # 버킷 이름은 전 세계에서 유일해야 함
  # 본인의 고유한 이름으로 변경 필요!
  bucket = "my-first-terraform-bucket-yoon"

  tags = {
    Name        = "My First Bucket"
    Environment = "Practice"
    ManagedBy   = "Terraform"
  }
}
