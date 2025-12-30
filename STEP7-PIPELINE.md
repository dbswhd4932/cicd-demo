# 7단계: CI/CD 파이프라인 구성

## 전체 플로우

```
[코드 변경] → [CodeCommit Push] → [Jenkins CI] → [ECR Push] → [K8s Manifest 업데이트] → [ArgoCD CD] → [EKS 배포]
```

---

## 1. CodeCommit에 애플리케이션 코드 푸시

### Git 초기화 및 원격 저장소 설정

```bash
# 프로젝트 디렉토리로 이동
cd cicd

# Git 초기화
git init

# .gitignore 생성
cat > .gitignore << 'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# Python
__pycache__/
*.py[cod]
.venv/

# IDE
.idea/
.vscode/

# OS
.DS_Store
EOF

# 전체 커밋
git add .
git commit -m "Initial commit - CI/CD Demo"

# CodeCommit 원격 저장소 추가
git remote add origin https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-app

# 푸시
git push -u origin main
```

---

## 2. K8s 매니페스트 저장소 설정 (GitOps)

### 별도 디렉토리에서 K8s 저장소 생성

```bash
# 별도 위치에 K8s 매니페스트 저장소 생성
mkdir ~/cicd-demo-k8s
cd ~/cicd-demo-k8s

# Git 초기화
git init

# k8s 디렉토리 생성 및 파일 복사
mkdir k8s
cp ~/cicd/k8s/* k8s/

# deployment.yaml에서 ACCOUNT_ID를 실제 값으로 교체
# [YOUR_ACCOUNT_ID]를 실제 AWS 계정 ID로 변경하세요
sed -i '' 's/ACCOUNT_ID/[YOUR_ACCOUNT_ID]/g' k8s/deployment.yaml

# 커밋
git add .
git commit -m "Initial K8s manifests"

# CodeCommit 연결
git remote add origin https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-k8s
git push -u origin main
```

---

## 3. Jenkins Pipeline 설정 확인

### Jenkinsfile 구조

```
jenkins/Jenkinsfile
├── Checkout         # 소스 코드 체크아웃
├── Get Version      # main.py에서 버전 추출
├── Build Image      # Docker 이미지 빌드
├── Push to ECR      # ECR에 이미지 푸시
└── Update Manifest  # K8s 매니페스트 업데이트
```

### Jenkins 환경 변수 설정

Jenkins에서 다음 환경 변수가 필요합니다:

1. **Jenkins 관리** → **Configure System**
2. **Global properties** → **Environment variables** 체크
3. 추가:
   - `AWS_ACCOUNT_ID`: [YOUR_AWS_ACCOUNT_ID]

---

## 4. 첫 빌드 실행

### Jenkins에서 빌드 트리거

1. Jenkins UI 접속
2. `cicd-demo-pipeline` 선택
3. **Build Now** 클릭
4. 빌드 진행 상황 확인

### 빌드 단계별 확인

```
✅ Checkout - 소스 코드 체크아웃
✅ Get Version - v0.0.1 추출
✅ Build Docker Image - 이미지 빌드 완료
✅ Push to ECR - ECR에 푸시 완료
✅ Update K8s Manifest - 매니페스트 업데이트
```

---

## 5. ArgoCD 동기화 확인

### 자동 Sync 확인

```bash
# ArgoCD Application 상태
kubectl get applications -n argocd

# Application 상세 정보
kubectl describe application cicd-demo -n argocd
```

### 배포 상태 확인

```bash
# Pod 상태
kubectl get pods -l app=cicd-demo

# 서비스 상태
kubectl get svc cicd-demo

# 버전 확인
curl http://[SERVICE_IP]/version
```

---

## 6. Webhook 설정 (자동 트리거)

### CodeCommit → Lambda → Jenkins

#### Lambda 함수 생성

```python
# lambda_function.py
import json
import urllib.request

JENKINS_URL = "http://[JENKINS_IP]:8080"
JOB_NAME = "cicd-demo-pipeline"
JENKINS_TOKEN = "[YOUR_API_TOKEN]"

def lambda_handler(event, context):
    url = f"{JENKINS_URL}/job/{JOB_NAME}/build"

    req = urllib.request.Request(url, method='POST')
    req.add_header('Authorization', f'Bearer {JENKINS_TOKEN}')

    try:
        urllib.request.urlopen(req)
        return {'statusCode': 200, 'body': 'Build triggered'}
    except Exception as e:
        return {'statusCode': 500, 'body': str(e)}
```

### Jenkins API Token 생성

1. Jenkins UI → 사용자 아이콘 → **Configure**
2. **API Token** → **Add new Token**
3. 토큰 복사 및 저장

---

## 7. 파이프라인 최적화 (선택사항)

### 병렬 빌드

```groovy
stage('Test & Build') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'pytest tests/'
            }
        }
        stage('Build Image') {
            steps {
                sh 'docker build -t app .'
            }
        }
    }
}
```

### 캐시 활용

```groovy
stage('Build') {
    steps {
        sh 'docker build --cache-from ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest -t app .'
    }
}
```

---

## 트러블슈팅

### ECR 로그인 실패

```bash
# Jenkins Pod에서 AWS CLI 확인
kubectl exec -it -n jenkins deploy/jenkins -- aws sts get-caller-identity
```

### Git Push 권한 오류

```bash
# CodeCommit 자격 증명 확인
kubectl exec -it -n jenkins deploy/jenkins -- git config --global credential.helper
```

### 이미지 Pull 실패 (EKS)

```bash
# 노드 IAM Role 확인
aws eks describe-nodegroup --cluster-name cicd-demo-eks --nodegroup-name cicd-demo-node-group
```

---

## 다음 단계

파이프라인 구성이 완료되면 [STEP8-TEST.md](./STEP8-TEST.md)에서 전체 테스트를 진행하세요.
