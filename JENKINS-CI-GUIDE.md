# Jenkins CI 파이프라인 구축 가이드

## 개요

AWS EKS 환경에서 Jenkins를 사용한 CI(Continuous Integration) 파이프라인 구축 과정을 정리합니다.

### 아키텍처
```
[CodeCommit: cicd-demo-app]
        ↓ (소스 코드)
    [Jenkins]
        ↓ (Docker 빌드)
    [ECR: cicd-demo-app]
        ↓ (이미지 태그 업데이트)
[CodeCommit: cicd-demo-k8s]
        ↓ (ArgoCD가 감시)
    [EKS 배포]
```

### 환경 정보
- AWS Account ID: `421114334882`
- Region: `ap-northeast-2`
- EKS Cluster: `cicd-demo-eks`
- Jenkins Namespace: `jenkins`

---

## STEP 1: EBS CSI Driver 설정 (Jenkins 영구 스토리지용)

Jenkins가 PersistentVolume을 사용하려면 EBS CSI Driver가 필요합니다.

### 1.1 OIDC Provider 확인
```bash
# OIDC Provider ID 확인
aws eks describe-cluster --name cicd-demo-eks --query "cluster.identity.oidc.issuer" --output text
# 출력 예: https://oidc.eks.ap-northeast-2.amazonaws.com/id/D9AA3B3E9360A287E1F6E9F4BAB6206A
```

### 1.2 EBS CSI Driver IAM Role 생성

**신뢰 정책 (ebs-csi-trust-policy.json):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::421114334882:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/D9AA3B3E9360A287E1F6E9F4BAB6206A"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.ap-northeast-2.amazonaws.com/id/D9AA3B3E9360A287E1F6E9F4BAB6206A:aud": "sts.amazonaws.com",
          "oidc.eks.ap-northeast-2.amazonaws.com/id/D9AA3B3E9360A287E1F6E9F4BAB6206A:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
```

**IAM Role 생성:**
```bash
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://ebs-csi-trust-policy.json

aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
```

### 1.3 EBS CSI Driver Addon 설치
```bash
aws eks create-addon \
  --cluster-name cicd-demo-eks \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::421114334882:role/AmazonEKS_EBS_CSI_DriverRole

# 설치 확인
aws eks describe-addon --cluster-name cicd-demo-eks --addon-name aws-ebs-csi-driver
```

---

## STEP 2: Jenkins 설치 (Helm)

### 2.1 Jenkins 네임스페이스 생성
```bash
kubectl create namespace jenkins
```

### 2.2 Helm values.yaml 작성

**jenkins/values.yaml:**
```yaml
controller:
  image:
    tag: "2.479.1-lts-jdk17"
  serviceType: LoadBalancer
  admin:
    password: "admin123!"
  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - pipeline-stage-view
    - docker-workflow
    - amazon-ecr
    - aws-credentials
    - pipeline-utility-steps
    - git-parameter
persistence:
  enabled: true
  storageClass: gp2
  size: 10Gi
```

### 2.3 Helm으로 Jenkins 설치
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins \
  -n jenkins \
  -f jenkins/values.yaml
```

### 2.4 Jenkins 접속 확인
```bash
# LoadBalancer URL 확인
kubectl get svc -n jenkins

# Pod 상태 확인
kubectl get pods -n jenkins
```

**Jenkins URL:** `http://<EXTERNAL-IP>:8080`
**로그인:** admin / admin123!

---

## STEP 3: Jenkins Kubernetes Cloud 설정

Jenkins가 EKS에서 동적으로 agent pod를 생성하려면 Kubernetes Cloud 설정이 필요합니다.

### 3.1 Jenkins ServiceAccount 권한 부여
```bash
kubectl create clusterrolebinding jenkins-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=jenkins:jenkins
```

### 3.2 Jenkins UI에서 Kubernetes Cloud 설정

1. **Jenkins 관리** → **Clouds** → **New cloud** → **Kubernetes**
2. 다음 설정 입력:
   - **Name:** `kubernetes`
   - **Kubernetes URL:** (비워두면 자동 감지)
   - **Kubernetes Namespace:** `jenkins`
   - **Jenkins URL:** `http://jenkins.jenkins.svc.cluster.local:8080`
   - **Jenkins tunnel:** `jenkins-agent.jenkins.svc.cluster.local:50000`
3. **Test Connection** 클릭하여 연결 확인
4. **Save**

---

## STEP 4: Jenkins Credentials 설정

### 4.1 CodeCommit Git Credentials 생성

1. **AWS 콘솔** → **IAM** → **Users** → 사용자 선택
2. **Security credentials** 탭
3. **HTTPS Git credentials for AWS CodeCommit** → **Generate credentials**
4. Username/Password 복사해두기

### 4.2 Jenkins에 Credentials 추가

**Jenkins 관리** → **Credentials** → **System** → **Global credentials** → **Add Credentials**

#### CodeCommit Credentials (Git용)
- **Kind:** Username with password
- **Username:** (CodeCommit에서 생성한 Username)
- **Password:** (CodeCommit에서 생성한 Password)
- **ID:** `codecommit-credentials`

#### AWS Credentials (ECR용)
- **Kind:** AWS Credentials
- **Access Key ID:** (IAM Access Key)
- **Secret Access Key:** (IAM Secret Key)
- **ID:** `aws-credentials`

---

## STEP 5: CodeCommit 레포지토리 구성

### 5.1 cicd-demo-app (애플리케이션 소스)

**디렉토리 구조:**
```
cicd-demo-app/
├── app/
│   ├── main.py
│   ├── Dockerfile
│   └── requirements.txt
└── jenkins/
    └── Jenkinsfile
```

**app/main.py:**
```python
from fastapi import FastAPI
from pydantic import BaseModel

APP_VERSION = "v0.0.2"

app = FastAPI(
    title="CI/CD Demo API",
    version=APP_VERSION
)

@app.get("/")
def root():
    return {"app": "CI/CD Demo", "version": APP_VERSION}

@app.get("/version")
def get_version():
    return {"version": APP_VERSION}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

**app/Dockerfile:**
```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY main.py .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**app/requirements.txt:**
```
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
```

### 5.2 cicd-demo-k8s (Kubernetes 매니페스트)

**디렉토리 구조:**
```
cicd-demo-k8s/
└── k8s/
    ├── deployment.yaml
    └── service.yaml
```

**k8s/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cicd-demo-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cicd-demo-app
  template:
    metadata:
      labels:
        app: cicd-demo-app
    spec:
      containers:
      - name: cicd-demo-app
        image: 421114334882.dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app:v0.0.2
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

**k8s/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: cicd-demo-app
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: cicd-demo-app
  ports:
  - port: 80
    targetPort: 8000
```

---

## STEP 6: Jenkinsfile 작성

**jenkins/Jenkinsfile:**
```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
  - name: aws-cli
    image: amazon/aws-cli:latest
    command:
    - sleep
    args:
    - infinity
'''
        }
    }

    environment {
        AWS_REGION = 'ap-northeast-2'
        AWS_ACCOUNT_ID = '421114334882'
        ECR_REPOSITORY = 'cicd-demo-app'
        K8S_REPO_URL = "https://git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/cicd-demo-k8s"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Get Version') {
            steps {
                script {
                    def version = sh(
                        script: "grep '^APP_VERSION' app/main.py | cut -d'\"' -f2",
                        returnStdout: true
                    ).trim()
                    env.APP_VERSION = version
                    env.ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    echo "Application Version: ${env.APP_VERSION}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    echo 'Building Docker image...'
                    dir('app') {
                        sh "docker build -t ${ECR_REPOSITORY}:${APP_VERSION} ."
                        sh "docker tag ${ECR_REPOSITORY}:${APP_VERSION} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${APP_VERSION}"
                        sh "docker tag ${ECR_REPOSITORY}:${APP_VERSION} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                container('aws-cli') {
                    echo 'Logging in to ECR...'
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} > ${WORKSPACE}/ecr-password"
                    }
                }
                container('docker') {
                    echo 'Pushing to ECR...'
                    sh "cat ${WORKSPACE}/ecr-password | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${APP_VERSION}"
                    sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    sh "rm -f ${WORKSPACE}/ecr-password"
                }
            }
        }

        stage('Update K8s Manifest') {
            steps {
                echo 'Updating Kubernetes manifest...'
                withCredentials([gitUsernamePassword(credentialsId: 'codecommit-credentials', gitToolName: 'git-tool')]) {
                    sh "rm -rf k8s-manifests"
                    sh "git clone ${K8S_REPO_URL} k8s-manifests"

                    dir('k8s-manifests') {
                        sh """
                            sed -i 's|image:.*cicd-demo-app:.*|image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${APP_VERSION}|g' k8s/deployment.yaml
                            git config user.email "jenkins@cicd-demo.com"
                            git config user.name "Jenkins"
                            git add .
                            git commit -m "Update image to ${APP_VERSION}" || true
                            git push origin main
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Version ${APP_VERSION} is ready for deployment"
        }
        failure {
            echo "Pipeline failed!"
        }
        always {
            echo "Cleaning up workspace..."
        }
    }
}
```

---

## STEP 7: Jenkins Pipeline Job 생성

### 7.1 새 Pipeline Job 생성

1. **Jenkins 대시보드** → **New Item**
2. **이름:** `cicd-demo-pipeline`
3. **타입:** Pipeline
4. **OK**

### 7.2 Pipeline 설정

**Pipeline 섹션:**
- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-app`
- **Credentials:** `codecommit-credentials`
- **Branch:** `*/main`
- **Script Path:** `jenkins/Jenkinsfile`

**Build Triggers:**
- 모든 옵션 체크 해제 (수동 빌드)

**Save**

---

## STEP 8: 빌드 실행

1. **cicd-demo-pipeline** Job 클릭
2. **Build Now** 클릭
3. **Console Output**에서 진행 상황 확인

### 성공 시 결과:
- Docker 이미지가 ECR에 푸시됨
- cicd-demo-k8s 레포지토리의 deployment.yaml 이미지 태그가 업데이트됨

---

## 트러블슈팅

### 에러 1: No Kubernetes cloud was found
**원인:** Jenkins Kubernetes Cloud가 설정되지 않음
**해결:** STEP 3 참고하여 Kubernetes Cloud 설정

### 에러 2: CodeCommit 403 에러
**원인:** AWS credential helper를 사용하려 하지만 Jenkins에 AWS CLI가 없음
**해결:** Username/Password 방식의 Git credentials 사용 (STEP 4.1 참고)

### 에러 3: ECR password file not found
**원인:** 컨테이너 간 /tmp 경로가 공유되지 않음
**해결:** `${WORKSPACE}` 경로 사용 (공유 볼륨)

### 에러 4: grep으로 버전 파싱 실패
**원인:** `grep 'APP_VERSION'`이 여러 줄 매칭
**해결:** `grep '^APP_VERSION'`으로 줄 시작 매칭

### 에러 5: Post section container context error
**원인:** post 블록에서 container() 사용 시 podTemplate 컨텍스트 없음
**해결:** post 블록에서 container() 제거, echo만 사용

---

## 다음 단계

Jenkins CI 파이프라인이 완성되었습니다. 다음은 ArgoCD를 설정하여 CD(Continuous Deployment)를 구성합니다.

→ **STEP6-ARGOCD.md** 참고
