# CI/CD 파이프라인 구축 Step-by-Step 가이드

## 📋 전체 아키텍처
```
[Developer] → [CodeCommit] → [Jenkins] → [ECR] → [ArgoCD] → [EKS]
     │              │             │          │         │         │
   코드작성      Git Push     CI Build    Image     GitOps    K8s배포
                           & Docker Push  저장소    CD배포
```

---

# ✅ 1~2단계: 애플리케이션 & Docker (완료)

## 현재 생성된 파일
```
cicd/
├── app/
│   ├── main.py           # FastAPI 애플리케이션
│   ├── requirements.txt  # Python 의존성
│   ├── Dockerfile        # Docker 빌드 설정
│   └── .dockerignore
├── terraform/            # (3단계에서 작성)
├── k8s/                  # (4단계에서 작성)
├── jenkins/              # (5단계에서 작성)
└── argocd/               # (6단계에서 작성)
```

## 로컬 테스트 방법

### Docker 이미지 빌드
```bash
cd app
docker build -t cicd-demo:v0.0.1 .
```

### 컨테이너 실행 & 테스트
```bash
# 컨테이너 실행
docker run -d --name cicd-demo-test -p 8000:8000 cicd-demo:v0.0.1

# 버전 확인
curl http://localhost:8000/version
# 결과: {"version":"v0.0.1","message":"Current version is v0.0.1"}

# 헬스체크
curl http://localhost:8000/health
# 결과: {"status":"healthy"}

# 테스트 후 정리
docker stop cicd-demo-test && docker rm cicd-demo-test
```

---

# 📦 3단계: Terraform AWS 인프라 구성

## 사전 준비

### 1. Terraform 설치
```bash
# macOS (Homebrew)
brew install terraform

# 설치 확인
terraform --version
```

### 2. AWS CLI 설치 및 설정
```bash
# macOS (Homebrew)
brew install awscli

# AWS 자격 증명 설정
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region name: ap-northeast-2
# Default output format: json

# 설정 확인
aws sts get-caller-identity
```

## Terraform 파일 생성

`terraform/` 디렉토리에 아래 파일들을 생성하세요.

---

### terraform/variables.tf
```hcl
# 프로젝트 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "cicd-demo"
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  default     = "dev"
}

# AWS 설정
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# EKS 설정
variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_type" {
  description = "EKS 노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "EKS 노드 개수"
  type        = number
  default     = 2
}

# 네트워크 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}
```

---

### terraform/main.tf
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 상태 파일 로컬 저장 (실습용)
  # 프로덕션에서는 S3 backend 사용 권장
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
```

---

### terraform/vpc.tf
```hcl
# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 퍼블릭 서브넷 (2개 AZ)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.project_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

# 프라이빗 서브넷 (2개 AZ)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                           = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT 게이트웨이
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# 프라이빗 라우팅 테이블
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

---

### terraform/ecr.tf
```hcl
# ECR 레포지토리
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

# ECR 수명주기 정책 (이미지 정리)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 10개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

---

### terraform/codecommit.tf
```hcl
# CodeCommit 저장소 - 애플리케이션 코드
resource "aws_codecommit_repository" "app" {
  repository_name = "${var.project_name}-app"
  description     = "CI/CD Demo Application Repository"

  tags = {
    Name = "${var.project_name}-app"
  }
}

# CodeCommit 저장소 - Kubernetes 매니페스트 (GitOps용)
resource "aws_codecommit_repository" "k8s" {
  repository_name = "${var.project_name}-k8s"
  description     = "Kubernetes manifests for GitOps"

  tags = {
    Name = "${var.project_name}-k8s"
  }
}
```

---

### terraform/eks.tf
```hcl
# EKS 클러스터 IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS 클러스터
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS 노드 그룹 IAM Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# EKS 노드 그룹
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = [var.eks_node_instance_type]

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_desired_size + 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]

  tags = {
    Name = "${var.project_name}-node"
  }
}
```

---

### terraform/outputs.tf
```hcl
# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# ECR
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

# CodeCommit
output "codecommit_app_clone_url_http" {
  description = "CodeCommit App Repository Clone URL (HTTPS)"
  value       = aws_codecommit_repository.app.clone_url_http
}

output "codecommit_k8s_clone_url_http" {
  description = "CodeCommit K8s Repository Clone URL (HTTPS)"
  value       = aws_codecommit_repository.k8s.clone_url_http
}

# EKS
output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.main.endpoint
}

# kubectl 설정 명령어
output "configure_kubectl" {
  description = "kubectl 설정 명령어"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
```

---

## Terraform 실행

### 1. 초기화
```bash
cd terraform
terraform init
```

### 2. 실행 계획 확인
```bash
terraform plan
```

### 3. 인프라 생성
```bash
terraform apply
# 확인 메시지에 'yes' 입력
```

### 4. 출력값 확인
```bash
terraform output
```

### 💡 예상 출력
```
ecr_repository_url = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app"
eks_cluster_name = "cicd-demo-eks"
codecommit_app_clone_url_http = "https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-app"
configure_kubectl = "aws eks update-kubeconfig --region ap-northeast-2 --name cicd-demo-eks"
```

---

## ⚠️ 비용 주의사항

- **EKS 클러스터**: 시간당 $0.10 (약 월 $72)
- **NAT Gateway**: 시간당 $0.045 + 데이터 전송 비용
- **EC2 인스턴스 (t3.medium x 2)**: 시간당 약 $0.08

### 리소스 삭제 방법
```bash
terraform destroy
# 확인 메시지에 'yes' 입력
```

---

# 🔧 4단계: kubectl 설정 & ECR 푸시

## kubectl 설정
```bash
# EKS 클러스터에 연결
aws eks update-kubeconfig --region ap-northeast-2 --name cicd-demo-eks

# 연결 확인
kubectl get nodes
```

## ECR에 이미지 푸시

### 1. ECR 로그인
```bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin [계정ID].dkr.ecr.ap-northeast-2.amazonaws.com
```

### 2. 이미지 태그 & 푸시
```bash
# 태그 지정
docker tag cicd-demo:v0.0.1 [계정ID].dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app:v0.0.1

# ECR에 푸시
docker push [계정ID].dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app:v0.0.1
```

---

# 📄 다음 단계 (5~8단계)

5단계부터의 가이드는 다음 파일에서 계속됩니다:
- Jenkins 설치: STEP5-JENKINS.md
- ArgoCD 설정: STEP6-ARGOCD.md
- CI/CD 파이프라인: STEP7-PIPELINE.md
- 전체 테스트: STEP8-TEST.md

준비가 되면 다음 단계를 진행해 주세요!
