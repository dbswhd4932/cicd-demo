# ============================================
# 변수값 설정
# ============================================

project_name = "yoon"
environment  = "dev"
owner        = "yoon"
aws_region   = "ap-northeast-2"

# 네트워크 설정
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# NAT Gateway (비용 발생: 약 $32/월 + 데이터 전송비)
# 실습 시에는 false로 설정하여 비용 절감 가능
enable_nat_gateway = true

# VPC Flow Logs (트래픽 모니터링)
enable_flow_logs         = true
flow_logs_retention_days = 14
