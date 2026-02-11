# Optimized FastAPI Dockerfile for DevX Pipeline
FROM python:3.11-alpine AS builder

WORKDIR /app

# The artifact is downloaded by the CI pipeline.
ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} ./

# Runtime stage
FROM python:3.11-alpine
WORKDIR /app

# Copy wheel from builder and install
COPY --from=builder /app/*.whl .
RUN pip install --no-cache-dir *.whl && rm *.whl

# Install production server
RUN pip install --no-cache-dir gunicorn uvicorn

EXPOSE 8000
HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1
CMD ["gunicorn", "app.main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]