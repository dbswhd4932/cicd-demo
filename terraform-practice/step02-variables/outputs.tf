# ============================================
# 출력값 정의 파일
# ============================================
# apply 후 터미널에 표시되는 값들
# 다른 모듈에서 참조할 때도 사용
# ============================================

# 버킷 이름 출력
output "bucket_name" {
  description = "생성된 S3 버킷 이름"
  value       = aws_s3_bucket.app_bucket.id
}

# 버킷 ARN 출력
output "bucket_arn" {
  description = "S3 버킷 ARN"
  value       = aws_s3_bucket.app_bucket.arn
}

# 버킷 리전 출력
output "bucket_region" {
  description = "S3 버킷 리전"
  value       = aws_s3_bucket.app_bucket.region
}

# 버전 관리 상태 출력
output "versioning_status" {
  description = "버전 관리 활성화 여부"
  value       = var.enable_versioning ? "Enabled" : "Disabled"
}

# 환경 정보 출력
output "environment_info" {
  description = "배포 환경 정보"
  value = {
    project     = var.project_name
    environment = var.environment
    region      = var.aws_region
  }
}
