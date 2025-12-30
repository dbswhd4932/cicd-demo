# 8단계: 전체 테스트 (v0.0.1 → v0.0.2)

이 단계에서는 실제로 버전을 변경하고 자동 배포가 되는지 확인합니다.

---

## 테스트 시나리오

```
1. 현재 상태: v0.0.1 배포됨
2. 코드 변경: v0.0.1 → v0.0.2
3. Git Push
4. Jenkins 자동 빌드
5. ECR에 새 이미지 Push
6. K8s 매니페스트 업데이트
7. ArgoCD 자동 배포
8. 새 버전 확인: v0.0.2
```

---

## 1. 현재 버전 확인

```bash
# 서비스 IP 확인
kubectl get svc cicd-demo

# 현재 버전 확인
curl http://[SERVICE_IP]/version
# 예상 결과: {"version":"v0.0.1","message":"Current version is v0.0.1"}
```

---

## 2. 버전 변경 (v0.0.1 → v0.0.2)

### app/main.py 수정

```bash
cd cicd/app

# 버전 변경 (v0.0.1 → v0.0.2)
sed -i '' 's/v0.0.1/v0.0.2/g' main.py

# 변경 확인
grep APP_VERSION main.py
# 결과: APP_VERSION = "v0.0.2"
```

### 또는 직접 편집

```python
# app/main.py
# 아래 라인 수정
APP_VERSION = "v0.0.2"  # v0.0.1에서 변경
```

---

## 3. 변경사항 커밋 & 푸시

```bash
cd cicd

# 변경 확인
git diff

# 커밋
git add app/main.py
git commit -m "Bump version to v0.0.2"

# CodeCommit에 푸시
git push origin main
```

---

## 4. Jenkins 빌드 모니터링

### Jenkins UI에서 확인

1. Jenkins UI 접속
2. `cicd-demo-pipeline` 클릭
3. 빌드가 자동으로 시작되었는지 확인 (또는 **Build Now** 클릭)
4. **Console Output**에서 진행 상황 확인

### 예상 로그

```
📥 Checking out source code...
📌 Application Version: v0.0.2
🔨 Building Docker image...
📤 Pushing to ECR...
📝 Updating Kubernetes manifest...
✅ Pipeline completed successfully!
🚀 Version v0.0.2 is ready for deployment
```

---

## 5. ECR 이미지 확인

```bash
# ECR에 새 이미지가 푸시되었는지 확인
aws ecr describe-images \
  --repository-name cicd-demo-app \
  --query 'imageDetails[*].imageTags' \
  --output table
```

예상 결과:
```
-----------------
|  ListImages   |
+---------------+
|  v0.0.1      |
|  v0.0.2      |
|  latest      |
+---------------+
```

---

## 6. K8s 매니페스트 업데이트 확인

```bash
# K8s 저장소에서 변경 확인
cd ~/cicd-demo-k8s
git pull

# deployment.yaml 확인
grep image k8s/deployment.yaml
# 결과: image: [ACCOUNT_ID].dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app:v0.0.2
```

---

## 7. ArgoCD 동기화 확인

### ArgoCD UI에서 확인

1. ArgoCD UI 접속
2. `cicd-demo` Application 클릭
3. **Sync Status**: `Synced` 확인
4. **Health Status**: `Healthy` 확인

### CLI로 확인

```bash
# Application 상태
kubectl get applications -n argocd
# STATUS: Synced, HEALTH: Healthy

# 상세 정보
argocd app get cicd-demo
```

---

## 8. 배포 확인

### Pod 상태 확인

```bash
# Pod 상태 (새 Pod로 교체되었는지 확인)
kubectl get pods -l app=cicd-demo

# Pod 상세 정보 (이미지 태그 확인)
kubectl describe pod -l app=cicd-demo | grep Image
# 결과: Image: [ACCOUNT_ID].dkr.ecr.ap-northeast-2.amazonaws.com/cicd-demo-app:v0.0.2
```

### 새 버전 API 테스트

```bash
# 버전 확인
curl http://[SERVICE_IP]/version
```

### 예상 결과 🎉

```json
{
  "version": "v0.0.2",
  "message": "Current version is v0.0.2"
}
```

---

## 9. 전체 플로우 검증 완료 ✅

```
[v0.0.1 → v0.0.2 변경]
        ↓
[CodeCommit Push] ✅
        ↓
[Jenkins 빌드 트리거] ✅
        ↓
[Docker 이미지 빌드] ✅
        ↓
[ECR에 Push] ✅
        ↓
[K8s 매니페스트 업데이트] ✅
        ↓
[ArgoCD 자동 Sync] ✅
        ↓
[EKS 배포 완료] ✅
        ↓
[/version → v0.0.2 확인] ✅
```

---

## 10. 추가 테스트 (선택사항)

### 롤백 테스트

```bash
# ArgoCD에서 이전 버전으로 롤백
argocd app rollback cicd-demo

# 또는 UI에서 History → 이전 버전 선택 → Rollback
```

### 스케일링 테스트

```bash
# 레플리카 수 변경
kubectl scale deployment cicd-demo --replicas=3

# ArgoCD가 다시 원래대로 복구하는지 확인 (Self-Heal)
kubectl get pods -l app=cicd-demo -w
```

---

## 트러블슈팅

### 버전이 업데이트되지 않는 경우

1. Jenkins 빌드 로그 확인
2. ECR에 새 이미지가 있는지 확인
3. K8s 매니페스트가 업데이트되었는지 확인
4. ArgoCD Sync 상태 확인

### Pod가 ImagePullBackOff 상태인 경우

```bash
# 이미지 존재 확인
aws ecr describe-images --repository-name cicd-demo-app

# 노드 권한 확인
kubectl describe pod [POD_NAME]
```

---

## 🎉 축하합니다!

CI/CD 파이프라인 구축을 완료했습니다!

### 학습한 내용

- ✅ FastAPI 애플리케이션 개발
- ✅ Docker 컨테이너화
- ✅ AWS 인프라 수동 구성 (VPC, EKS, ECR, CodeCommit)
- ✅ Jenkins CI 파이프라인 (Kubernetes Agent)
- ✅ ArgoCD GitOps CD
- ✅ 자동 배포 테스트

### 다음 단계 (심화 학습)

- Helm Chart로 애플리케이션 패키징
- Canary/Blue-Green 배포 전략
- Prometheus/Grafana 모니터링
- Secret 관리 (AWS Secrets Manager, HashiCorp Vault)
- 멀티 환경 배포 (dev/staging/prod)
