# Docker-Only Build - Complete Example

This example is for projects that **already have their own build process** and just need Docker image building with security scanning.

**Use Cases:**
- Monorepos with custom build tools
- Multi-language projects
- Projects with existing CI that just need Docker/security
- Static sites or pre-built artifacts

---

## 📁 Project Structure

```
your-existing-app/
├── .github/
│   └── workflows/
│       └── docker-ci.yaml       # GitHub Actions workflow (Docker only)
├── [your existing code]
├── devx-ci.yaml                 # DevX CI configuration
├── Dockerfile                   # Your existing or new Dockerfile
└── .dockerignore
```

---

## 1️⃣ devx-ci.yaml (Minimal - Docker Only)

```yaml
# DevX CI Configuration - Docker Build Only
# This skips language-specific builds and goes straight to Docker

project:
  # Choose any language (required field, but not used for builds)
  language: node  # or python or maven - doesn't matter for Docker-only
  working_directory: "."

build:
  run_tests: false  # IMPORTANT: Skip language-specific builds/tests

security:
  # Skip SAST if you have your own security scanning
  sast:
    enabled: false
  
  # Skip IaC if not applicable
  iac:
    enabled: false
  
  # Trivy: Scan Docker image (RECOMMENDED)
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  # SBOM: Generate software bill of materials (RECOMMENDED)
  sbom:
    enabled: true
    format: cyclonedx-json
  
  # SBOM Scan: Check for vulnerabilities
  sbom_scan:
    enabled: true
    severity: medium
    format: sarif

# Docker configuration
docker:
  enabled: true  # This is the only thing we're doing
  dockerfile: Dockerfile
  image_name: my-app
  registry_type: ecr
  platforms: linux/amd64

# AWS Configuration (for ECR)
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

## 2️⃣ .github/workflows/docker-ci.yaml

```yaml
name: Docker Build Pipeline

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

# Prevent multiple runs on same commit
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  docker:
    name: Docker Build & Security Scan
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    with:
      config_path: devx-ci.yaml
    secrets: inherit
```

---

## 3️⃣ Example Scenarios

### **Scenario A: Monorepo with Multiple Services**

```yaml
# devx-ci.yaml
project:
  language: node
  working_directory: "./services/api"  # Build specific service

build:
  run_tests: false  # Tests run elsewhere

docker:
  enabled: true
  working_directory: "./services/api"  # Dockerfile location
  dockerfile: Dockerfile
  image_name: monorepo-api-service
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

**Directory Structure:**
```
monorepo/
├── services/
│   ├── api/
│   │   ├── Dockerfile
│   │   └── [code]
│   └── worker/
│       ├── Dockerfile
│       └── [code]
├── devx-ci-api.yaml      # Config for API service
├── devx-ci-worker.yaml   # Config for worker service
└── .github/workflows/
    ├── api-ci.yaml
    └── worker-ci.yaml
```

---

### **Scenario B: Static Site (Hugo/Jekyll/Next.js SSG)**

```yaml
# devx-ci.yaml
project:
  language: node
  working_directory: "."

build:
  run_tests: false  # Build happens in Dockerfile

security:
  sast:
    enabled: false
  trivy:
    enabled: true

docker:
  enabled: true
  dockerfile: Dockerfile
  image_name: my-static-site
  registry_type: generic
  registry_url: ghcr.io
```

**Dockerfile:**
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build  # Creates 'out/' or 'public/' directory

# Serve stage
FROM nginx:alpine
COPY --from=builder /app/out /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

### **Scenario C: Pre-Built Artifacts (CI uploads artifact, Docker packages it)**

```yaml
# devx-ci.yaml
project:
  language: python
  working_directory: "."

build:
  run_tests: false  # Already built elsewhere

docker:
  enabled: true
  dockerfile: Dockerfile
  image_name: pre-built-app
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

**Dockerfile (expects pre-built artifacts):**
```dockerfile
FROM python:3.11-slim

# Assume artifacts are already in dist/
COPY dist/ /app/
WORKDIR /app

# Install runtime dependencies only
RUN pip install --no-cache-dir -r requirements-prod.txt

EXPOSE 8000
CMD ["gunicorn", "app:app"]
```

---

### **Scenario D: Multi-Language Project**

```yaml
# devx-ci.yaml
project:
  language: node  # Doesn't matter
  working_directory: "."

build:
  run_tests: false  # Custom build in Dockerfile

docker:
  enabled: true
  dockerfile: Dockerfile.multi
  image_name: multi-lang-app
  registry_type: ecr
```

**Dockerfile.multi:**
```dockerfile
# Build frontend (Node.js)
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Build backend (Go)
FROM golang:1.21-alpine AS backend-builder
WORKDIR /backend
COPY backend/go.* ./
RUN go mod download
COPY backend/ ./
RUN go build -o app

# Final image
FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=frontend-builder /frontend/dist /app/static
COPY --from=backend-builder /backend/app /app/server
WORKDIR /app
EXPOSE 8080
CMD ["./server"]
```

---

## 4️⃣ Advanced Configurations

### **Custom Build Args**

```yaml
docker:
  enabled: true
  image_name: my-app
  build_args: |
    VERSION=${{ github.ref_name }}
    COMMIT_SHA=${{ github.sha }}
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
    ENVIRONMENT=production
```

**Use in Dockerfile:**
```dockerfile
ARG VERSION
ARG COMMIT_SHA
ARG BUILD_DATE

LABEL version="${VERSION}" \
      commit="${COMMIT_SHA}" \
      build-date="${BUILD_DATE}"
```

---

### **Multi-Architecture Builds**

```yaml
docker:
  enabled: true
  platforms: linux/amd64,linux/arm64
  image_name: my-app
```

---

### **Different Registries**

#### **AWS ECR:**
```yaml
docker:
  registry_type: ecr
  image_name: my-app

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123:role/GHA
```

#### **GitHub Container Registry:**
```yaml
docker:
  registry_type: generic
  registry_url: ghcr.io
  image_name: my-org/my-app

# Add these secrets to repo:
# REGISTRY_USERNAME: github-username
# REGISTRY_PASSWORD: github-token
```

#### **Docker Hub:**
```yaml
docker:
  registry_type: generic
  registry_url: docker.io
  image_name: dockerhub-username/my-app

# Add these secrets:
# REGISTRY_USERNAME: dockerhub-username
# REGISTRY_PASSWORD: dockerhub-token
```

#### **Private Registry:**
```yaml
docker:
  registry_type: generic
  registry_url: registry.company.com
  image_name: team/my-app

# Add credentials as secrets
```

---

## 5️⃣ When to Use Docker-Only Mode

### ✅ **USE Docker-Only When:**

- You have a monorepo with custom build orchestration
- You're migrating gradually (build exists, adding Docker)
- Your build is complex (multi-language, custom tooling)
- You only need containerization + security scanning
- You have pre-built artifacts to package
- Your tests run in a different CI system

### ❌ **DON'T Use Docker-Only When:**

- You have a simple single-language app
- You want automated testing
- You want SAST scanning on source code
- You're starting a new project

**For standard apps, use the full pipeline:**
- [Node.js Example](../nodejs-express/)
- [Python Example](../python-fastapi/)
- [Java Example](../java-springboot/)

---

## 6️⃣ Security Considerations

### **Even Docker-Only Should Include:**

```yaml
security:
  # Image vulnerability scanning (CRITICAL)
  trivy:
    enabled: true
    fail_on_vuln: true
  
  # Software bill of materials (RECOMMENDED)
  sbom:
    enabled: true
  
  # SBOM vulnerability scan (RECOMMENDED)
  sbom_scan:
    enabled: true
```

### **Why Skip SAST?**

- You're scanning in another tool (SonarQube, Snyk, etc.)
- Code is already scanned before reaching this stage
- This is just a packaging/deployment pipeline

### **Why Keep Trivy?**

- Scans the **final container image**
- Catches OS-level vulnerabilities
- Checks base image CVEs
- Required for production security

---

## 7️⃣ Complete Workflow Example

### **Scenario: Microservices Monorepo**

**Project Structure:**
```
monorepo/
├── .github/workflows/
│   ├── service-a-ci.yaml
│   ├── service-b-ci.yaml
│   └── service-c-ci.yaml
├── services/
│   ├── service-a/
│   │   ├── Dockerfile
│   │   └── devx-ci.yaml
│   ├── service-b/
│   │   ├── Dockerfile
│   │   └── devx-ci.yaml
│   └── service-c/
│       ├── Dockerfile
│       └── devx-ci.yaml
└── shared/
    └── [shared code]
```

**services/service-a/devx-ci.yaml:**
```yaml
project:
  language: node
  working_directory: "./services/service-a"

build:
  run_tests: false  # Tested in root-level CI

docker:
  enabled: true
  working_directory: "./services/service-a"
  image_name: monorepo-service-a
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123:role/GHA
```

**.github/workflows/service-a-ci.yaml:**
```yaml
name: Service A - Docker Build

on:
  push:
    branches: [main]
    paths:
      - 'services/service-a/**'
      - 'shared/**'

jobs:
  docker:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    with:
      config_path: services/service-a/devx-ci.yaml
    secrets: inherit
```

---

## 🚀 Quick Start

### **Step 1: Create Config**

```bash
# Copy template
cp examples/docker-only/devx-ci.yaml ./

# Edit for your needs
vim devx-ci.yaml
```

### **Step 2: Create Workflow**

```bash
# Copy workflow
cp examples/docker-only/.github/workflows/docker-ci.yaml ./.github/workflows/

# Or rename if you have multiple
cp examples/docker-only/.github/workflows/docker-ci.yaml ./.github/workflows/my-service-ci.yaml
```

### **Step 3: Customize**

- Update `image_name`
- Set correct `registry_type`
- Configure AWS role (if ECR)
- Adjust `working_directory` if needed

### **Step 4: Push**

```bash
git add devx-ci.yaml .github/workflows/
git commit -m "Add Docker-only CI/CD"
git push
```

---

## 📊 What Happens

```
1. Load Configuration
   └─ Validates devx-ci.yaml

2. Skip Build Phase
   └─ build.run_tests: false

3. Docker Build
   └─ Build Dockerfile
   └─ Push to registry

4. Security Scans
   ├─ Trivy Scan
   │  └─ Scan container image
   ├─ SBOM Generation
   │  └─ Create inventory
   └─ SBOM Scan
      └─ Check vulnerabilities

5. Done! 🎉
```

**Time:** Typically 3-8 minutes (vs 15-25 for full pipeline)

---

## 🆘 Troubleshooting

**"Tests failed" but run_tests is false?**
- Check that `build.run_tests: false` is set correctly
- Language-specific builds shouldn't run

**Docker build fails?**
```bash
# Test locally
docker build -t test .
```

**Want to add source code scanning later?**
```yaml
security:
  sast:
    enabled: true  # Change to true
    scan_path: "./src"
```

---

## 📚 Next Steps

1. **Add Health Checks to Dockerfile**
   ```dockerfile
   HEALTHCHECK --interval=30s CMD curl -f http://localhost/ || exit 1
   ```

2. **Optimize Image Size**
   - Use multi-stage builds
   - Use alpine base images
   - Minimize layers

3. **Deploy Images**
   - ECS/EKS
   - Cloud Run
   - Kubernetes
   - Lambda (if using container images)

---

**Need full CI/CD?** Check out:
- [Node.js Example](../nodejs-express/)
- [Python Example](../python-fastapi/)
- [Java Example](../java-springboot/)

**Questions?** See [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)