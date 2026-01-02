# ============================================
# Step 03: VPC 네트워크 기본 구축
# ============================================
# 학습 목표:
# 1. VPC 생성 및 CIDR 블록 이해
# 2. Public Subnet 생성
# 3. Internet Gateway 연결
# 4. Route Table 설정
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
}

# 사용 가능한 AZ 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# VPC (Virtual Private Cloud)
# ============================================
# AWS 내에서 논리적으로 격리된 네트워크 공간
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # 예: 10.0.0.0/16 (65,536개 IP)
  enable_dns_hostnames = true          # DNS 호스트명 활성화
  enable_dns_support   = true          # DNS 지원 활성화

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ============================================
# Internet Gateway (IGW)
# ============================================
# VPC와 인터넷 간의 통신을 가능하게 하는 게이트웨이
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # VPC에 연결

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ============================================
# Public Subnet
# ============================================
# 인터넷과 직접 통신 가능한 서브넷 (2개 AZ에 생성)
resource "aws_subnet" "public" {
  count = 2  # 2개의 서브넷 생성

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"  # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # 인스턴스에 자동으로 Public IP 할당

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  }
}

# ============================================
# Route Table (Public)
# ============================================
# 서브넷의 트래픽 라우팅 규칙 정의
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 기본 라우트: 모든 트래픽(0.0.0.0/0)을 IGW로 보냄
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ============================================
# Route Table Association
# ============================================
# 서브넷과 라우트 테이블 연결
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
