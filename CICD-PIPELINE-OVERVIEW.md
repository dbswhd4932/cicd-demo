# CI/CD 파이프라인 전체 프로세스 가이드

## 목차
1. [개요](#개요)
2. [전체 아키텍처](#전체-아키텍처)
3. [구성 요소 설명](#구성-요소-설명)
4. [상세 프로세스](#상세-프로세스)
5. [실제 배포 흐름 예시](#실제-배포-흐름-예시)
6. [무중단 배포](#무중단-배포)

---

## 개요

### CI/CD란?

**CI (Continuous Integration, 지속적 통합)**
- 개발자가 코드를 변경하면 자동으로 빌드하고 테스트하는 프로세스
- 코드 품질을 유지하고 버그를 조기에 발견

**CD (Continuous Deployment, 지속적 배포)**
- CI를 통과한 코드를 자동 또는 수동으로 운영 환경에 배포하는 프로세스
- 빠르고 안정적인 배포 가능

### 이 프로젝트에서 사용하는 도구

| 도구 | 역할 | 설명 |
|------|------|------|
| **AWS CodeCommit** | 소스 코드 저장소 | Git 기반 프라이빗 레포지토리 |
| **Jenkins** | CI 도구 | 빌드, 테스트, 이미지 생성 자동화 |
| **AWS ECR** | 컨테이너 레지스트리 | Docker 이미지 저장소 |
| **ArgoCD** | CD 도구 | GitOps 기반 Kubernetes 배포 |
| **AWS EKS** | 컨테이너 오케스트레이션 | Kubernetes 클러스터 |

---

## 전체 아키텍처

### 시스템 구성도

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Developer["👨‍💻 개발자"]
        CODE[코드 작성/수정]
    end

    subgraph CodeCommit["AWS CodeCommit"]
        APP_REPO[cicd-demo-app<br/>애플리케이션 소스]
        K8S_REPO[cicd-demo-k8s<br/>K8s 매니페스트]
    end

    subgraph CI["CI - Jenkins"]
        JENKINS[Jenkins Controller]
        AGENT[Jenkins Agent Pod]
    end

    subgraph Registry["AWS ECR"]
        ECR[cicd-demo-app<br/>Docker 이미지]
    end

    subgraph CD["CD - ArgoCD"]
        ARGO[ArgoCD Server]
    end

    subgraph EKS["AWS EKS Cluster"]
        APP_POD1[App Pod 1]
        APP_POD2[App Pod 2]
        SVC[LoadBalancer<br/>Service]
    end

    subgraph User["👤 사용자"]
        BROWSER[웹 브라우저]
    end

    CODE -->|1. git push| APP_REPO
    APP_REPO -->|2. 소스 체크아웃| JENKINS
    JENKINS -->|3. Agent 생성| AGENT
    AGENT -->|4. Docker 빌드 & 푸시| ECR
    AGENT -->|5. 이미지 태그 업데이트| K8S_REPO
    K8S_REPO -->|6. 변경 감지| ARGO
    ARGO -->|7. 배포| APP_POD1
    ARGO -->|7. 배포| APP_POD2
    SVC --> APP_POD1
    SVC --> APP_POD2
    BROWSER -->|8. 접속| SVC
```

### GitOps 패턴 설명

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph Source["소스 레포지토리"]
        APP[cicd-demo-app<br/>- app/main.py<br/>- Dockerfile<br/>- Jenkinsfile]
    end

    subgraph Config["설정 레포지토리"]
        K8S[cicd-demo-k8s<br/>- deployment.yaml<br/>- service.yaml]
    end

    subgraph Principle["GitOps 원칙"]
        P1[Git = 단일 진실 공급원]
        P2[선언적 인프라]
        P3[자동 동기화]
    end

    APP -->|CI Pipeline| K8S
    K8S -->|CD Pipeline| P1
    P1 --> P2
    P2 --> P3
```

**왜 레포지토리를 분리하나요?**

1. **관심사의 분리**: 애플리케이션 코드와 배포 설정을 독립적으로 관리
2. **권한 분리**: 개발자는 소스 코드만, 운영팀은 배포 설정만 관리 가능
3. **배포 이력 추적**: 배포 변경사항만 별도로 추적 가능
4. **롤백 용이**: 배포 설정만 롤백 가능

---

## 구성 요소 설명

### 1. AWS CodeCommit (Git 저장소)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Repositories["CodeCommit 레포지토리"]
        subgraph AppRepo["cicd-demo-app"]
            APP_CODE["/app<br/>애플리케이션 코드"]
            JENKINS_FILE["/jenkins<br/>Jenkinsfile"]
        end

        subgraph K8sRepo["cicd-demo-k8s"]
            K8S_MANIFESTS["/k8s<br/>deployment.yaml<br/>service.yaml"]
        end
    end

    DEV[개발자] -->|코드 푸시| AppRepo
    JENKINS[Jenkins] -->|이미지 태그 업데이트| K8sRepo
    ARGO[ArgoCD] -->|매니페스트 감시| K8sRepo
```

**역할:**
- `cicd-demo-app`: 애플리케이션 소스 코드와 빌드 설정 (Jenkinsfile) 저장
- `cicd-demo-k8s`: Kubernetes 배포 매니페스트 저장 (ArgoCD가 감시)

---

### 2. Jenkins (CI 도구)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph JenkinsSystem["Jenkins 시스템"]
        subgraph Controller["Jenkins Controller"]
            PIPELINE[Pipeline Job<br/>cicd-demo-pipeline]
            CREDS[Credentials<br/>- codecommit-credentials<br/>- aws-credentials]
            K8S_CLOUD[Kubernetes Cloud<br/>설정]
        end

        subgraph AgentPod["동적 Agent Pod"]
            JNLP[JNLP Container<br/>Jenkins 통신]
            DOCKER[Docker Container<br/>이미지 빌드]
            AWS_CLI[AWS CLI Container<br/>ECR 인증]
        end
    end

    Controller -->|Pod 생성| AgentPod
    AgentPod -->|빌드 완료 후| Controller
    AgentPod -.->|자동 삭제| AgentPod
```

**역할:**
- 소스 코드 체크아웃
- Docker 이미지 빌드
- ECR에 이미지 푸시
- K8s 매니페스트 레포지토리 업데이트

**Jenkins Agent Pod의 특징:**
- 빌드 시에만 동적으로 생성
- 빌드 완료 후 자동 삭제
- 리소스 효율적 사용

---

### 3. AWS ECR (컨테이너 레지스트리)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph ECR["AWS ECR"]
        REPO[cicd-demo-app 레포지토리]

        subgraph Images["이미지 태그"]
            V1[v0.0.1]
            V2[v0.0.2]
            V3[v0.0.3]
            LATEST[latest]
        end
    end

    JENKINS[Jenkins] -->|docker push| REPO
    REPO --> Images
    EKS[EKS] -->|docker pull| REPO
```

**역할:**
- Docker 이미지 저장 및 버전 관리
- EKS에서 이미지 Pull

---

### 4. ArgoCD (CD 도구)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph ArgoCD["ArgoCD"]
        SERVER[ArgoCD Server<br/>Web UI]
        REPO_SERVER[Repo Server<br/>Git 감시]
        APP_CONTROLLER[Application Controller<br/>동기화 관리]
    end

    subgraph GitRepo["cicd-demo-k8s"]
        MANIFESTS[deployment.yaml<br/>service.yaml]
    end

    subgraph EKS["EKS Cluster"]
        DEPLOYMENT[Deployment]
        SERVICE[Service]
        PODS[Pods]
    end

    REPO_SERVER -->|1. 폴링| GitRepo
    REPO_SERVER -->|2. 변경 감지| APP_CONTROLLER
    APP_CONTROLLER -->|3. 비교| EKS
    APP_CONTROLLER -->|4. 동기화| EKS
    SERVER -->|모니터링| APP_CONTROLLER
```

**역할:**
- Git 레포지토리 변경 감시
- Kubernetes 클러스터와 Git 상태 비교
- 차이 발생 시 동기화 (자동 또는 수동)

**동기화 모드:**
| 모드 | 설명 |
|------|------|
| **Auto Sync** | Git 변경 감지 시 자동 배포 |
| **Manual Sync** | 사용자가 Sync 버튼 클릭 시 배포 |

---

### 5. AWS EKS (Kubernetes 클러스터)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph EKS["AWS EKS Cluster"]
        subgraph Namespaces["Namespaces"]
            subgraph Jenkins_NS["jenkins namespace"]
                JENKINS_POD[Jenkins Controller]
                JENKINS_SVC[Jenkins Service<br/>LoadBalancer]
            end

            subgraph ArgoCD_NS["argocd namespace"]
                ARGO_POD[ArgoCD Server]
                ARGO_SVC[ArgoCD Service<br/>LoadBalancer]
            end

            subgraph Default_NS["default namespace"]
                APP_DEPLOY[cicd-demo-app<br/>Deployment]
                APP_SVC[cicd-demo-app<br/>Service LoadBalancer]
                POD1[Pod 1]
                POD2[Pod 2]
            end
        end
    end

    APP_DEPLOY --> POD1
    APP_DEPLOY --> POD2
    APP_SVC --> POD1
    APP_SVC --> POD2

    USER[사용자] -->|접속| APP_SVC
```

**역할:**
- 컨테이너 오케스트레이션
- 서비스 로드밸런싱
- 자동 복구 및 스케일링

---

## 상세 프로세스

### 전체 파이프라인 흐름

```mermaid
%%{init: {'theme': 'dark'}}%%
sequenceDiagram
    participant DEV as 👨‍💻 개발자
    participant APP as CodeCommit<br/>(cicd-demo-app)
    participant JC as Jenkins<br/>Controller
    participant JA as Jenkins<br/>Agent Pod
    participant ECR as AWS ECR
    participant K8S as CodeCommit<br/>(cicd-demo-k8s)
    participant ARGO as ArgoCD
    participant EKS as EKS Pods
    participant USER as 👤 사용자

    Note over DEV,USER: 🚀 CI/CD 파이프라인 시작

    rect rgb(30, 60, 90)
        Note over DEV,APP: Step 1: 코드 푸시
        DEV->>DEV: main.py 버전 수정<br/>(v0.0.2 → v0.0.3)
        DEV->>APP: git push origin main
    end

    rect rgb(90, 60, 30)
        Note over APP,ECR: Step 2-5: CI (Jenkins)
        DEV->>JC: Build Now 클릭
        JC->>JA: Agent Pod 생성
        JA->>APP: 소스 코드 체크아웃
        JA->>JA: 버전 파싱 (v0.0.3)
        JA->>JA: Docker 이미지 빌드
        JA->>ECR: 이미지 푸시<br/>(v0.0.3, latest)
    end

    rect rgb(30, 90, 60)
        Note over JA,K8S: Step 6: 매니페스트 업데이트
        JA->>K8S: deployment.yaml 수정<br/>(image: v0.0.3)
        JA->>JC: 빌드 완료
        JC->>JA: Agent Pod 삭제
    end

    rect rgb(90, 30, 60)
        Note over K8S,EKS: Step 7-8: CD (ArgoCD)
        ARGO->>K8S: 변경 감지
        ARGO->>ARGO: Out of Sync 상태
        DEV->>ARGO: Sync 클릭 (수동 모드)
        ARGO->>EKS: Rolling Update 시작
        EKS->>EKS: 새 Pod 생성 (v0.0.3)
        EKS->>EKS: 기존 Pod 종료 (v0.0.2)
        ARGO->>ARGO: Synced 상태
    end

    rect rgb(50, 50, 90)
        Note over EKS,USER: Step 9: 배포 확인
        USER->>EKS: /version 접속
        EKS->>USER: {"version": "v0.0.3"}
    end
```

---

### Step 1: 코드 푸시

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph Local["로컬 개발 환경"]
        EDIT[main.py 수정<br/>APP_VERSION = 'v0.0.3']
        GIT_ADD[git add .]
        GIT_COMMIT[git commit -m '...']
        GIT_PUSH[git push origin main]
    end

    subgraph Remote["CodeCommit"]
        REPO[cicd-demo-app<br/>main 브랜치]
    end

    EDIT --> GIT_ADD --> GIT_COMMIT --> GIT_PUSH --> REPO
```

**개발자가 하는 일:**
1. `app/main.py` 파일에서 `APP_VERSION` 값 수정
2. 변경사항 커밋 및 푸시

**이 단계에서 일어나는 일:**
- 소스 코드가 CodeCommit에 저장됨
- 아직 아무 자동화도 트리거되지 않음 (수동 빌드 설정)

---

### Step 2: Jenkins 빌드 트리거

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Trigger["빌드 트리거 방식"]
        MANUAL[수동 빌드<br/>Build Now 클릭]
        AUTO[자동 빌드<br/>Poll SCM / Webhook]
    end

    subgraph Jenkins["Jenkins"]
        JOB[cicd-demo-pipeline Job]
        JENKINSFILE[Jenkinsfile 로드]
    end

    MANUAL -->|현재 설정| JOB
    AUTO -.->|미사용| JOB
    JOB --> JENKINSFILE
```

**현재 설정: 수동 빌드**
- Jenkins 대시보드에서 `Build Now` 클릭
- 원하는 시점에 배포 제어 가능

**자동 빌드 옵션 (미사용):**
- Poll SCM: 주기적으로 Git 변경 확인
- Webhook: Git 푸시 시 자동 트리거

---

### Step 3: Jenkins Agent Pod 생성

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Controller["Jenkins Controller"]
        PIPELINE[Pipeline 실행]
        K8S_PLUGIN[Kubernetes Plugin]
    end

    subgraph K8sAPI["Kubernetes API"]
        CREATE[Pod 생성 요청]
    end

    subgraph AgentPod["Jenkins Agent Pod"]
        subgraph Containers["컨테이너"]
            JNLP[jnlp<br/>Jenkins 통신]
            DOCKER[docker<br/>Docker-in-Docker]
            AWS[aws-cli<br/>AWS 명령어]
        end

        subgraph Volume["공유 볼륨"]
            WORKSPACE[/home/jenkins/agent<br/>작업 공간]
        end
    end

    PIPELINE --> K8S_PLUGIN
    K8S_PLUGIN --> CREATE
    CREATE --> AgentPod
    JNLP --> WORKSPACE
    DOCKER --> WORKSPACE
    AWS --> WORKSPACE
```

**Agent Pod 구성:**
| 컨테이너 | 이미지 | 역할 |
|----------|--------|------|
| jnlp | jenkins/inbound-agent | Jenkins와 통신 |
| docker | docker:24-dind | Docker 빌드 실행 |
| aws-cli | amazon/aws-cli | AWS 명령어 실행 |

**공유 볼륨의 중요성:**
- 모든 컨테이너가 같은 작업 공간 사용
- ECR 비밀번호 파일 공유 등에 활용

---

### Step 4: Docker 이미지 빌드 & ECR 푸시

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Build["Docker 빌드"]
        CHECKOUT[소스 체크아웃]
        PARSE[버전 파싱<br/>grep '^APP_VERSION']
        BUILD[docker build<br/>-t cicd-demo-app:v0.0.3]
        TAG[docker tag<br/>ECR 경로 추가]
    end

    subgraph Push["ECR 푸시"]
        LOGIN[ECR 로그인<br/>aws ecr get-login-password]
        PUSH1[docker push :v0.0.3]
        PUSH2[docker push :latest]
    end

    subgraph ECR["AWS ECR"]
        IMAGE[cicd-demo-app<br/>v0.0.3, latest]
    end

    CHECKOUT --> PARSE --> BUILD --> TAG
    TAG --> LOGIN --> PUSH1 --> PUSH2 --> IMAGE
```

**빌드 과정:**
1. CodeCommit에서 소스 코드 체크아웃
2. `main.py`에서 버전 문자열 추출
3. Dockerfile 기반으로 이미지 빌드
4. ECR 경로로 태그 지정
5. ECR에 로그인 후 푸시

---

### Step 5: K8s 매니페스트 업데이트

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Jenkins["Jenkins Agent"]
        CLONE[cicd-demo-k8s 클론]
        SED[sed로 이미지 태그 수정<br/>v0.0.2 → v0.0.3]
        COMMIT[git commit]
        PUSH[git push]
    end

    subgraph Before["수정 전 deployment.yaml"]
        OLD[image: .../cicd-demo-app:v0.0.2]
    end

    subgraph After["수정 후 deployment.yaml"]
        NEW[image: .../cicd-demo-app:v0.0.3]
    end

    subgraph CodeCommit["cicd-demo-k8s"]
        REPO[main 브랜치]
    end

    CLONE --> Before
    Before --> SED --> After
    After --> COMMIT --> PUSH --> REPO
```

**이 단계의 핵심:**
- Jenkins가 K8s 매니페스트 레포지토리의 이미지 태그를 자동 업데이트
- ArgoCD가 이 변경을 감지하여 배포 트리거

---

### Step 6: ArgoCD 동기화

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Detection["변경 감지"]
        POLL[Git 폴링<br/>3분 주기]
        DETECT[변경 감지]
        COMPARE[현재 상태 비교]
    end

    subgraph Status["동기화 상태"]
        SYNCED[Synced ✅<br/>Git = 클러스터]
        OUTOFSYNC[OutOfSync ⚠️<br/>Git ≠ 클러스터]
    end

    subgraph Action["동기화 실행"]
        MANUAL_SYNC[수동: Sync 버튼 클릭]
        AUTO_SYNC[자동: Auto-Sync 활성화 시]
        APPLY[kubectl apply 실행]
    end

    POLL --> DETECT --> COMPARE
    COMPARE --> OUTOFSYNC
    OUTOFSYNC --> MANUAL_SYNC
    OUTOFSYNC -.-> AUTO_SYNC
    MANUAL_SYNC --> APPLY
    AUTO_SYNC -.-> APPLY
    APPLY --> SYNCED
```

**ArgoCD 동기화 상태:**
| 상태 | 의미 | 아이콘 |
|------|------|--------|
| Synced | Git과 클러스터가 동일 | ✅ 녹색 |
| OutOfSync | Git과 클러스터가 다름 | ⚠️ 노란색 |
| Unknown | 상태 확인 불가 | ❓ 회색 |

---

### Step 7: Kubernetes Rolling Update

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Phase1["Phase 1: 초기 상태"]
        P1_POD1[Pod A<br/>v0.0.2 ✅]
        P1_POD2[Pod B<br/>v0.0.2 ✅]
    end

    subgraph Phase2["Phase 2: 새 Pod 생성"]
        P2_POD1[Pod A<br/>v0.0.2 ✅]
        P2_POD2[Pod B<br/>v0.0.2 ✅]
        P2_POD3[Pod C<br/>v0.0.3 🔄]
    end

    subgraph Phase3["Phase 3: 기존 Pod 종료"]
        P3_POD1[Pod A<br/>v0.0.2 ⏳ 종료중]
        P3_POD2[Pod B<br/>v0.0.2 ✅]
        P3_POD3[Pod C<br/>v0.0.3 ✅]
    end

    subgraph Phase4["Phase 4: 완료"]
        P4_POD1[Pod C<br/>v0.0.3 ✅]
        P4_POD2[Pod D<br/>v0.0.3 ✅]
    end

    Phase1 -->|"새 Pod 생성"| Phase2
    Phase2 -->|"Ready 확인 후<br/>기존 Pod 종료"| Phase3
    Phase3 -->|"반복"| Phase4
```

**Rolling Update 특징:**
- 점진적으로 Pod 교체
- 서비스 중단 없음
- Ready 상태 확인 후 다음 단계 진행

---

### Step 8: 배포 완료 및 확인

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph User["사용자"]
        BROWSER[웹 브라우저]
    end

    subgraph EKS["EKS Cluster"]
        LB[LoadBalancer<br/>AWS ELB]
        POD1[Pod 1<br/>v0.0.3]
        POD2[Pod 2<br/>v0.0.3]
    end

    subgraph Response["응답"]
        JSON["{ 'version': 'v0.0.3' }"]
    end

    BROWSER -->|"GET /version"| LB
    LB --> POD1
    LB --> POD2
    POD1 --> JSON
    POD2 --> JSON
    JSON --> BROWSER
```

**확인 방법:**
- 브라우저에서 `/version` 엔드포인트 접속
- 새 버전 확인 (v0.0.3)

---

## 실제 배포 흐름 예시

### v0.0.2 → v0.0.3 업데이트 시나리오

```mermaid
%%{init: {'theme': 'dark'}}%%
timeline
    title CI/CD 파이프라인 타임라인

    section 개발 (1분)
        코드 수정 : main.py 버전 변경
        Git 푸시 : CodeCommit에 푸시

    section CI - Jenkins (3-5분)
        빌드 시작 : Build Now 클릭
        Agent 생성 : K8s Pod 생성
        Docker 빌드 : 이미지 빌드
        ECR 푸시 : 이미지 업로드
        매니페스트 업데이트 : K8s 레포 수정

    section CD - ArgoCD (1-2분)
        변경 감지 : OutOfSync 상태
        동기화 : Sync 클릭
        Rolling Update : Pod 교체
        완료 : Synced 상태

    section 확인 (즉시)
        버전 확인 : /version 접속
```

---

## 무중단 배포

### Rolling Update 동작 원리

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TB
    subgraph Deployment["Deployment 설정"]
        REPLICAS[replicas: 2]
        STRATEGY[strategy: RollingUpdate]
        MAX_UNAVAILABLE[maxUnavailable: 1]
        MAX_SURGE[maxSurge: 1]
    end

    subgraph Rules["규칙"]
        R1[최소 1개 Pod는<br/>항상 Running]
        R2[최대 3개 Pod까지<br/>동시 존재 가능]
        R3[새 Pod Ready 후<br/>기존 Pod 종료]
    end

    Deployment --> Rules
```

### Graceful Shutdown 과정

```mermaid
%%{init: {'theme': 'dark'}}%%
sequenceDiagram
    participant SVC as Service
    participant POD as Pod (v0.0.2)
    participant APP as Application

    Note over SVC,APP: Pod 종료 시작

    SVC->>POD: Endpoints에서 제거
    Note over SVC: 새 요청 차단

    POD->>APP: SIGTERM 신호
    Note over APP: 진행 중인 요청 처리

    alt 30초 내 완료
        APP->>POD: 정상 종료
        POD->>POD: Pod 삭제
    else 30초 초과
        POD->>APP: SIGKILL 강제 종료
        POD->>POD: Pod 삭제
    end
```

**무중단 배포 핵심:**
| 설정 | 기본값 | 설명 |
|------|--------|------|
| terminationGracePeriodSeconds | 30초 | Pod 종료 대기 시간 |
| maxUnavailable | 25% | 동시 종료 가능 Pod 수 |
| maxSurge | 25% | 추가 생성 가능 Pod 수 |

---

## 요약

### CI/CD 파이프라인 한눈에 보기

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph CI["CI (Jenkins)"]
        direction TB
        A[코드 푸시] --> B[빌드 트리거]
        B --> C[Docker 빌드]
        C --> D[ECR 푸시]
        D --> E[매니페스트 업데이트]
    end

    subgraph CD["CD (ArgoCD)"]
        direction TB
        F[변경 감지] --> G[동기화]
        G --> H[Rolling Update]
        H --> I[배포 완료]
    end

    CI --> CD

    style CI fill:#e6f3ff
    style CD fill:#ffe6e6
```

### 핵심 포인트

1. **GitOps**: Git이 모든 상태의 단일 진실 공급원
2. **자동화**: 코드 푸시 → 배포까지 자동화 (수동 트리거 가능)
3. **무중단**: Rolling Update로 서비스 중단 없이 배포
4. **추적성**: 모든 변경사항이 Git에 기록됨
5. **롤백**: 이전 버전으로 쉽게 롤백 가능

---

## 다음 단계

- [ ] 자동 빌드 트리거 설정 (Webhook)
- [ ] 자동 동기화 활성화 (Auto-Sync)
- [ ] 모니터링 도구 연동 (Prometheus, Grafana)
- [ ] 알림 설정 (Slack, Email)
