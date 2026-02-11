# DevX Reusable Workflows

**CI/CD Workflows for GitHub Actions**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/AOT-Technologies/devx-reusable-workflows/releases)

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
│   ├── ci-orchestrator.yaml    # CI Brain (Builds, Tests, Scans)
│   ├── cd-orchestrator.yaml    # CD Brain (Deploys, Health Checks, Rollbacks)
│   ├── node-build.yaml         # Node.js build + NPM publish
│   ├── python-build.yaml       # Python build + PyPI publish
│   ├── maven-build.yaml        # Maven build + deploy
│   ├── docker-build.yaml       # Universal container builder
│   ├── sast-semgrep.yaml       # Static code analysis
│   ├── sast-sonarqube.yaml     # Enterprise code quality
│   ├── iac-scan.yaml           # Infrastructure scanning
│   ├── trivy-scan.yaml         # Container vulnerabilities
│   ├── sbom-generate.yaml      # SBOM generation (Syft)
│   ├── sbom-scan.yaml          # SBOM analysis (Grype)
│   ├── deploy-eks.yaml         # EKS (Helm) deployment
│   ├── deploy-ecs.yaml         # ECS deployment
│   ├── deploy-ec2.yaml         # EC2 deployment (SSM/SSH)
│   ├── deploy-k8s.yaml         # Generic K8s deployment
│   ├── health-check.yaml       # Post-deployment verification
│   ├── rollback.yaml           # Automated rollback logic
│   └── notify-google-chat.yaml # Chat notifications
├── docs/                       # Documentation
├── examples/                   # Template projects
└── README.md
```

---

## 🚀 Quick Start

### 1. Create `devx-ci.yaml` (CI Config) & `devx-config.yaml` (CD Config)

**CI Configuration (`devx-ci.yaml`):**
```yaml
project:
  language: node
nexus:
  url: "https://nexus.example.com"
  repo_type: "npm"
docker:
  enabled: true
  registry_type: nexus
```

**CD Configuration (`devx-config.yaml`):**
```yaml
aws:
  role_to_assume: "arn:aws:iam::123:role/GHA"
deployment:
  enabled: true
  target: "eks"
  environments:
    dev:
      enabled: true
      cluster_name: "dev-cluster"
```

### 2. Create Workflow Files

**CI Pipeline (`.github/workflows/ci.yaml`):**
```yaml
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
with:
  config_path: devx-ci.yaml
secrets: inherit
```

**CD Pipeline (`.github/workflows/cd.yaml`):**
```yaml
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/cd-orchestrator.yaml@v1
with:
  environment: dev
  image_uri: ${{ needs.ci.outputs.image_uri }}
secrets: inherit
```

### 3. Add Secrets

- `NEXUS_USERNAME` / `NEXUS_PASSWORD`
- `GOOGLE_CHAT_WEBHOOK` (Optional)

**That's it!** Push to main to trigger CI, then deploy to Dev.

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [docs/README.md](docs/README.md) | Main documentation hub |
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | CI setup guide |
| [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | **CD / Deployment setup guide** |
| [docs/CONFIG_REFERENCE.md](docs/CONFIG_REFERENCE.md) | CI configuration options |
| [docs/CD_CONFIG_REFERENCE.md](docs/CD_CONFIG_REFERENCE.md) | **CD configuration options** |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical deep dive (CI/CD) |
| [docs/ROLLBACK_PROCEDURES.md](docs/ROLLBACK_PROCEDURES.md) | Rollback strategies |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | CI troubleshooting |
| [docs/CD_TROUBLESHOOTING.md](docs/CD_TROUBLESHOOTING.md) | CD troubleshooting |

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
| **Deployment Targets** | **AWS EKS**, **AWS ECS**, **AWS EC2**, **Generic K8s** |
| **Security Scanning** | Semgrep, SonarQube, Checkov, Trivy, Syft, Grype |

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