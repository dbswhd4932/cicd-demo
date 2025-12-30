# 멀티스테이지 빌드를 사용한 최적화된 Dockerfile
# Stage 1: 빌드 단계
FROM python:3.11-slim as builder

WORKDIR /app

# 의존성 파일 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: 실행 단계
FROM python:3.11-slim

WORKDIR /app

# 빌드 단계에서 설치된 패키지 복사
COPY --from=builder /root/.local /root/.local

# PATH에 로컬 bin 추가
ENV PATH=/root/.local/bin:$PATH

# 애플리케이션 코드 복사
COPY main.py .

# 비root 사용자로 실행 (보안)
# RUN useradd -m appuser && chown -R appuser:appuser /app
# USER appuser

# 포트 노출
EXPOSE 8000

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# 애플리케이션 실행
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
