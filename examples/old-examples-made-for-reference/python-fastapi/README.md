# Python FastAPI - Complete Example

This is a complete example of using DevX CI/CD with a Python FastAPI REST API.

---

## 📁 Project Structure

```
your-python-app/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions workflow
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── routers/
│   └── models/
├── tests/
│   ├── __init__.py
│   └── test_api.py
├── devx-ci.yaml                 # DevX CI configuration
├── Dockerfile                   # Container definition
├── .dockerignore
├── requirements.txt             # Python dependencies
├── requirements-dev.txt         # Development dependencies
├── pytest.ini                   # Pytest configuration
└── README.md
```

---

## 1️⃣ devx-ci.yaml

```yaml
# DevX CI Configuration for Python FastAPI Application
# This configuration enables automated CI/CD with security scanning

project:
  language: python
  version: "3.11"                # Python 3.11
  working_directory: "."

build:
  run_tests: true                # Run pytest before building
  artifact_path: "dist/"         # Upload distribution files (wheels/sdist)

security:
  # SAST: Static Application Security Testing
  # Scans source code for vulnerabilities, secrets, and bad practices
  sast:
    enabled: true
    scan_path: "./app"           # Only scan application code
    exclude_paths: "tests/,__pycache__/,.pytest_cache/,venv/,dist/"
    severity: ERROR              # Report ERROR level findings
    fail_on_findings: true       # Block pipeline if issues found
  
  # IaC: Infrastructure as Code scanning
  # Enable if you have Terraform/K8s/CloudFormation
  iac:
    enabled: false
  
  # Trivy: Container vulnerability scanning
  # Scans the built Docker image for OS/package vulnerabilities
  trivy:
    enabled: true
    severity: CRITICAL,HIGH      # Block on critical and high severity
    fail_on_vuln: true           # Block pipeline if vulnerabilities found
  
  # SBOM: Software Bill of Materials
  # Creates an inventory of all dependencies
  sbom:
    enabled: true
    format: cyclonedx-json       # Industry standard format
  
  # SBOM Scan: Vulnerability scanning based on SBOM
  # Checks SBOM against known CVE databases
  sbom_scan:
    enabled: true
    severity: medium             # Report medium and above
    format: sarif                # Upload to GitHub Security tab

docker:
  enabled: true
  dockerfile: Dockerfile
  image_name: python-fastapi-api # Your app name
  image_tag: ""                  # Defaults to git commit SHA
  registry_type: ecr             # AWS ECR (can be 'generic' for GHCR/DockerHub)
  
  # Multi-line build arguments
  build_args: |
    PYTHON_VERSION=3.11
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
  
  platforms: linux/amd64         # Single platform (faster builds)
  # For multi-arch: linux/amd64,linux/arm64

# AWS Configuration (required for ECR)
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole

# For GHCR instead of ECR, use:
# docker:
#   registry_type: generic
#   registry_url: ghcr.io
#   image_name: your-org/python-fastapi-api
# 
# Then add these secrets to your repo:
#   REGISTRY_USERNAME: your-github-username
#   REGISTRY_PASSWORD: github-token-with-packages-write
```

---

## 2️⃣ .github/workflows/ci.yaml

```yaml
name: CI Pipeline

on:
  push:
    branches:
      - main
      - develop
      - 'feature/**'
  pull_request:
    branches:
      - main
      - develop

# Prevent multiple runs on same commit
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    name: DevX CI/CD Pipeline
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    with:
      config_path: devx-ci.yaml
    secrets: inherit  # Pass all secrets to the reusable workflow
```

---

## 3️⃣ Dockerfile

```dockerfile
# Multi-stage build for smaller final image
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# ============================================
# Production Stage
# ============================================
FROM python:3.11-slim AS production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 -s /bin/bash appuser

# Set working directory
WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser ./app ./app

# Switch to non-root user
USER appuser

# Add .local/bin to PATH for installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Start application with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

---

## 4️⃣ .dockerignore

```
# Virtual environments
venv
env
.venv
.env

# Python cache
__pycache__
*.py[cod]
*$py.class
*.so

# Testing
.pytest_cache
.coverage
htmlcov
.tox
.hypothesis

# Distribution / packaging
dist
build
*.egg-info
.eggs

# Git
.git
.gitignore

# CI/CD
.github
devx-ci.yaml

# Documentation
*.md
docs

# IDE
.vscode
.idea
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Development
requirements-dev.txt
pytest.ini
.editorconfig
```

---

## 5️⃣ requirements.txt

```txt
# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0

# Validation
pydantic==2.5.0
pydantic-settings==2.1.0

# Database (if needed)
sqlalchemy==2.0.23
asyncpg==0.29.0

# Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Utilities
python-dotenv==1.0.0
```

---

## 6️⃣ requirements-dev.txt

```txt
# Include production requirements
-r requirements.txt

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
httpx==0.25.2

# Code Quality
black==23.11.0
flake8==6.1.0
mypy==1.7.1
isort==5.12.0

# Documentation
mkdocs==1.5.3
mkdocs-material==9.4.14
```

---

## 7️⃣ pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --verbose
    --color=yes
    --cov=app
    --cov-report=term-missing
    --cov-report=html
    --cov-report=xml
asyncio_mode = auto
```

---

## 8️⃣ app/main.py (Example)

```python
"""
FastAPI Application Entry Point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Python FastAPI API",
    description="Example FastAPI application with DevX CI/CD",
    version="1.0.0",
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to Python FastAPI API",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "python-fastapi-api"
    }


@app.get("/api/items")
async def list_items():
    """List items endpoint"""
    return {
        "items": [
            {"id": 1, "name": "Item 1"},
            {"id": 2, "name": "Item 2"},
        ]
    }
```

---

## 9️⃣ tests/test_api.py (Example)

```python
"""
API Tests
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data


def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_list_items():
    """Test list items endpoint"""
    response = client.get("/api/items")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) > 0
```

---

## 🚀 How to Use This Example

### **Step 1: Copy Files**

```bash
# Copy configuration files
cp examples/python-fastapi/devx-ci.yaml ./
cp examples/python-fastapi/.github/workflows/ci.yaml ./.github/workflows/
cp examples/python-fastapi/Dockerfile ./
cp examples/python-fastapi/.dockerignore ./
cp examples/python-fastapi/requirements.txt ./
cp examples/python-fastapi/pytest.ini ./
```

### **Step 2: Set Up Virtual Environment**

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### **Step 3: Test Locally**

```bash
# Run tests
pytest

# Run application
uvicorn app.main:app --reload

# Visit http://localhost:8000/docs for API documentation
```

### **Step 4: Customize**

Edit `devx-ci.yaml`:
- Change `image_name` to your app name
- Update `role_to_assume` with your AWS IAM role
- Adjust security settings if needed

### **Step 5: Commit and Push**

```bash
git add devx-ci.yaml .github/workflows/ci.yaml Dockerfile .dockerignore requirements.txt pytest.ini
git commit -m "Add DevX CI/CD pipeline"
git push
```

---

## 📊 What Happens When You Push

```
1. Load Configuration
   └─ Validates devx-ci.yaml

2. Security Gates (Parallel)
   ├─ SAST Scan (Semgrep)
   │  └─ Scans app/ for vulnerabilities
   └─ Results → GitHub Security Tab

3. Build & Test
   ├─ pip install -r requirements.txt
   ├─ pytest (run unit tests with coverage)
   └─ Artifacts: test results & coverage reports

4. Docker Build
   ├─ Build multi-stage Dockerfile
   └─ Push to ECR: 123456.dkr.ecr.us-east-1.amazonaws.com/python-fastapi-api:abc1234

5. Container Security
   ├─ Trivy Scan
   │  └─ Scan image for OS/package vulnerabilities
   ├─ SBOM Generation
   │  └─ Create software bill of materials
   └─ SBOM Scan
      └─ Check for known CVEs

6. Success! 🎉
   └─ Image ready for deployment
```

---

## 🔍 Viewing Results

### **Build Artifacts**
- Go to **Actions → Workflow run → Artifacts**
- Download: `python-build-{sha}` (contains dist/ folder)

### **Test Results & Coverage**
- Go to **Actions → Workflow run → Artifacts**
- Download: `python-test-results-{sha}`
- Contains:
  - `coverage.xml` - Coverage report
  - `htmlcov/` - HTML coverage report
  - `junit.xml` - Test results

### **Security Findings**
- Go to **Security → Code scanning alerts**
- Filter by tool: `sast-semgrep`, `trivy-image`, `sbom-grype`

### **Docker Image**
- Image URI: `{account}.dkr.ecr.{region}.amazonaws.com/{image_name}:{git-sha}`
- Image Digest: `sha256:abc123...` (immutable reference)

---

## 🛠️ Customization Options

### **Custom Test Command**
```yaml
# devx-ci.yaml
build:
  run_tests: true
  # Default command: python -m pytest
  # Customize in pytest.ini or via pytest configuration
```

### **Add Code Quality Checks**
```bash
# Run before committing
black app tests              # Format code
isort app tests              # Sort imports
flake8 app tests             # Lint code
mypy app                     # Type checking
```

### **Database Testing**
```python
# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()
```

### **Async Testing**
```python
# tests/test_async_api.py
import pytest

@pytest.mark.asyncio
async def test_async_endpoint():
    """Test async endpoint"""
    response = await client.get("/async-endpoint")
    assert response.status_code == 200
```

---

## 🆘 Troubleshooting

**Tests Failing?**
```bash
# Run locally first
pytest -v
```

**Import Errors?**
```bash
# Ensure app is in PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:${PWD}"
pytest
```

**Docker Build Failing?**
```bash
# Test locally
docker build -t test .
docker run -p 8000:8000 test
```

**Dependency Issues?**
```bash
# Update dependencies
pip list --outdated
pip install --upgrade package-name
pip freeze > requirements.txt
```

---

## 📚 Next Steps

1. **Add Database Migrations**
   ```bash
   pip install alembic
   alembic init migrations
   ```

2. **Add API Documentation**
   - FastAPI auto-generates docs at `/docs` (Swagger UI)
   - ReDoc available at `/redoc`

3. **Add Environment Variables**
   ```python
   # app/config.py
   from pydantic_settings import BaseSettings
   
   class Settings(BaseSettings):
       database_url: str
       secret_key: str
       
       class Config:
           env_file = ".env"
   ```

4. **Deploy**
   - Use the image URI from workflow outputs
   - Deploy to ECS, EKS, Lambda, Cloud Run, etc.

---

**Questions?** Check [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)