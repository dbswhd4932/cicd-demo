"""
CI/CD Demo Application
버전 확인을 위한 간단한 FastAPI 애플리케이션
"""
from fastapi import FastAPI
from pydantic import BaseModel

# 애플리케이션 버전 - 이 값을 변경하여 배포 테스트
APP_VERSION = "v0.0.3"

app = FastAPI(
    title="CI/CD Demo API",
    description="CI/CD 파이프라인 학습을 위한 데모 애플리케이션",
    version=APP_VERSION
)


class VersionResponse(BaseModel):
    version: str
    message: str


class HealthResponse(BaseModel):
    status: str


@app.get("/", response_model=dict)
def root():
    """루트 엔드포인트"""
    return {
        "app": "CI/CD Demo",
        "version": APP_VERSION
    }


@app.get("/version", response_model=VersionResponse)
def get_version():
    """
    현재 애플리케이션 버전을 반환합니다.
    배포 확인용 엔드포인트입니다.
    """
    return VersionResponse(
        version=APP_VERSION,
        message=f"Current version is {APP_VERSION}"
    )


@app.get("/health", response_model=HealthResponse)
def health_check():
    """
    헬스체크 엔드포인트
    Kubernetes liveness/readiness probe에 사용됩니다.
    """
    return HealthResponse(status="healthy")
