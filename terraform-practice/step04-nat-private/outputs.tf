# ============================================
# 출력값 정의
# ============================================

# VPC 정보
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# Subnet 정보
output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet ID 목록"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Private Subnet CIDR 목록"
  value       = aws_subnet.private[*].cidr_block
}

# Gateway 정보
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway Public IP"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

# Route Table 정보
output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private.id
}

# 가용 영역 정보
output "availability_zones" {
  description = "사용된 가용 영역"
  value       = data.aws_availability_zones.available.names
}

# Flow Logs 정보
output "flow_logs_log_group" {
  description = "VPC Flow Logs CloudWatch Log Group"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

# 요약 정보 (한눈에 보기)
output "network_summary" {
  description = "네트워크 구성 요약"
  value = {
    vpc_id              = aws_vpc.main.id
    vpc_cidr            = aws_vpc.main.cidr_block
    public_subnets      = aws_subnet.public[*].id
    private_subnets     = aws_subnet.private[*].id
    nat_gateway_enabled = var.enable_nat_gateway
    flow_logs_enabled   = var.enable_flow_logs
  }
}
