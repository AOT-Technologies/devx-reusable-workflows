# DevX Reusable Workflows

**Enterprise-Grade CI/CD Workflows for GitHub Actions**

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
  run_build: true             # Enable build step
  artifact_path: "dist/"      # Path to build artifacts

nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"    # npm-hosted | pypi-hosted | maven-releases
  repo_type: "npm"            # npm | pypi | raw
  docker_registry_url: "nexus.example.com:8082"
  docker_repository: "docker-hosted"

security:
  sast:
    enabled: true
    tool: semgrep             # semgrep | sonarqube
    severity: ERROR           # INFO | WARNING | ERROR
    fail_on_findings: true
  
  iac:
    enabled: false            # Enable for infrastructure projects
    frameworks: terraform     # terraform, kubernetes, cloudformation
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
    scanners: vuln,secret,misconfig
  
  sbom:
    enabled: true
    format: cyclonedx-json    # cyclonedx-json | spdx-json
  
  sbom_scan:
    enabled: true
    severity: medium

docker:
  enabled: true
  image_name: my-app
  registry_type: nexus        # nexus | ecr | generic
  dockerfile: Dockerfile
  platforms: linux/amd64

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
✅ Publish artifacts to **Nexus** (NPM, PyPI, Maven)  
✅ Run security scans (SAST, IaC, container scanning)  
✅ Build and push Docker images (optimized with Nexus artifacts)  
✅ Generate SBOMs  
✅ Upload results to GitHub Security tab  

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       PROJECT REPOSITORY                        │
│  .github/workflows/ci.yaml  →  devx-ci.yaml (Configuration)     │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ workflow_call
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              CI ORCHESTRATOR (The Brain)                        │
│  1. Load & Parse devx-ci.yaml                                   │
│  2. Route to correct language build                             │
│  3. Orchestrate security gates                                  │
│  4. Manage build → scan → deploy flow                           │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                     ┌─────────────┴─────────────┐
                     ▼                           ▼
          ┌──────────────────┐        ┌──────────────────┐
          │ SECURITY GATES   │        │ SECURITY GATES   │
          │   (Parallel)     │        │   (Parallel)     │
          ├──────────────────┤        ├──────────────────┤
          │ SAST Scan        │        │ IaC Scan         │
          │ (Semgrep/Sonar)  │        │ (Checkov)        │
          └────────┬─────────┘        └────────┬─────────┘
                   │                           │
                   └─────────────┬─────────────┘
                                 ▼
                   ┌──────────────────────────────┐
                   │   LANGUAGE BUILD (Routed)    │
                   ├──────────────────────────────┤
                   │  node    → node-build.yaml   │
                   │  python  → python-build.yaml │
                   │  maven   → maven-build.yaml  │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │   NEXUS ARTIFACT UPLOAD      │
                   │   (Native NPM/PyPI/Maven)    │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │   DOCKER BUILD               │
                   │   (Downloads from Nexus)     │
                   └──────────────┬───────────────┘
                                  │
                   ┌──────────────┴───────────────┐
                   ▼              ▼               ▼
          ┌────────────┐  ┌────────────┐  ┌────────────┐
          │ Trivy Scan │  │ SBOM Gen   │  │ SBOM Scan  │
          │ (Image)    │  │ (Syft)     │  │ (Grype)    │
          └────────────┘  └────────────┘  └────────────┘
```

**Key Design Principles:**
1. **Config-Driven**: One YAML file controls everything
2. **Fail-Fast**: Security gates run before builds
3. **Parallel Where Possible**: SAST and IaC scans run simultaneously
4. **Language-Agnostic**: Same workflow for Node, Python, Java
5. **Artifact-Centric**: Nexus is the single source of truth for all build artifacts

---

## 📦 Available Workflows

### **Orchestrator**
| Workflow | Purpose |
|----------|---------|
| `ci-orchestrator.yaml` | Main entry point - orchestrates all modules based on `devx-ci.yaml` |

### **Build Modules**
| Workflow | Language | Features |
|----------|----------|----------|
| `node-build.yaml` | Node.js | npm caching, unit tests, **native NPM publish** to Nexus |
| `python-build.yaml` | Python | pip caching, pytest, **native PyPI upload** (twine) to Nexus |
| `maven-build.yaml` | Java | Maven caching, unit tests, **standard Maven deploy** to Nexus |
| `docker-build.yaml` | Universal | **Nexus artifact download**, Multi-registry (ECR/GHCR/Nexus), OIDC support |

### **Security Modules**
| Workflow | Tool | Scans |
|----------|------|-------|
| `sast-semgrep.yaml` | Semgrep | Code vulnerabilities, secrets, best practices (SARIF output) |
| `sast-sonarqube.yaml` | SonarQube | Enterprise code quality, code smells, security (PR decoration) |
| `iac-scan.yaml` | Checkov | Terraform, K8s, CloudFormation, ARM, Serverless misconfigs |
| `trivy-scan.yaml` | Trivy | OS packages, dependencies, secrets, misconfigurations |
| `sbom-generate.yaml` | Syft | Software Bill of Materials generation (CycloneDX/SPDX) |
| `sbom-scan.yaml` | Grype | SBOM-based CVE analysis (report-only, never fails) |

---

## 📋 What This Provides

### **Automated CI/CD Pipeline**
- **Language Support**: Node.js, Python, Java (Maven)
- **Artifact Management**: Native support for **Sonatype Nexus** (NPM, PyPI, Maven, Raw)
- **Security Gates**: Multi-tool SAST (Semgrep or SonarQube), IaC scanning, container scanning
- **Container Building**: **Nexus Docker Registry**, AWS ECR, GHCR, Docker Hub support
- **SBOM Generation**: CycloneDX and SPDX formats with CVE analysis
- **Test Execution**: Unit tests with result capture and coverage reports

### **Enterprise Features**
- **Deterministic Builds**: All actions version-pinned with SHA hashes
- **Security-First**: Block on security findings by default
- **Audit Trail**: SARIF reports automatically uploaded to GitHub Security tab
- **Cost Optimized**: Smart caching, parallel execution, and **direct Nexus-to-Docker** artifact flow
- **Configurable**: Override any default via `devx-ci.yaml`
- **Concurrency Control**: Smart cancellation of in-progress runs on feature branches

### **Developer Experience**
- **Single Config File**: One `devx-ci.yaml` controls everything
- **Automatic Routing**: Detects your language and repository type automatically
- **Parallel Execution**: Security scans run in parallel with each other
- **Clear Feedback**: Detailed error messages and pipeline summaries
- **Manual Dispatch**: Every workflow supports `workflow_dispatch` for testing

---

## 📖 Documentation

- **[Getting Started Guide](GETTING_STARTED.md)** - Complete setup walkthrough
- **[Configuration Reference](CONFIG_REFERENCE.md)** - All `devx-ci.yaml` options
- **[Architecture Guide](ARCHITECTURE.md)** - How everything works
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Examples](../examples/)** - Sample configurations

---

## 🎯 Usage Examples

### **Node.js with Nexus NPM**
```yaml
project:
  language: node
  version: "20"

build:
  run_tests: true
  run_build: true
  build_script: "build"

nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"
  repo_type: "npm"

docker:
  enabled: true
  image_name: my-node-app
  registry_type: nexus
```

### **Python with Nexus PyPI**
```yaml
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

docker:
  enabled: true
  image_name: my-python-app
  registry_type: nexus
```

### **Java Maven with Nexus**
```yaml
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

docker:
  enabled: true
  image_name: my-java-app
  registry_type: nexus
```

### **SonarQube Integration**
```yaml
security:
  sast:
    enabled: true
    tool: sonarqube
    sonar_host_url: "https://sonarqube.example.com"
    sonar_project_key: "my-project"
    fail_on_quality_gate: true
```

**More examples:** See [examples/](../examples/) directory

---

## 🔐 Security Features

### **Security Scanning**
- ✅ **SAST**: Semgrep (free, fast) OR SonarQube (enterprise, comprehensive)
- ✅ **IaC**: Checkov for Terraform, K8s, CloudFormation
- ✅ **Container**: Trivy for OS/package vulnerabilities, secrets, misconfigs
- ✅ **Dependencies**: SBOM-based CVE scanning with Grype
- ✅ **Secrets**: Credential leak detection in code and containers

### **Security Reports**
All scan results automatically upload to **GitHub Security Tab**:
- Navigate to **Security → Code scanning alerts**
- Filter by tool: `sast-semgrep`, `iac-checkov`, `trivy-image`, `sbom-grype`
- Track remediation over time

### **Policy Enforcement**
```yaml
security:
  sast:
    fail_on_findings: true    # Block on SAST issues
  trivy:
    fail_on_vuln: true        # Block on container vulnerabilities
  iac:
    soft_fail: false          # Block on IaC misconfigurations
```

---

## 📊 Pipeline Outputs

### **Build Artifacts**
- Published to **Sonatype Nexus** using native protocols (NPM, PyPI, Maven)
- Also available as GitHub Actions artifacts (retention: 90 days)

### **Test Results**
- Test results and coverage reports uploaded automatically
- Retention: 30 days
- Naming: `{language}-test-results-{sha}`

### **Docker Images**
- Pushed to **Nexus Docker Registry**, ECR, GHCR, or Docker Hub
- Image URI available as output: `${{ needs.docker.outputs.image_uri }}`
- Image digest (immutable): `${{ needs.docker.outputs.image_digest }}`

### **Maven Coordinates**
For Maven builds, the pipeline outputs:
- `group_id`, `artifact_id`, `version` - extracted from pom.xml
- `nexus_path` - full path to artifact in Nexus

---

## 🎓 Best Practices

### **1. Use Native Repositories**
Always use the native repository type for your language:
- **Node.js**: `repo_type: npm` → publishes with `npm publish`
- **Python**: `repo_type: pypi` → publishes with `twine upload`
- **Maven**: Uses standard Maven repository layout automatically

### **2. Pin Workflow Versions**
```yaml
# ✅ Good - Use version tags
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
```

### **3. Enable Security Gates**
In production, always keep `fail_on_findings: true` to ensure no vulnerable code is deployed.

### **4. Use OIDC for AWS (No Static Keys)**
```yaml
aws:
  role_to_assume: arn:aws:iam::123:role/GitHubActionsRole
```

---

## 🐛 Troubleshooting

### **"Config file not found"**
Ensure `devx-ci.yaml` exists in your repository root.

### **"Invalid language"**
Must be exactly `node`, `python`, or `maven` (not `nodejs` or `java`).

### **"twine upload failed"**
Ensure `NEXUS_USERNAME` and `NEXUS_PASSWORD` secrets are set and have publish permissions.

### **"npm publish failed"**
Verify your `package.json` has a unique version and credentials are correct.

### **"Role assumption failed"**
Check your IAM role trust policy allows the GitHub OIDC provider.

**More solutions:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🎉 Acknowledgments

Built with:
- [GitHub Actions](https://github.com/features/actions)
- [Sonatype Nexus](https://www.sonatype.com/products/sonatype-nexus-repository)
- [Semgrep](https://semgrep.dev/) - SAST scanning
- [SonarQube](https://www.sonarqube.org/) - Code quality
- [Trivy](https://trivy.dev/) - Vulnerability scanning
- [Checkov](https://www.checkov.io/) - IaC scanning
- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - SBOM scanning
