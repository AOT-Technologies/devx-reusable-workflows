# Multi-stage build for Python app
FROM python:3.11-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev linux-headers curl

WORKDIR /app

# The artifact is downloaded by the CI pipeline.
# ARTIFACT_NAME is passed as a build argument.
ARG ARTIFACT_NAME

COPY ${ARTIFACT_NAME} ./

RUN echo "📦 Extracting artifact: ${ARTIFACT_NAME}..." && \
    mkdir -p dist && \
    # We expect the artifact to be a .whl file
    cp ${ARTIFACT_NAME} dist/ && \
    rm ${ARTIFACT_NAME}

# Runtime stage
FROM python:3.11-alpine

WORKDIR /app

# Install production dependencies
# Note: In a real app, you might want to copy requirements.txt and install first
# for better caching, but here we install from the wheel.

# Copy wheel from builder
COPY --from=builder /app/dist/*.whl .
RUN pip install --no-cache-dir *.whl && rm *.whl

# Make sure scripts are usable
ENV PYTHONPATH=/app

# Health check
RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:5000/health || exit 1

# Expose port
EXPOSE 5000

# Run with gunicorn (production server)
# Note: gunicorn should be in the wheel's dependencies
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "30", "demo_app.app:app"]