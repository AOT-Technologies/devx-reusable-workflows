# DevX Reusable Workflows

**Reusable CI/CD workflows for GitHub Actions**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/AOT-Technologies/devx-reusable-workflows/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🚀 Quick Start

### 1. Create your configuration file

Create `devx-ci.yaml` in your project root:

```yaml
project:
  language: node              # node | python | maven
  version: "20"               # Language version
  working_directory: "."      # Project root

build:
  run_tests: true
  artifact_path: "dist/"      # Optional: path to build artifacts

security:
  sast:
    enabled: true
    severity: ERROR           # INFO | WARNING | ERROR
    fail_on_findings: true
  
  iac:
    enabled: false            # Enable for infrastructure projects
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  sbom:
    enabled: true
    format: cyclonedx-json

docker:
  enabled: true
  image_name: my-app
  registry_type: ecr          # ecr | generic
  dockerfile: Dockerfile

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

### 2. Create your workflow file

Create `.github/workflows/ci.yaml`:

```yaml
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

### 3. Commit and push

```bash
git add devx-ci.yaml .github/workflows/ci.yaml
git commit -m "Add DevX CI pipeline"
git push
```

**That's it!** Your pipeline will now:
✅ Build and test your code  
✅ Run security scans (SAST, IaC, container scanning)  
✅ Build and push Docker images  
✅ Generate SBOMs  
✅ Upload results to GitHub Security tab  

---

## 📋 What This Provides

### **Automated CI/CD Pipeline**
- **Language Support**: Node.js, Python, Java (Maven)
- **Security Gates**: SAST, IaC scanning, vulnerability scanning
- **Container Building**: AWS ECR, GHCR, Docker Hub support
- **SBOM Generation**: CycloneDX and SPDX formats
- **Test Execution**: Unit tests with result capture

### **Enterprise Features**
- **Deterministic Builds**: All actions version-pinned
- **Security-First**: Block on security findings by default
- **Audit Trail**: SARIF reports to GitHub Security tab
- **Cost Optimized**: Smart caching, parallel execution
- **Configurable**: Override any default via `devx-ci.yaml`

### **Developer Experience**
- **Single Config File**: One `devx-ci.yaml` controls everything
- **Automatic Routing**: Detects your language automatically
- **Parallel Execution**: Security scans run in parallel
- **Clear Feedback**: Detailed error messages and summaries

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Your Project (.github/workflows/ci.yaml)                   │
│  Calls: ci-orchestrator.yaml                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  CI ORCHESTRATOR (The Brain)                                │
│  - Reads devx-ci.yaml configuration                         │
│  - Routes to correct language build                         │
│  - Orchestrates security gates                              │
│  - Manages build → scan → deploy flow                       │
└──────┬───────────────────────────────────────┬──────────────┘
       │                                       │
       ▼                                       ▼
┌─────────────────┐                   ┌──────────────────────┐
│ SECURITY GATES  │                   │   BUILD PIPELINE     │
│  (Parallel)     │                   │    (Sequential)      │
├─────────────────┤                   ├──────────────────────┤
│ • SAST Scan     │───────┐           │ 1. Language Build    │
│ • IaC Scan      │       │           │    (Node/Python/     │
└─────────────────┘       │           │     Maven)           │
                          ▼           │                      │
                    ┌─────────────┐   │ 2. Docker Build      │
                    │  BUILD OK?  │   │                      │
                    └──────┬──────┘   │ 3. Trivy Scan        │
                           │          │                      │
                           ▼          │ 4. SBOM Generate     │
                    ┌─────────────┐   │                      │
                    │ Continue to │   │ 5. SBOM Scan         │
                    │   Docker    │   └──────────────────────┘
                    └─────────────┘
```

**Key Design Principles:**
1. **Config-Driven**: One YAML file controls everything
2. **Fail-Fast**: Security gates run before builds
3. **Parallel Where Possible**: SAST and IaC scans run simultaneously
4. **Language-Agnostic**: Same workflow for Node, Python, Java
5. **No Vendor Lock-in**: Works with any registry (ECR, GHCR, Docker Hub)

---

## 📦 Available Workflows

### **Orchestrator**
| Workflow | Purpose | Documentation |
|----------|---------|---------------|
| `ci-orchestrator.yaml` | Main entry point, orchestrates all modules | [Docs](docs/ORCHESTRATOR.md) |

### **Build Modules**
| Workflow | Language | Features |
|----------|----------|----------|
| `node-build.yaml` | Node.js | npm caching, unit tests, artifact upload |
| `python-build.yaml` | Python | pip caching, pytest, artifact upload |
| `maven-build.yaml` | Java | Maven caching, unit tests, JAR/WAR upload |
| `docker-build.yaml` | Universal | Multi-registry, multi-arch, OIDC support |

### **Security Modules**
| Workflow | Tool | Scans |
|----------|------|-------|
| `sast-semgrep.yaml` | Semgrep | Code vulnerabilities, secrets, best practices |
| `iac-scan.yaml` | Checkov | Terraform, K8s, CloudFormation misconfigurations |
| `trivy-scan.yaml` | Trivy | OS packages, dependencies, misconfigurations |
| `sbom-generate.yaml` | Syft | Software Bill of Materials generation |
| `sbom-scan.yaml` | Grype | SBOM-based vulnerability analysis |

---

## 📖 Documentation

- **[Getting Started Guide](docs/GETTING_STARTED.md)** - Complete setup walkthrough
- **[Configuration Reference](docs/CONFIG_REFERENCE.md)** - All `devx-ci.yaml` options
- **[Architecture Guide](docs/ARCHITECTURE.md)** - How everything works
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Migration Guide](docs/MIGRATION.md)** - Moving from legacy CI
- **[Examples](examples/)** - Sample configurations

---

## 🎯 Usage Examples

### **Simple Node.js App**
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
  enabled: false  # No Docker needed
```

### **Python with Docker**
```yaml
# devx-ci.yaml
project:
  language: python
  version: "3.11"

build:
  run_tests: true
  artifact_path: "dist/"

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-python-app
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123:role/GHA
```

### **Java with IaC Scanning**
```yaml
# devx-ci.yaml
project:
  language: maven
  version: "17"

build:
  run_tests: true
  artifact_path: "target/*.jar"

security:
  sast:
    enabled: true
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: terraform
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-java-app
  registry_type: generic
  registry_url: ghcr.io
```

**More examples:** See [examples/](examples/) directory

---

## 🔐 Security Features

### **Security Scanning**
- ✅ **SAST**: Semgrep with OWASP rules
- ✅ **IaC**: Checkov for infrastructure
- ✅ **Container**: Trivy for images
- ✅ **Dependencies**: Vulnerability scanning
- ✅ **Secrets**: Credential leak detection

### **Security Reports**
All scan results automatically upload to **GitHub Security Tab**:
- Navigate to **Security → Code scanning alerts**
- Filter by tool: `sast-semgrep`, `iac-checkov`, `trivy-image`
- Track remediation over time

### **Policy Enforcement**
```yaml
# Block builds on security findings
security:
  sast:
    fail_on_findings: true    # Block on SAST issues
  trivy:
    fail_on_vuln: true        # Block on vulnerabilities
  iac:
    soft_fail: false          # Block on IaC misconfigurations
```

---

## 🛠️ Advanced Configuration

### **Custom Build Commands**
```yaml
build:
  run_tests: true
  test_script: "npm run test:ci"        # Custom test command
  build_script: "npm run build:prod"    # Custom build command
  artifact_path: "dist/"
```

### **Multi-Architecture Docker**
```yaml
docker:
  enabled: true
  platforms: "linux/amd64,linux/arm64"  # Multi-arch builds
  build_args: |
    VERSION=1.0.0
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
```

### **Skip Specific Security Checks**
```yaml
security:
  iac:
    enabled: true
    skip_check: "CKV_AWS_20,CKV_AWS_21"  # Skip specific Checkov rules
```

### **SBOM Customization**
```yaml
security:
  sbom:
    enabled: true
    format: spdx-json              # cyclonedx-json | spdx-json
  sbom_scan:
    enabled: true
    severity: medium               # negligible | low | medium | high | critical
```

---

## 📊 Pipeline Outputs

### **Build Artifacts**
- Build artifacts uploaded to GitHub Actions artifacts
- Retention: 90 days
- Naming: `{language}-build-{sha}`

### **Test Results**
- Test results and coverage reports uploaded
- Retention: 30 days
- Naming: `{language}-test-results-{sha}`

### **Security Reports**
- SARIF files uploaded to GitHub Security tab
- SBOM files stored for 180 days
- Scan reports available as artifacts

### **Docker Images**
- Image URI available as output: `${{ needs.docker.outputs.image_uri }}`
- Image digest (immutable): `${{ needs.docker.outputs.image_digest }}`

---

## 🎓 Best Practices

### **1. Pin Workflow Versions**
```yaml
# ✅ Good - Use version tags
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1

# ⚠️ Risky - Tracks main branch (breaking changes)
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@main
```

### **2. Enable Security Gates**
```yaml
# ✅ Production: Block on security issues
security:
  sast:
    fail_on_findings: true
  trivy:
    fail_on_vuln: true

# ⚠️ Development: Audit mode only
security:
  sast:
    fail_on_findings: false
```

### **3. Use Image Digests for Deployments**
```yaml
# ✅ Immutable reference
image: 123456.dkr.ecr.us-east-1.amazonaws.com/app@sha256:abc123...

# ⚠️ Mutable tag
image: 123456.dkr.ecr.us-east-1.amazonaws.com/app:latest
```

### **4. Review Security Alerts Regularly**
- Check GitHub Security tab weekly
- Set up notifications for new alerts
- Make security checks required status checks

---

## 🐛 Troubleshooting

### **Common Issues**

**"Config file not found"**
```bash
# Ensure devx-ci.yaml exists in repository root
ls -la devx-ci.yaml
```

**"Invalid language"**
```yaml
# Must be: node, python, or maven
project:
  language: node  # ✅ Correct
  language: nodejs  # ❌ Wrong
```

**"Role assumption failed"**
```yaml
# Verify IAM role ARN is correct
aws:
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
  
# Check trust policy allows GitHub OIDC
```

**More solutions:** See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

### **Testing Workflows**
All workflows support `workflow_dispatch` for manual testing:
```bash
gh workflow run node-build.yaml \
  --ref main \
  -f node_version="20" \
  -f run_tests=true
```
---

## 🎉 Acknowledgments

Built with:
- [GitHub Actions](https://github.com/features/actions)
- [Semgrep](https://semgrep.dev/) - SAST scanning
- [Trivy](https://trivy.dev/) - Vulnerability scanning
- [Checkov](https://www.checkov.io/) - IaC scanning
- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - SBOM scanning
