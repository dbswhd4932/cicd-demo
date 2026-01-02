# ============================================
# 변수값 설정
# ============================================

project_name = "yoon"
environment  = "dev"
aws_region   = "ap-northeast-2"

# Jenkins EC2
jenkins_instance_type = "t3.medium"
jenkins_volume_size   = 30

# 보안: 본인 IP로 제한 권장
# 예: allowed_cidr_blocks = ["123.456.789.0/32"]
allowed_cidr_blocks = ["0.0.0.0/0"]
