# ============================================
# 출력값 정의
# ============================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록"
  value       = aws_subnet.public[*].cidr_block
}

output "availability_zones" {
  description = "사용된 가용 영역"
  value       = aws_subnet.public[*].availability_zone
}
