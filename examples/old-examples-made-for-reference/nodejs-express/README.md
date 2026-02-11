# Node.js Express API - Complete Example

This is a complete example of using DevX CI/CD with a Node.js Express REST API.

---

## 📁 Project Structure

```
your-nodejs-app/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions workflow
├── src/
│   ├── index.js
│   ├── routes/
│   └── controllers/
├── tests/
│   └── api.test.js
├── devx-ci.yaml                 # DevX CI configuration
├── Dockerfile                   # Container definition
├── .dockerignore
├── package.json
├── package-lock.json
└── README.md
```

---

## 1️⃣ devx-ci.yaml

```yaml
# DevX CI Configuration for Node.js Express Application
# This configuration enables automated CI/CD with security scanning

project:
  language: node
  version: "20"                  # Node.js 20 LTS
  working_directory: "."

build:
  run_tests: true                # Run npm test before building
  artifact_path: "dist/"         # Upload dist/ folder as artifact

security:
  # SAST: Static Application Security Testing
  # Scans source code for vulnerabilities, secrets, and bad practices
  sast:
    enabled: true
    scan_path: "./src"           # Only scan source code
    exclude_paths: "node_modules/,tests/,coverage/,dist/"
    severity: ERROR              # Report ERROR level findings
    fail_on_findings: true       # Block pipeline if issues found
  
  # IaC: Infrastructure as Code scanning
  # Not needed for typical Node.js apps unless you have Terraform/K8s
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
  image_name: nodejs-express-api # Your app name
  image_tag: ""                  # Defaults to git commit SHA
  registry_type: ecr             # AWS ECR (can be 'generic' for GHCR/DockerHub)
  
  # Multi-line build arguments
  build_args: |
    NODE_ENV=production
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
#   image_name: your-org/nodejs-express-api
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
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build application (if you have a build step)
RUN npm run build || echo "No build step defined"

# ============================================
# Production Stage
# ============================================
FROM node:20-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/src ./src

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
```

---

## 4️⃣ .dockerignore

```
# Dependencies
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage
.nyc_output
*.test.js
*.spec.js
tests

# Git
.git
.gitignore
.gitattributes

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

# Environment
.env
.env.local
.env.*.local

# Build artifacts
dist
build
```

---

## 5️⃣ package.json (Example)

```json
{
  "name": "nodejs-express-api",
  "version": "1.0.0",
  "description": "Example Express API with DevX CI/CD",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.js",
    "build": "babel src -d dist",
    "test": "jest --coverage",
    "test:ci": "jest --ci --coverage --maxWorkers=2",
    "lint": "eslint src/**/*.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "@babel/cli": "^7.23.0",
    "@babel/core": "^7.23.0",
    "@babel/preset-env": "^7.23.0",
    "jest": "^29.7.0",
    "nodemon": "^3.0.1",
    "eslint": "^8.52.0",
    "supertest": "^6.3.3"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

---

## 🚀 How to Use This Example

### **Step 1: Copy Files**

```bash
# Copy configuration files
cp examples/nodejs-express/devx-ci.yaml ./
cp examples/nodejs-express/.github/workflows/ci.yaml ./.github/workflows/
cp examples/nodejs-express/Dockerfile ./
cp examples/nodejs-express/.dockerignore ./
```

### **Step 2: Customize**

Edit `devx-ci.yaml`:
- Change `image_name` to your app name
- Update `role_to_assume` with your AWS IAM role
- Adjust security settings if needed

### **Step 3: Commit and Push**

```bash
git add devx-ci.yaml .github/workflows/ci.yaml Dockerfile .dockerignore
git commit -m "Add DevX CI/CD pipeline"
git push
```

### **Step 4: Watch It Run**

Go to **Actions** tab in GitHub to see your pipeline running!

---

## 📊 What Happens When You Push

```
1. Load Configuration
   └─ Validates devx-ci.yaml

2. Security Gates (Parallel)
   ├─ SAST Scan (Semgrep)
   │  └─ Scans src/ for vulnerabilities
   └─ Results → GitHub Security Tab

3. Build & Test
   ├─ npm ci (install dependencies)
   ├─ npm test (run unit tests)
   └─ npm run build (if configured)

4. Docker Build
   ├─ Build multi-stage Dockerfile
   └─ Push to ECR: 123456.dkr.ecr.us-east-1.amazonaws.com/nodejs-express-api:abc1234

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
- Download: `node-build-{sha}` (contains dist/ folder)

### **Test Results**
- Go to **Actions → Workflow run → Artifacts**
- Download: `node-test-results-{sha}` (contains coverage reports)

### **Security Findings**
- Go to **Security → Code scanning alerts**
- Filter by tool: `sast-semgrep`, `trivy-image`, `sbom-grype`

### **Docker Image**
- Image URI: `{account}.dkr.ecr.{region}.amazonaws.com/{image_name}:{git-sha}`
- Image Digest: `sha256:abc123...` (immutable reference)

---

## 🛠️ Customization Options

### **Skip Tests (Not Recommended)**
```yaml
build:
  run_tests: false
```

### **Custom Test Command**
```json
// package.json
{
  "scripts": {
    "test": "jest --coverage --verbose"
  }
}
```

### **Audit Mode (Don't Block on Security)**
```yaml
security:
  sast:
    fail_on_findings: false  # Report only
  trivy:
    fail_on_vuln: false      # Report only
```

### **Add Infrastructure Scanning**
```yaml
security:
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: terraform
```

---

## 🆘 Troubleshooting

**Tests Failing?**
```bash
# Run locally first
npm test
```

**Docker Build Failing?**
```bash
# Test locally
docker build -t test .
```

**Security Findings?**
- Check **Security → Code scanning**
- Review each finding
- Fix or suppress false positives

---

## 📚 Next Steps

1. **Add Branch Protection**
   - Settings → Branches → Add rule
   - Require "CI Pipeline" status check

2. **Add Status Badge**
   ```markdown
   ![CI](https://github.com/your-org/your-repo/workflows/CI%20Pipeline/badge.svg)
   ```

3. **Deploy**
   - Use the image URI from workflow outputs
   - Deploy to ECS, EKS, Lambda, etc.

---

**Questions?** Check [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)