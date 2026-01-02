# ============================================
# Step 02: 변수(Variables)와 출력값(Outputs)
# ============================================
# 학습 목표:
# 1. variable 블록으로 입력 변수 정의
# 2. var.변수명 으로 변수 참조
# 3. output 블록으로 출력값 정의
# 4. terraform.tfvars 파일로 변수값 관리
# ============================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider에서 변수 사용
provider "aws" {
  region = var.aws_region  # 하드코딩 대신 변수 사용!
}

# S3 버킷 - 변수를 활용한 동적 이름 생성
resource "aws_s3_bucket" "app_bucket" {
  # 변수를 조합하여 버킷 이름 생성
  bucket = "${var.project_name}-${var.environment}-bucket"

  tags = {
    Name        = "${var.project_name}-bucket"
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# S3 버킷 버전 관리 설정
resource "aws_s3_bucket_versioning" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}
