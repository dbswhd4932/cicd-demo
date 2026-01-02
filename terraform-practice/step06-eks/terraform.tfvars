# ============================================
# 변수값 설정
# ============================================

project_name = "cicd-tf"
environment  = "dev"
aws_region   = "ap-northeast-2"

# VPC
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

# EKS
cluster_version     = "1.34"
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3
