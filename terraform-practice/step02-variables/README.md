# Step 02: 변수(Variables)와 출력값(Outputs)

## 학습 목표
- 변수를 사용한 재사용 가능한 코드 작성
- 다양한 변수 타입 이해
- 출력값(outputs) 활용
- tfvars 파일로 환경별 설정 분리

## 파일 구조
```
step02-variables/
├── main.tf           # Provider + 리소스 정의
├── variables.tf      # 변수 정의
├── outputs.tf        # 출력값 정의
└── terraform.tfvars  # 변수값 설정 (자동 로드)
```

## 핵심 개념

### 1. 변수 정의 (variables.tf)
```hcl
variable "변수명" {
  description = "설명"
  type        = string    # 타입 지정
  default     = "기본값"   # 선택사항
}
```

### 2. 변수 사용 (main.tf)
```hcl
bucket = var.project_name   # var.변수명 으로 참조
```

### 3. 변수값 설정 (terraform.tfvars)
```hcl
project_name = "myproject"
environment  = "dev"
```

### 4. 출력값 정의 (outputs.tf)
```hcl
output "출력명" {
  description = "설명"
  value       = aws_s3_bucket.app_bucket.id
}
```

## 변수 타입

| 타입 | 예시 | 설명 |
|------|------|------|
| `string` | `"hello"` | 문자열 |
| `number` | `10` | 숫자 |
| `bool` | `true` / `false` | 불리언 |
| `list(string)` | `["a", "b"]` | 리스트 |
| `map(string)` | `{ key = "value" }` | 맵(딕셔너리) |

## 변수 우선순위 (높은순)

```
1. -var 옵션           terraform apply -var="env=prod"
2. -var-file 옵션      terraform apply -var-file="prod.tfvars"
3. *.auto.tfvars       자동 로드
4. terraform.tfvars    자동 로드
5. 환경변수            TF_VAR_environment=prod
6. default 값          variable 블록의 default
```

## 실습 명령어

### 1단계: 초기화
```bash
cd terraform-practice/step02-variables
terraform init
```

### 2단계: 변수값 확인 후 계획
```bash
# terraform.tfvars 내용 확인
cat terraform.tfvars

# 실행 계획 (변수 적용 확인)
terraform plan
```

### 3단계: 리소스 생성
```bash
terraform apply
```

### 4단계: 출력값 확인
```bash
# 모든 출력값 확인
terraform output

# 특정 출력값만 확인
terraform output bucket_name

# JSON 형식으로 출력
terraform output -json
```

### 5단계: 변수 오버라이드 테스트
```bash
# -var 옵션으로 변수 덮어쓰기
terraform plan -var="environment=staging"
```

### 6단계: 리소스 삭제
```bash
terraform destroy
```

## 실습 포인트

### 유효성 검증 (validation)
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "dev, staging, prod 중 하나여야 합니다."
  }
}
```
→ 잘못된 값 입력 시 에러 발생!

### 조건부 표현식
```hcl
status = var.enable_versioning ? "Enabled" : "Disabled"
```
→ `조건 ? 참일때 : 거짓일때`

## 환경별 tfvars 파일 예시

```bash
# 개발 환경
terraform apply -var-file="dev.tfvars"

# 프로덕션 환경
terraform apply -var-file="prod.tfvars"
```

## 다음 단계
Step 03에서는 VPC 네트워크를 구축합니다.
