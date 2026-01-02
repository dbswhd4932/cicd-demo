terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 프로덕션용 S3 Backend 설정
  # 사용 전 S3 버킷과 DynamoDB 테이블을 먼저 생성해야 합니다
  # aws s3 mb s3://your-company-terraform-state --region ap-northeast-2
  # aws dynamodb create-table --table-name terraform-locks \
  #   --attribute-definitions AttributeName=LockID,AttributeType=S \
  #   --key-schema AttributeName=LockID,KeyType=HASH \
  #   --billing-mode PAY_PER_REQUEST --region ap-northeast-2
  #
  # backend "s3" {
  #   bucket         = "your-company-terraform-state"
  #   key            = "cicd-demo/dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
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

# 사용 가능한 AZ 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}
