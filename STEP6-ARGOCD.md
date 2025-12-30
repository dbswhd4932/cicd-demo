# 6단계: ArgoCD 설치 및 설정

## 사전 조건
- EKS 클러스터가 실행 중이어야 합니다
- kubectl이 EKS에 연결되어 있어야 합니다

---

## 1. ArgoCD 네임스페이스 생성

```bash
kubectl create namespace argocd
```

---

## 2. ArgoCD 설치

### 방법 1: kubectl로 직접 설치 (권장)

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 방법 2: Helm으로 설치

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer
```

---

## 3. ArgoCD 설치 확인

```bash
# Pod 상태 확인
kubectl get pods -n argocd -w

# 모든 Pod가 Running 상태가 될 때까지 대기 (약 2-3분)
```

---

## 4. ArgoCD 서버 노출

### LoadBalancer로 노출

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### 외부 IP 확인

```bash
kubectl get svc argocd-server -n argocd
# EXTERNAL-IP 열 확인 (할당까지 1-2분 소요)
```

---

## 5. ArgoCD 초기 비밀번호 확인

```bash
# 초기 admin 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 6. ArgoCD 웹 UI 접속

1. `kubectl get svc argocd-server -n argocd`에서 EXTERNAL-IP 확인
2. 브라우저에서 `https://[EXTERNAL-IP]` 접속 (HTTPS)
3. 보안 경고 무시하고 진행
4. ID: `admin`, PW: 위에서 확인한 비밀번호

---

## 7. ArgoCD CLI 설치 (선택사항)

```bash
# macOS
brew install argocd

# 로그인
argocd login [EXTERNAL-IP] --username admin --password [PASSWORD] --insecure
```

---

## 8. CodeCommit 저장소 연결

### 방법 1: ArgoCD UI에서 설정

1. **Settings** → **Repositories** → **Connect Repo**
2. **Via HTTPS** 선택
3. 설정:
   - Repository URL: `https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-k8s`
   - Username: [AWS CodeCommit HTTPS Git 자격 증명의 사용자 이름]
   - Password: [AWS CodeCommit HTTPS Git 자격 증명의 비밀번호]
4. **Connect** 클릭

### 방법 2: CLI로 설정

```bash
argocd repo add https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-k8s \
  --username [GIT_USERNAME] \
  --password [GIT_PASSWORD]
```

### CodeCommit HTTPS Git 자격 증명 생성

1. AWS Console → IAM → Users → [사용자 선택]
2. **Security credentials** 탭
3. **HTTPS Git credentials for AWS CodeCommit** 섹션
4. **Generate credentials** 클릭
5. 사용자 이름과 비밀번호 저장

---

## 9. Application 생성

### 방법 1: UI에서 생성

1. **Applications** → **New App**
2. 설정:
   - Application Name: `cicd-demo`
   - Project: `default`
   - Sync Policy: `Automatic`
   - **Source**:
     - Repository URL: `https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/cicd-demo-k8s`
     - Path: `k8s`
   - **Destination**:
     - Cluster URL: `https://kubernetes.default.svc`
     - Namespace: `default`
3. **Create** 클릭

### 방법 2: YAML로 생성

```bash
kubectl apply -f argocd/application.yaml
```

---

## 10. 자동 동기화 확인

```bash
# ArgoCD Application 상태 확인
kubectl get applications -n argocd

# 상세 정보
kubectl describe application cicd-demo -n argocd
```

---

## 11. 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -l app=cicd-demo

# Service 확인
kubectl get svc cicd-demo

# 애플리케이션 테스트
curl http://[SERVICE-EXTERNAL-IP]/version
```

---

## ArgoCD 동작 원리

```
1. Jenkins가 K8s 매니페스트 저장소 업데이트
              ↓
2. ArgoCD가 Git 변경 감지 (주기적 polling 또는 webhook)
              ↓
3. ArgoCD가 EKS 클러스터와 Git 상태 비교
              ↓
4. 차이가 있으면 자동으로 Sync (배포)
              ↓
5. 새 Pod가 생성되고 이전 Pod는 종료
```

---

## 트러블슈팅

### Application이 Sync 실패하는 경우

```bash
# ArgoCD Application 로그 확인
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# 수동 Sync 시도
argocd app sync cicd-demo
```

### 이미지 Pull 실패

```bash
# Pod 상태 상세 확인
kubectl describe pod -l app=cicd-demo

# ECR 접근 권한 확인
# EKS 노드에 AmazonEC2ContainerRegistryReadOnly 정책이 있는지 확인
```

---

## 다음 단계

ArgoCD 설정이 완료되면 [STEP7-PIPELINE.md](./STEP7-PIPELINE.md)로 이동하세요.
