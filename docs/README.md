# DevX Reusable Workflows

**Enterprise-grade CI/CD Workflows for GitHub Actions**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/AOT-Technologies/devx-reusable-workflows/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🏗️ Architecture Overview

The platform consists of two main orchestrators:
1. **CI Orchestrator (`ci-orchestrator.yaml`)**: Handles builds, tests, artifacts, and security scans.
2. **CD Orchestrator (`cd-orchestrator.yaml`)**: Handles deployments, health checks, and rollbacks.

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
                   ┌──────────────┴───────────────┐
                   ▼              ▼               ▼
          ┌────────────┐  ┌────────────┐  ┌────────────┐
          │ Trivy Scan │  │ SBOM Gen   │  │ SBOM Scan  │
          │ (Image)    │  │ (Syft)     │  │ (Grype)    │
          └────────────┘  └────────────┘  └────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              CD ORCHESTRATOR (Deployment)                       │
│  1. Load & Parse devx-config.yaml                               │
│  2. Deploy Image to Target (EKS/ECS/EC2)                        │
│  3. Verify Health & Auto-Rollback                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Workflow Catalog

### **1. Orchestrators**
| Workflow | Purpose |
|----------|---------|
| `ci-orchestrator.yaml` | **The CI Brain**. Parses config, routes builds, runs security gates. |
| `cd-orchestrator.yaml` | **The CD Brain**. Managing deployments to AWS (EKS/ECS/EC2). |

### **2. Build Modules**
| Workflow | Key Features |
|----------|--------------|
| `node-build.yaml` | Node.js setup, caching, **NPM publish** to Nexus. |
| `python-build.yaml` | Python setup, caching, **PyPI upload** to Nexus. |
| `maven-build.yaml` | Java setup, Maven caching, partial builds, **Maven deploy**. |
| `docker-build.yaml` | Multi-registry support (Nexus/ECR/GHCR), optimized caching. |

### **3. Security Modules**
| Workflow | Tool | output |
|----------|------|--------|
| `sast-semgrep.yaml` | Semgrep | SARIF |
| `sast-sonarqube.yaml` | SonarQube | Dashboard + PR Decoration |
| `iac-scan.yaml` | Checkov | SARIF |
| `trivy-scan.yaml` | Trivy | SARIF |
| `sbom-generate.yaml` | Syft | CycloneDX/SPDX JSON |
| `sbom-scan.yaml` | Grype | CVE Report |

### **4. Deployment Modules**
| Workflow | Target | Features |
|----------|--------|----------|
| `deploy-eks.yaml` | EKS (Helm) | Atomic upgrades, namespace management, values injection. |
| `deploy-ecs.yaml` | ECS | Task def registration, service update, stability wait. |
| `deploy-ec2.yaml` | EC2 | SSM Command / SSH. Docker Compose support. |
| `deploy-k8s.yaml` | Generic K8s | Manifest application, kubeconfig secret support. |

### **5. Utilities**
| Workflow | Purpose |
|----------|---------|
| `health-check.yaml` | Verifies deployment health (HTTP/K8s/TCP). |
| `rollback.yaml` | Automated rollback logic for EKS, ECS, EC2. |
| `notify-google-chat.yaml` | Sends rich status cards to Google Chat. |

---

## 📖 Documentation Index

### **Getting Started**
- **[CI Setup Guide](GETTING_STARTED.md)** - Set up your build pipeline.
- **[CD Setup Guide](DEPLOYMENT_GUIDE.md)** - Set up your deployment pipeline.

### **Configuration**
- **[CI Config Reference](CONFIG_REFERENCE.md)** - `devx-ci.yaml` options.
- **[CD Config Reference](CD_CONFIG_REFERENCE.md)** - `devx-config.yaml` options.
- **[AWS OIDC Setup](AWS_OIDC.md)** - Secure AWS authentication.

### **Deep Dives**
- **[Architecture](ARCHITECTURE.md)** - Detailed design and decision flow.
- **[Rollback Procedures](ROLLBACK_PROCEDURES.md)** - How automated and manual rollbacks work.
- **[Troubleshooting CI](TROUBLESHOOTING.md)** - Fix common build issues.
- **[Troubleshooting CD](CD_TROUBLESHOOTING.md)** - Fix common deployment issues.

---

## 🔐 Security Features

1.  **OIDC Authentication**: No long-lived AWS keys.
2.  **Immutable Artifacts**: SHA-pinned actions and artifacts.
3.  **Fail-Fast Gates**: Pipeline stops if vulnerabilities exceed thresholds.
4.  **Least Privilege**: Workflows request minimal necessary permissions.
5.  **Secrets Sanitization**: Logs are automatically masked.

---

## 📄 License
MIT License - See [LICENSE](../LICENSE) for details.
