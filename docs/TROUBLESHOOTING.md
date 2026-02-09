# Troubleshooting Guide

Common issues and solutions for DevX Reusable Workflows (CI).

> **Looking for Deployment Issues?**  
> Check out the [CD Troubleshooting Guide](CD_TROUBLESHOOTING.md).

---

## 📋 Table of Contents

- [Configuration Issues](#configuration-issues)
- [Build Failures](#build-failures)
- [Security Scan Issues](#security-scan-issues)
- [Docker Build Issues](#docker-build-issues)
- [AWS/ECR Issues](#awsecr-issues)
- [Performance Issues](#performance-issues)
- [Debugging Tips](#debugging-tips)

---

## 🔧 Configuration Issues

### **Error: "Config file not found"**

**Full Error:**
```
❌ Config file not found: devx-ci.yaml
   Please create a devx-ci.yaml configuration file
```

**Causes:**
1. File doesn't exist
2. File is in wrong location
3. Typo in filename

**Solutions:**

**1. Check if file exists:**
```bash
ls -la devx-ci.yaml
```

**2. Ensure it's in repository root:**
```
your-repo/
├── devx-ci.yaml          # ✅ Correct location
└── .github/
    └── workflows/
        └── ci.yaml
```

**3. Check filename spelling:**
```bash
# Correct
devx-ci.yaml

# Wrong
devx-ci.yml              # Missing 'a'
devx_ci.yaml             # Underscore instead of hyphen
devx-ci-config.yaml      # Extra suffix
```

---

### **Error: "Invalid YAML syntax"**

**Full Error:**
```
❌ Invalid YAML in devx-ci.yaml
```

**Causes:**
- Indentation errors
- Missing colons
- Incorrect spacing

**Solutions:**

**1. Validate YAML syntax:**
```bash
# Online validator
https://www.yamllint.com/

# Command line (if you have yq)
yq '.' devx-ci.yaml
```

**2. Common YAML mistakes:**

❌ **Wrong - Tab indentation:**
```yaml
project:
	language: node  # Tab used instead of spaces
```

✅ **Correct - Space indentation:**
```yaml
project:
  language: node  # 2 spaces
```

❌ **Wrong - Missing colon:**
```yaml
project
  language: node
```

✅ **Correct - Has colon:**
```yaml
project:
  language: node
```

---

### **Error: "Missing required field: project.language"**

**Full Error:**
```
❌ Missing required field: project.language
   Please specify project.language in your config (node, python, or maven)
```

**Solution:**

Add the language field:
```yaml
project:
  language: node  # REQUIRED: Must be node, python, or maven
```

---

### **Error: "Invalid language"**

**Full Error:**
```
❌ Invalid language: nodejs
   Supported languages: node, python, maven
```

**Cause:** Wrong language value

**Solution:**

Use exact values:
```yaml
project:
  language: node      # ✅ Correct
  # NOT: nodejs, javascript, js, ts, typescript
  
  language: python    # ✅ Correct
  # NOT: py, python3
  
  language: maven     # ✅ Correct
  # NOT: java, jvm
```

---

## 🔨 Build Failures

### **Error: "Tests failed"**

**Full Error:**
```
Error: Process completed with exit code 1
```

**Causes:**
1. Unit tests are actually failing
2. Test dependencies missing
3. Test configuration incorrect

**Solutions:**

**1. Run tests locally first:**
```bash
# Node.js
npm test

# Python
python -m pytest

# Maven
mvn test
```

**2. Check test output in Actions:**
- Go to **Actions → Failed run → Build job**
- Expand "Run Unit Tests" step
- Look for specific test failures

**3. Temporarily skip tests (debugging only):**
```yaml
build:
  run_tests: false  # NOT recommended for production
```

**4. Review test results artifact:**
- Go to failed run
- Download `{language}-test-results-{sha}` artifact
- Review test reports

---

### **Error: "npm ci failed"** (Node.js)

**Full Error:**
```
Error: Process completed with exit code 1
npm ERR! Could not resolve dependency
```

**Causes:**
1. `package-lock.json` missing or out of sync
2. Dependency version conflicts
3. Private package access

**Solutions:**

**1. Update package-lock.json:**
```bash
rm -rf node_modules package-lock.json
npm install
git add package-lock.json
git commit -m "Update package-lock.json"
```

**2. Check for private packages:**
If using private npm packages, add `.npmrc` to repo root:
```ini
@yourscope:registry=https://registry.npmjs.org/
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
```

Then add `NPM_TOKEN` to GitHub Secrets.

---

### **Error: "pip install failed"** (Python)

**Full Error:**
```
ERROR: Could not find a version that satisfies the requirement
```

**Causes:**
1. `requirements.txt` has version conflicts
2. Python version mismatch
3. Missing system dependencies

**Solutions:**

**1. Test requirements locally:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**2. Pin Python version:**
```yaml
project:
  language: python
  version: "3.11"  # Match your local version
```

**3. Check for system dependencies:**
Some packages need system libraries. Add to Dockerfile:
```dockerfile
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*
```

---

### **Error: "Maven build failed"** (Java)

**Full Error:**
```
[ERROR] Failed to execute goal
```

**Causes:**
1. Compilation errors
2. Missing dependencies
3. Plugin failures

**Solutions:**

**1. Build locally:**
```bash
mvn clean package
```

**2. Check Java version:**
```yaml
project:
  language: maven
  version: "17"  # Must match pom.xml <java.version>
```

**3. Review pom.xml:**
Ensure all dependencies are available in Maven Central.

---

## 🔐 Security Scan Issues

### **Error: "SAST scan blocked build"**

**Full Error:**
```
Error: Semgrep found security issues
```

**This is WORKING AS DESIGNED** - but here's how to handle it:

**Solutions:**

**1. View findings (Recommended):**
- Go to **Security → Code scanning alerts**
- Filter by `sast-semgrep`
- Review each finding
- Fix the security issues

**2. Temporarily set to audit mode:**
```yaml
security:
  sast:
    enabled: true
    fail_on_findings: false  # Don't block, just report
```

**3. Exclude false positives:**
```yaml
security:
  sast:
    exclude_paths: "tests/,scripts/migrations/"
```

**4. Lower severity threshold:**
```yaml
security:
  sast:
    severity: ERROR  # Only block on ERROR, not WARNING
```

---

### **Error: "Trivy found vulnerabilities"**

**Full Error:**
```
Error: Trivy scan found CRITICAL vulnerabilities
```

**This is WORKING AS DESIGNED** - here's how to handle it:

**Solutions:**

**1. View vulnerabilities:**
- Go to **Security → Code scanning alerts**
- Filter by `trivy-image`
- Review CVEs

**2. Update dependencies:**
```bash
# Node.js
npm update
npm audit fix

# Python
pip list --outdated
pip install --upgrade package-name

# Maven
mvn versions:display-dependency-updates
```

**3. Accept risk temporarily:**
```yaml
security:
  trivy:
    fail_on_vuln: false  # Audit mode
```

**4. Ignore unfixed vulnerabilities:**
```yaml
security:
  trivy:
    enabled: true
    fail_on_vuln: true
    # Trivy already ignores unfixed by default
```

---

### **Error: "IaC scan failed"**

**Full Error:**
```
Checkov found security issues in infrastructure code
```

**Solutions:**

**1. View findings:**
- Go to **Security → Code scanning alerts**
- Filter by `iac-checkov`
- Review infrastructure issues

**2. Skip specific checks:**
```yaml
security:
  iac:
    enabled: true
    skip_check: "CKV_AWS_20,CKV_AWS_21"  # Skip these specific rules
```

**3. Set to soft-fail:**
```yaml
security:
  iac:
    enabled: true
    soft_fail: true  # Report but don't block
```

---

## 🐳 Docker Build Issues

### **Error: "Dockerfile not found"**

**Full Error:**
```
❌ Error: unable to prepare context: unable to evaluate symlinks in Dockerfile path
```

**Solutions:**

**1. Check Dockerfile exists:**
```bash
ls -la Dockerfile
```

**2. Check working directory:**
```yaml
docker:
  working_directory: "."      # If Dockerfile is in root
  # OR
  working_directory: "./app"  # If Dockerfile is in app/ subdirectory
```

**3. Check Dockerfile name:**
```yaml
docker:
  dockerfile: Dockerfile       # Default
  # OR
  dockerfile: Dockerfile.prod  # If using different name
```

---

### **Error: "Docker build failed"**

**Full Error:**
```
ERROR [internal] load build definition from Dockerfile
```

**Causes:**
1. Syntax errors in Dockerfile
2. Base image not found
3. COPY paths incorrect

**Solutions:**

**1. Test Docker build locally:**
```bash
docker build -t test .
```

**2. Check base image exists:**
```dockerfile
FROM node:20-alpine  # ✅ Tag must exist
FROM node:99         # ❌ Invalid tag
```

**3. Verify COPY paths:**
```dockerfile
# Paths are relative to context (working_directory)
COPY package.json ./     # ✅
COPY /absolute/path ./   # ❌ Don't use absolute paths
```

---

### **Error: "image_name is required"**

**Full Error:**
```
❌ ERROR: 'image_name' is required when docker.enabled is true
```

**Solution:**

Add image name:
```yaml
docker:
  enabled: true
  image_name: my-app  # Add this
```

---

### **Error: "registry_url is required"**

**Full Error:**
```
❌ ERROR: 'registry_url' is required when registry_type is 'generic'
```

**Solution:**

Add registry URL for generic registries:
```yaml
docker:
  registry_type: generic
  registry_url: ghcr.io  # Add this
```

For common registries:
- **GHCR:** `ghcr.io`
- **Docker Hub:** `docker.io`
- **Artifactory:** `your-company.jfrog.io`

---

## ☁️ AWS/ECR Issues

### **Error: "role_to_assume is required"**

**Full Error:**
```
❌ ERROR: 'role_to_assume' is required when registry_type is 'ecr'
```

**Solution:**

Add IAM role ARN:
```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

See [AWS IAM Setup](GETTING_STARTED.md#aws-iam-setup-for-ecr) for full instructions.

---

### **Error: "Not authorized to perform: sts:AssumeRoleWithWebIdentity"**

**Full Error:**
```
Error: User: arn:aws:sts::123:assumed-role/... is not authorized to perform: sts:AssumeRoleWithWebIdentity
```

**Causes:**
1. IAM role trust policy incorrect
2. Repository not allowed in trust policy
3. OIDC provider not configured

**Solutions:**

**1. Check trust policy:**

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

**2. Verify OIDC provider exists:**
- Go to **IAM → Identity providers**
- Should see: `token.actions.githubusercontent.com`
- If not, create it:
  - Provider URL: `https://token.actions.githubusercontent.com`
  - Audience: `sts.amazonaws.com`

---

### **Error: "No basic auth credentials"**

**Full Error:**
```
Error: no basic auth credentials
```

**Causes:**
1. Using generic registry without credentials
2. Secrets not configured

**Solutions:**

**1. Add registry credentials:**

Go to **Settings → Secrets → Actions**, add:
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

**2. Ensure secrets are passed:**
```yaml
# In your .github/workflows/ci.yaml
jobs:
  ci:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    secrets: inherit  # ← Make sure this is present
```

---

## 🚀 Performance Issues

### **Issue: "Pipeline takes too long"**

**Typical Times:**
- Simple build: 2-5 minutes
- Build + security + Docker: 8-15 minutes
- Full pipeline with all scans: 15-25 minutes

**Optimization Strategies:**

**1. Check if caching is working:**
- Look for "Cache hit" in logs
- Node.js: Should see "Cache restored from key: node-..."
- Python: Should see "Cache restored from key: python-..."
- Maven: Should see "Cache restored from key: maven-..."

**2. Skip non-critical security scans in dev:**
```yaml
security:
  sbom:
    enabled: false  # Skip SBOM in dev branches
  sbom_scan:
    enabled: false
```

**3. Use branch conditions:**
```yaml
# In .github/workflows/ci.yaml
on:
  push:
    branches: [main]     # Full pipeline on main
  pull_request:           # Lighter pipeline on PRs
```

**4. Reduce Docker build time:**
```yaml
docker:
  platforms: linux/amd64  # Single arch is faster than multi-arch
```

---

### **Issue: "Out of disk space"**

**Full Error:**
```
Error: No space left on device
```

**Causes:**
1. Large Docker images
2. Many dependencies
3. Build artifacts not cleaned

**Solutions:**

**1. Clean Docker image:**
```dockerfile
# Multi-stage build
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production image (much smaller)
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**2. Use .dockerignore:**
```
# .dockerignore
node_modules
.git
.github
*.md
tests
coverage
.env
```

---

## 🔍 Debugging Tips

### **Enable Detailed Logging**

**Option 1: Runner diagnostic logging**

Add these secrets to your repository:
- Name: `ACTIONS_RUNNER_DEBUG`
- Value: `true`

- Name: `ACTIONS_STEP_DEBUG`
- Value: `true`

**Option 2: Add debug steps:**
```yaml
# In your devx-ci.yaml, you can't add steps
# But you can check configuration:

# Print configuration during workflow
# (Already built into orchestrator)
```

---

### **Check Workflow Syntax**

Before committing:
```bash
# Validate workflow file
gh workflow view ci.yaml

# Lint YAML
yamllint .github/workflows/ci.yaml
```

---

### **Test Workflows Manually**

All workflows support manual triggering:

```bash
# Trigger manually with custom inputs
gh workflow run node-build.yaml \
  --ref main \
  -f working_directory="." \
  -f node_version="20" \
  -f run_tests="true"
```

---

### **Compare Working vs Broken Runs**

1. Find a working run
2. Find the broken run
3. Compare:
   - Configuration changes
   - Dependency versions
   - Code changes
   - Infrastructure changes

---

### **Isolate the Problem**

**Test individual modules:**

Create a temporary workflow:
```yaml
# .github/workflows/test-sast.yaml
name: Test SAST Only

on: workflow_dispatch

jobs:
  sast:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/sast-semgrep.yaml@v1
    with:
      scan_path: "."
      fail_on_findings: false
```

---

## 🆘 Still Stuck?

### **Before Asking for Help**

Gather this information:
1. Your `devx-ci.yaml` configuration
2. Workflow run URL
3. Full error message
4. What you've already tried
5. Expected vs actual behavior

### **Get Help**

**Check documentation:**
   - [README.md](../README.md)
   - [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md)
   - [GETTING_STARTED.md](GETTING_STARTED.md)

---

## 📊 Common Error Patterns

| Error Contains | Likely Cause | Quick Fix |
|----------------|--------------|-----------|
| `Config file not found` | Missing devx-ci.yaml | Create file in repo root |
| `Invalid language` | Wrong language value | Use `node`, `python`, or `maven` |
| `Tests failed` | Actual test failures | Fix tests or run locally first |
| `SAST scan blocked` | Security findings (intended) | Review Security tab, fix issues |
| `Dockerfile not found` | Missing/wrong path | Check `docker.working_directory` |
| `role_to_assume required` | ECR without IAM role | Add `aws.role_to_assume` |
| `No basic auth credentials` | Missing registry secrets | Add REGISTRY_USERNAME/PASSWORD |
| `Invalid YAML` | Syntax error in config | Validate with yamllint.com |

---