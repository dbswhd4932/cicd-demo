# Step 01: Terraform 기초

## 학습 목표
- Terraform 기본 구조 이해
- AWS Provider 설정
- 첫 번째 리소스 생성 (S3 버킷)
- 기본 명령어 익히기

## 파일 구조
```
step01-basics/
└── main.tf          # Provider 설정 + 리소스 정의
```

## 핵심 개념

### 1. Terraform 블록
```hcl
terraform {
  required_version = ">= 1.0"      # Terraform 버전
  required_providers { ... }        # 사용할 Provider
}
```

### 2. Provider 블록
```hcl
provider "aws" {
  region = "ap-northeast-2"
}
```

### 3. Resource 블록
```hcl
resource "리소스타입" "리소스이름" {
  속성 = 값
}
```

## 실습 명령어

### 1단계: 초기화
```bash
cd terraform-practice/step01-basics
terraform init
```
- `.terraform/` 폴더 생성
- AWS Provider 플러그인 다운로드

### 2단계: 실행 계획 확인
```bash
terraform plan
```
- 어떤 리소스가 생성될지 미리 확인
- `+` 표시: 생성될 리소스

### 3단계: 리소스 생성
```bash
terraform apply
```
- `yes` 입력하여 실제 생성
- `terraform.tfstate` 파일 생성됨

### 4단계: 리소스 확인
```bash
# AWS CLI로 확인
aws s3 ls | grep my-first

# 또는 Terraform으로 확인
terraform show
```

### 5단계: 리소스 삭제
```bash
terraform destroy
```
- 실습 후 비용 방지를 위해 삭제

## 주의사항
- S3 버킷 이름은 **전 세계에서 유일**해야 함
- `my-first-terraform-bucket-12345` → 본인만의 이름으로 변경!

## 다음 단계
Step 02에서는 변수(variables)와 출력값(outputs)을 배웁니다.
