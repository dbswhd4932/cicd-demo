# ============================================
# CodeCommit Repositories
# ============================================
# 학습 목표:
# 1. CodeCommit 저장소 생성
# 2. 애플리케이션 코드 저장소
# 3. Kubernetes 매니페스트 저장소 (GitOps용)
# ============================================

# ============================================
# 저장소 1: 애플리케이션 코드
# ============================================
resource "aws_codecommit_repository" "app" {
  repository_name = "${var.project_name}-app"
  description     = "CI/CD Demo Application"

  tags = {
    Name = "${var.project_name}-app"
  }
}

# ============================================
# 저장소 2: Kubernetes 매니페스트 (GitOps)
# ============================================
resource "aws_codecommit_repository" "k8s" {
  repository_name = "${var.project_name}-k8s"
  description     = "Kubernetes manifests for GitOps"

  tags = {
    Name = "${var.project_name}-k8s"
  }
}
