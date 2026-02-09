# Getting Started with DevX Reusable Workflows

This guide provides a complete walkthrough for setting up the **CI (Build)** pipeline.

> **Looking for Deployment (CD)?**  
> Check out the [Deployment Guide](DEPLOYMENT_GUIDE.md) to set up EKS, ECS, or EC2 deployments.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ A GitHub repository with your application code
- ✅ Code in one of these languages: **Node.js**, **Python**, or **Java (Maven)**
- ✅ (Optional) A **Dockerfile** if you want container builds
- ✅ (Optional) **Nexus Credentials** stored as GitHub Secrets:
  - `NEXUS_USERNAME`
  - `NEXUS_PASSWORD`
- ✅ (Optional) **AWS IAM role** configured if using ECR

---

## 🚀 Quick Setup

### **Step 1: Create Configuration File**

Create a file named `devx-ci.yaml` in your repository root:

```bash
cd your-project
touch devx-ci.yaml
```

### **Step 2: Add Basic Configuration**

Choose your language and add the appropriate configuration:

<details>
<summary><b>Node.js Project</b></summary>

```yaml
# devx-ci.yaml
project:
  language: node
  version: "20"

build:
  run_tests: true
  run_build: true
  build_script: "build"       # Runs `npm run build`
  artifact_path: "dist/"      # Optional: upload build output

nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"
  repo_type: "npm"

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: true               # Set to false if no container needed
  image_name: my-node-app
  registry_type: nexus
```

</details>

<details>
<summary><b>Python Project</b></summary>

```yaml
# devx-ci.yaml
project:
  language: python
  version: "3.11"

build:
  run_tests: true
  build_command: "pip install wheel && python setup.py bdist_wheel"
  artifact_path: "dist/*.whl"

nexus:
  url: "https://nexus.example.com"
  repository: "pypi-hosted"
  repo_type: "pypi"

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-python-app
  registry_type: nexus
```

</details>

<details>
<summary><b>Java (Maven) Project</b></summary>

```yaml
# devx-ci.yaml
project:
  language: maven
  version: "17"

build:
  run_tests: true
  maven_args: "-B clean package -DskipTests"
  artifact_path: "target/*.jar"

nexus:
  url: "https://nexus.example.com"
  repository: "maven-releases"

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-java-app
  registry_type: nexus
```

</details>

### **Step 3: Create Workflow File**

Create `.github/workflows/ci.yaml`:

```bash
mkdir -p .github/workflows
```

```yaml
# .github/workflows/ci.yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    with:
      config_path: devx-ci.yaml
    secrets: inherit
```

### **Step 4: Add GitHub Secrets**

Go to your repository **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|--------|-------------|
| `NEXUS_USERNAME` | Nexus service account username |
| `NEXUS_PASSWORD` | Nexus service account password |

### **Step 5: Commit and Push**

```bash
git add devx-ci.yaml .github/workflows/ci.yaml
git commit -m "Add DevX CI pipeline"
git push
```

### **Step 6: Watch It Run! 🎉**

1. Go to your repository on GitHub
2. Click **Actions** tab
3. You should see your **CI Pipeline** running
4. Click on the run to see detailed logs

---

## 🐳 Adding Docker Support

If you want to build and push Docker images:

### **1. Create Dockerfile**

Your Dockerfile should accept the artifact as a build argument:

**For Python:**
```dockerfile
FROM python:3.11-alpine
WORKDIR /app

# The artifact is downloaded by the CI pipeline
ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} ./
RUN pip install --no-cache-dir ${ARTIFACT_NAME}

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

**For Node.js:**
```dockerfile
FROM node:20-alpine
WORKDIR /app

ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} ./
RUN tar -xzf ${ARTIFACT_NAME} --strip-components=1

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**For Java:**
```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

ARG ARTIFACT_NAME
COPY ${ARTIFACT_NAME} app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### **2. Choose Your Registry**

#### **Option A: Nexus Docker Registry (Recommended)**

```yaml
docker:
  enabled: true
  image_name: my-app
  registry_type: nexus

nexus:
  docker_registry_url: "nexus.example.com:8082"
  docker_repository: "docker-hosted"
```

#### **Option B: AWS ECR**

```yaml
docker:
  enabled: true
  image_name: my-app
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

See [AWS IAM Setup](#aws-iam-setup-for-ecr) below.

#### **Option C: GitHub Container Registry (GHCR)**

```yaml
docker:
  enabled: true
  image_name: your-org/my-app
  registry_type: generic
  registry_url: ghcr.io
```

Add secrets:
- `REGISTRY_USERNAME`: Your GitHub username
- `REGISTRY_PASSWORD`: GitHub PAT with `write:packages` scope

---

## 🔐 Security Configuration

### **SAST (Code Scanning)**

Choose between Semgrep (free, fast) or SonarQube (enterprise):

**Semgrep (Default):**
```yaml
security:
  sast:
    enabled: true
    tool: semgrep
    severity: ERROR
    fail_on_findings: true
    exclude_paths: "tests/,node_modules/"
```

**SonarQube:**
```yaml
security:
  sast:
    enabled: true
    tool: sonarqube
    sonar_host_url: "https://sonarqube.example.com"
    sonar_project_key: "my-project"
    fail_on_quality_gate: true
```

Required secret: `SONAR_TOKEN`

### **IaC Scanning (Terraform/K8s)**

```yaml
security:
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: terraform,kubernetes
    soft_fail: false           # Set to true for audit mode
```

### **Container Scanning**

```yaml
security:
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
    ignore_unfixed: true       # Skip vulns with no fix
    scanners: vuln,secret,misconfig
```

---

## 📊 Understanding Your Pipeline

When you push code, this happens:

```
1. LOAD CONFIGURATION
   └─ Reads devx-ci.yaml
   └─ Validates settings
   └─ Extracts language for routing

2. SECURITY GATES (Parallel)
   ├─ SAST Scan (Semgrep/SonarQube)
   │  └─ Scans your code for vulnerabilities
   └─ IaC Scan (Checkov) [if enabled]
      └─ Scans Terraform/K8s files

3. BUILD & TEST
   ├─ Install dependencies
   ├─ Run unit tests
   ├─ Build application
   └─ Upload to Nexus (NPM/PyPI/Maven)

4. DOCKER BUILD [if enabled]
   ├─ Download artifact from Nexus
   ├─ Build container image
   └─ Push to registry (Nexus/ECR/GHCR)

5. POST-BUILD SECURITY (Sequential)
   ├─ Trivy Scan
   │  └─ Scan image for vulnerabilities
   ├─ SBOM Generation
   │  └─ Create software bill of materials
   └─ SBOM Scan
      └─ Check SBOM for known CVEs

6. PIPELINE SUMMARY
   └─ Report overall status
```

---

## 🔐 Viewing Security Results

### **GitHub Security Tab**

All security scan results automatically appear in the **Security** tab:

1. Go to your repository
2. Click **Security** tab
3. Click **Code scanning alerts**
4. Filter by tool:
   - `sast-semgrep` - Source code issues
   - `iac-checkov` - Infrastructure issues
   - `trivy-image` - Container vulnerabilities
   - `sbom-grype` - SBOM-based vulnerabilities

---

## ☁️ AWS IAM Setup for ECR

### **1. Create IAM Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

### **2. Create IAM Role**

1. Go to **IAM → Roles → Create Role**
2. Select **Web identity**
3. **Identity provider:** `token.actions.githubusercontent.com`
4. **Audience:** `sts.amazonaws.com`
5. Add the policy above
6. Name: `GitHubActionsRole`

### **3. Update Trust Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

### **4. Update devx-ci.yaml**

```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

## 🐛 Common Issues

### **Issue: "Config file not found"**

**Cause:** `devx-ci.yaml` is not in repository root

**Fix:** Ensure file exists at repository root:
```bash
ls -la devx-ci.yaml
```

### **Issue: "Invalid language: nodejs"**

**Cause:** Wrong language value

**Fix:** Must be exactly `node`, `python`, or `maven`:
```yaml
project:
  language: node  # ✅ Correct (NOT nodejs, javascript, js)
```

### **Issue: "Tests failed"**

**Options:**
1. **Fix the tests** (recommended)
2. **Temporarily skip tests:**
   ```yaml
   build:
     run_tests: false
   ```

### **Issue: "SAST findings block build"**

**Options:**
1. **Fix the vulnerabilities** (recommended)
2. **Set to audit mode:**
   ```yaml
   security:
     sast:
       fail_on_findings: false
   ```

### **Issue: "twine upload failed"**

**Causes:**
- Wrong `repo_type` (use `pypi` for Python wheels)
- Invalid Nexus credentials
- Version already exists in Nexus

**Fix:**
```yaml
nexus:
  repo_type: "pypi"  # Not "raw"
```

---

## ✅ Setup Checklist

Before considering yourself "done":

- [ ] `devx-ci.yaml` created and committed
- [ ] `.github/workflows/ci.yaml` created and committed
- [ ] `NEXUS_USERNAME` and `NEXUS_PASSWORD` secrets added
- [ ] Pipeline runs successfully on push
- [ ] Tests pass
- [ ] Security scans pass (or findings addressed)
- [ ] Docker image builds (if enabled)
- [ ] Security tab shows scan results

---

## 📚 Next Steps

1. **Review Security Findings** - Go to Security → Code scanning
2. **Add Status Badge**
   ```markdown
   ![CI Pipeline](https://github.com/your-org/your-repo/workflows/CI%20Pipeline/badge.svg)
   ```
3. **Make Security Checks Required** - Settings → Branches → Branch protection
4. **Set up Deployment** - Follow the [Deployment Guide](DEPLOYMENT_GUIDE.md) to deploy your application.
5. **Explore Advanced Features** - See [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md)