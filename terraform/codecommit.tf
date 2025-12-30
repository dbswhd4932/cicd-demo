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
