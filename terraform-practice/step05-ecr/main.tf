# ============================================
# Step 05: ECR (Elastic Container Registry)
# ============================================
# 학습 목표:
# 1. ECR Repository 생성
# 2. 이미지 태그 불변성 (IMMUTABLE)
# 3. Lifecycle Policy로 이미지 정리
# 4. 이미지 스캔 및 암호화
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}

# ============================================
# ECR Repository
# ============================================
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "IMMUTABLE"  # 프로덕션: 태그 덮어쓰기 방지

  # 푸시 시 자동 취약점 스캔
  image_scanning_configuration {
    scan_on_push = true
  }

  # 이미지 암호화
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

# ============================================
# Lifecycle Policy (오래된 이미지 자동 삭제)
# ============================================
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 ${var.image_count_to_keep}개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_count_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================
# ECR Repository Policy (선택: 크로스 계정 접근)
# ============================================
# 다른 AWS 계정에서 이미지 Pull 허용 시 사용
# resource "aws_ecr_repository_policy" "app" {
#   repository = aws_ecr_repository.app.name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowCrossAccountPull"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::OTHER_ACCOUNT_ID:root"
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#       }
#     ]
#   })
# }
