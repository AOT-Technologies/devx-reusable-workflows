# Getting Started with DevX Reusable Workflows

This guide will walk you through setting up the DevX CI/CD pipeline for your project.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ A GitHub repository
- ✅ Code in one of these languages: Node.js, Python, or Java (Maven)
- ✅ (Optional) A Dockerfile if you want container builds
- ✅ (Optional) AWS IAM role configured if using ECR

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

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: false  # Set to true if you need Docker
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

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: false  # Set to true if you need Docker
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

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: false  # Set to true if you need Docker
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

### **Step 4: Commit and Push**

```bash
git add devx-ci.yaml .github/workflows/ci.yaml
git commit -m "Add DevX CI pipeline"
git push
```

### **Step 5: Watch It Run! 🎉**

1. Go to your repository on GitHub
2. Click **Actions** tab
3. You should see your **CI Pipeline** running
4. Click on the run to see detailed logs

---

## 🐳 Adding Docker Support

If you want to build and push Docker images:

### **1. Add Dockerfile**

Create a `Dockerfile` in your project root (if you don't have one):

<details>
<summary><b>Node.js Dockerfile Example</b></summary>

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

</details>

<details>
<summary><b>Python Dockerfile Example</b></summary>

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "app.py"]
```

</details>

<details>
<summary><b>Java Dockerfile Example</b></summary>

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

</details>

### **2. Choose Your Registry**

#### **Option A: AWS ECR (Recommended)**

**Prerequisites:**
- AWS account
- IAM role for GitHub Actions with ECR permissions

**Update devx-ci.yaml:**
```yaml
docker:
  enabled: true
  image_name: my-app
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

**Setup IAM Role:**
See [AWS IAM Setup Guide](#aws-iam-setup-for-ecr) below.

#### **Option B: GitHub Container Registry (GHCR)**

**Update devx-ci.yaml:**
```yaml
docker:
  enabled: true
  image_name: your-org/my-app
  registry_type: generic
  registry_url: ghcr.io
```

**Add Repository Secret:**
1. Go to repository **Settings → Secrets and variables → Actions**
2. Add secrets:
   - `REGISTRY_USERNAME`: Your GitHub username
   - `REGISTRY_PASSWORD`: GitHub Personal Access Token with `write:packages` scope

#### **Option C: Docker Hub**

**Update devx-ci.yaml:**
```yaml
docker:
  enabled: true
  image_name: your-dockerhub-username/my-app
  registry_type: generic
  registry_url: docker.io
```

**Add Repository Secrets:**
1. Go to repository **Settings → Secrets → Actions**
2. Add secrets:
   - `REGISTRY_USERNAME`: Docker Hub username
   - `REGISTRY_PASSWORD`: Docker Hub access token

### **3. Commit and Push**

```bash
git add Dockerfile devx-ci.yaml
git commit -m "Add Docker support"
git push
```

Your pipeline will now build and push Docker images! 🐳

---

## 🏗️ Project Structure

After setup, your repository should look like this:

```
your-project/
├── .github/
│   └── workflows/
│       └── ci.yaml              # ✅ Workflow that calls DevX
├── devx-ci.yaml                 # ✅ Your configuration
├── Dockerfile                   # ✅ If using Docker
├── package.json                 # For Node.js
├── requirements.txt             # For Python
├── pom.xml                      # For Maven
└── src/                         # Your source code
```

---

## 📊 Understanding Your Pipeline

When you push code, this happens:

```
1. Load Configuration
   └─ Reads devx-ci.yaml
   └─ Validates settings
   └─ Routes to correct language

2. Security Gates (Parallel)
   ├─ SAST Scan (Semgrep)
   │  └─ Scans your code for vulnerabilities
   └─ IaC Scan (Checkov) [if enabled]
      └─ Scans Terraform/K8s files

3. Build & Test
   ├─ Install dependencies
   ├─ Run unit tests
   └─ Build application

4. Docker Build [if enabled]
   ├─ Build container image
   └─ Push to registry (ECR/GHCR/Docker Hub)

5. Container Security
   ├─ Trivy Scan
   │  └─ Scan image for vulnerabilities
   ├─ SBOM Generation
   │  └─ Create software bill of materials
   └─ SBOM Scan
      └─ Check SBOM for known CVEs

6. Pipeline Summary
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

### **Workflow Logs**

Detailed logs are available in the **Actions** tab:

1. Click **Actions** tab
2. Click on a workflow run
3. Expand any job to see detailed logs

---

## 🎓 Common Customizations

### **1. Exclude Test Files from SAST**

```yaml
security:
  sast:
    enabled: true
    exclude_paths: "tests/,**/*test.js,**/*.spec.ts"
```

### **2. Add Build Artifacts**

```yaml
build:
  run_tests: true
  artifact_path: "dist/"  # Upload dist/ folder
```

### **3. Scan Infrastructure Code**

```yaml
security:
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: terraform
```

### **4. Customize Test Command**

**Node.js:**
```yaml
# devx-ci.yaml stays the same

# Modify your package.json:
{
  "scripts": {
    "test": "jest --coverage",
    "build": "webpack --mode production"
  }
}
```

**Python:**
```yaml
build:
  run_tests: true
  # Default: python -m pytest
  # Customize in your project with pytest.ini
```

**Maven:**
```yaml
build:
  run_tests: true
  # Default: mvn test -B
  # Customize in your pom.xml
```

### **5. Multi-Architecture Docker Builds**

```yaml
docker:
  enabled: true
  image_name: my-app
  platforms: linux/amd64,linux/arm64
```

### **6. Docker Build Arguments**

```yaml
docker:
  enabled: true
  image_name: my-app
  build_args: |
    VERSION=1.0.0
    ENVIRONMENT=production
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
```

---

## 🐛 Common Issues

### **Issue: "Config file not found"**

**Cause:** `devx-ci.yaml` is not in repository root

**Fix:**
```bash
# Ensure file exists
ls -la devx-ci.yaml

# If not, create it
touch devx-ci.yaml
# Add configuration...
```

### **Issue: "Invalid language: nodejs"**

**Cause:** Wrong language value

**Fix:** Must be exactly `node`, `python`, or `maven`:
```yaml
project:
  language: node  # ✅ Correct
  # NOT: nodejs, javascript, js
```

### **Issue: "Tests failed"**

**Cause:** Unit tests are failing

**Options:**

1. **Fix the tests** (recommended)
2. **Temporarily skip tests** (not recommended):
   ```yaml
   build:
     run_tests: false
   ```

### **Issue: "SAST findings block build"**

**Cause:** Security vulnerabilities found

**Options:**

1. **Fix the vulnerabilities** (recommended)
2. **Set to audit mode temporarily**:
   ```yaml
   security:
     sast:
       enabled: true
       fail_on_findings: false  # Don't block builds
   ```

3. **View findings:**
   - Go to **Security → Code scanning**
   - Review and fix each finding

### **Issue: "Docker build failed - role_to_assume required"**

**Cause:** Using ECR without IAM role

**Fix:** Add IAM role:
```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

See [AWS IAM Setup](#aws-iam-setup-for-ecr) below.

---

## ☁️ AWS IAM Setup for ECR

### **1. Create IAM Policy**

Create a policy with ECR permissions:

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
5. Add the policy you created above
6. Name: `GitHubActionsRole`

### **3. Update Trust Policy**

Edit the role's trust relationship:

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

Replace:
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_ORG/YOUR_REPO` with your GitHub repository

### **4. Copy Role ARN**

Copy the role ARN (looks like: `arn:aws:iam::123456789012:role/GitHubActionsRole`)

### **5. Update devx-ci.yaml**

```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole  # Paste here
```

---

## 📚 Next Steps

Now that your pipeline is running:

1. **Review Security Findings**
   - Go to **Security → Code scanning**
   - Address any findings

2. **Add Status Badge**
   ```markdown
   ![CI Pipeline](https://github.com/your-org/your-repo/workflows/CI%20Pipeline/badge.svg)
   ```

3. **Make Security Checks Required**
   - Go to **Settings → Branches**
   - Add branch protection rule
   - Require **CI Pipeline** status check

4. **Explore Advanced Features**
   - See [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md) for all options
   - Check [examples/](../examples/) for more configurations

5. **Set Up Continuous Deployment**
   - Add deployment jobs after CI passes
   - Deploy to your environment

---

## 🆘 Getting Help

**Stuck?**

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md)
3. Look at [examples/](../examples/) directory

**Documentation:**
- [README.md](../README.md) - Overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
- [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md) - All configuration options
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

---

## ✅ Checklist

Before considering yourself "done":

- [ ] `devx-ci.yaml` created and committed
- [ ] `.github/workflows/ci.yaml` created and committed
- [ ] Pipeline runs successfully on push
- [ ] Tests pass
- [ ] Security scans pass (or findings addressed)
- [ ] Docker image builds (if enabled)
- [ ] Security tab shows scan results
---