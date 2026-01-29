# DevX Reusable Workflows

**Enterprise-Grade CI/CD Workflows for GitHub Actions**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/AOT-Technologies/devx-reusable-workflows/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A centralized collection of reusable GitHub Actions workflows for standardized, secure CI/CD across AOT projects.

---

## ✨ Features

- 🚀 **One Config, Full Pipeline** - Single `devx-ci.yaml` controls everything
- 🔐 **Multi-Layer Security** - SAST, IaC, container scanning, SBOM generation
- 📦 **Native Nexus Integration** - NPM, PyPI, Maven, and Docker registries
- 🐳 **Multi-Registry Docker** - Nexus, AWS ECR, GHCR, Docker Hub
- 🔄 **Language Agnostic** - Node.js, Python, Java (Maven)
- ⚡ **Optimized Builds** - Direct Nexus artifact downloads, parallel security scans

---

## 🗂️ Repository Structure

```
devx-reusable-workflows/
├── .github/workflows/          # All reusable workflows
│   ├── ci-orchestrator.yaml    # The Brain (orchestrates everything)
│   ├── node-build.yaml         # Node.js build + NPM publish
│   ├── python-build.yaml       # Python build + PyPI publish
│   ├── maven-build.yaml        # Maven build + deploy
│   ├── docker-build.yaml       # Universal container builder
│   ├── sast-semgrep.yaml       # Static code analysis
│   ├── sast-sonarqube.yaml     # Enterprise code quality
│   ├── iac-scan.yaml           # Infrastructure scanning
│   ├── trivy-scan.yaml         # Container vulnerabilities
│   ├── sbom-generate.yaml      # Software bill of materials
│   └── sbom-scan.yaml          # SBOM vulnerability scan
├── docs/                       # Documentation
├── examples/                   # Template projects
└── README.md
```

---

## 🚀 Quick Start

### 1. Create `devx-ci.yaml` in your project:

```yaml
project:
  language: node              # node | python | maven

nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"
  repo_type: "npm"

docker:
  enabled: true
  image_name: my-app
  registry_type: nexus
```

### 2. Create `.github/workflows/ci.yaml`:

```yaml
name: CI Pipeline
on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
    with:
      config_path: devx-ci.yaml
    secrets: inherit
```

### 3. Add secrets to your repository:
- `NEXUS_USERNAME`
- `NEXUS_PASSWORD`

**That's it!** Push and watch your pipeline run.

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [docs/README.md](docs/README.md) | Main documentation - Overview, architecture, features |
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | Complete setup guide for all languages |
| [docs/CONFIG_REFERENCE.md](docs/CONFIG_REFERENCE.md) | All configuration options |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical deep dive |
| [docs/AWS_OIDC.md](docs/AWS_OIDC.md) | AWS ECR setup with OIDC |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |

---

## 📦 Examples

| Example | Description |
|---------|-------------|
| [examples/nodejs-express/](examples/nodejs-express/) | Node.js Express API with Docker |
| [examples/python-fastapi/](examples/python-fastapi/) | Python FastAPI with PyPI |
| [examples/java-springboot/](examples/java-springboot/) | Java Spring Boot with Maven |
| [examples/docker-only/](examples/docker-only/) | Docker-only builds (skip language build) |

---

## ⚙️ Supported Technologies

| Category | Options |
|----------|---------|
| **Languages** | Node.js, Python, Java (Maven) |
| **Artifact Repos** | Nexus (NPM, PyPI, Maven, Raw) |
| **Container Registries** | Nexus Docker, AWS ECR, GHCR, Docker Hub |
| **SAST Tools** | Semgrep, SonarQube |
| **IaC Scanning** | Checkov (Terraform, K8s, CloudFormation) |
| **Container Scanning** | Trivy |
| **SBOM** | Syft (CycloneDX, SPDX), Grype |

---

## 🔐 Security

All security scan results automatically upload to **GitHub Security → Code scanning alerts**:
- `sast-semgrep` - Source code vulnerabilities
- `iac-checkov` - Infrastructure misconfigurations  
- `trivy-image` - Container vulnerabilities
- `sbom-grype` - Dependency CVEs

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.