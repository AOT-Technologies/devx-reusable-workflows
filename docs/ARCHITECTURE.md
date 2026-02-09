# DevX Reusable Workflows - Architecture Documentation

This document provides a deep technical dive into how the DevX reusable workflows system is architected, how it makes decisions, and how the pieces fit together.

---

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Architecture Diagram](#architecture-diagram)
- [Orchestration Flow](#orchestration-flow)
- [Decision Logic](#decision-logic)
- [Module Design](#module-design)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)

---

## 🏗️ System Overview

The system is designed around a **Hub-and-Spoke** model with two central orchestrators:

1.  **CI Orchestrator (`ci-orchestrator.yaml`)**: The "Brain" of the build process. It accepts a configuration file (`devx-ci.yaml`), parses it, and dynamically routes the workflow to the appropriate language builders and security scanners.
2.  **CD Orchestrator (`cd-orchestrator.yaml`)**: The "Brain" of the deployment process. It manages environment progression, deployment methods (Helm/ECS/EC2), health checks, and rollbacks.

### Key Goals
-   **Abstraction**: Developers write config, not workflows.
-   **Standardization**: Every project follows the same security and build standards.
-   **Security**: Security gates are standard and cannot be easily bypassed.
-   **Modularity**: Each component (build, scan, deploy) is an independent, reusable workflow.

---

## 🖼️ Architecture Diagram

### CI Pipeline Flow

```
                      Start (Push/PR)
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                    CI ORCHESTRATOR                      │
│                (ci-orchestrator.yaml)                   │
└────────────────────────────┬────────────────────────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
  ┌──────────────────┐              ┌──────────────────┐
  │  SECURITY GATES  │              │  LANGUAGE BUILD  │
  │    (Parallel)    │              │                  │
  ├──────────────────┤              ├──────────────────┤
  │ • SAST (Semgrep) │              │ • Node.js        │
  │ • IaC (Checkov)  │              │ • Python         │
  └─────────┬────────┘              │ • Maven          │
            │                       └─────────┬────────┘
            │                                 │
            │                       ┌─────────▼────────┐
            │                       │    NEXUS REPO    │
            │                       │ (Artifact Upload)│
            │                       └─────────┬────────┘
            │                                 │
            └────────────────┬────────────────┘
                             ▼
                    ┌──────────────────┐
                    │   DOCKER BUILD   │
                    │ (Nexus Download) │
                    └────────┬─────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
    ┌──────────────┐                  ┌──────────────┐
    │  TRIVY SCAN  │                  │  SBOM GEN    │
    │ (Container)  │                  │  & SCAN      │
    └──────────────┘                  └──────────────┘
```

### CD Pipeline Flow

```
                     Start (CI Success)
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                    CD ORCHESTRATOR                      │
│                (cd-orchestrator.yaml)                   │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
                ┌───────────────────────────┐
                │     ENVIRONMENT LOOP      │
                │ (Dev -> QA -> Prod etc.)  │
                └────────────┬──────────────┘
                             │
      ┌──────────────────────┼──────────────────────┐
      ▼                      ▼                      ▼
┌────────────┐        ┌────────────┐         ┌────────────┐
│  EKS/K8s   │        │    ECS     │         │    EC2     │
│ (Helm Up)  │        │ (Task Def) │         │ (SSM/SSH)  │
└─────┬──────┘        └──────┬─────┘         └──────┬─────┘
      │                      │                      │
      └──────────────────────┼──────────────────────┘
                             ▼
                    ┌──────────────────┐
                    │   HEALTH CHECK   │
                    │  (HTTP/TCP/K8s)  │
                    └────────┬─────────┘
                             │
               ┌─────────────┴─────────────┐
               ▼                           ▼
          ( ✅ PASS )                 ( ❌ FAIL )
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │   ROLLBACK   │
                                    │ (Automatic)  │
                                    └──────────────┘
```

---

## 🎼 Orchestration Flow

### CI Orchestrator Logic
1.  **Checkout**: Retries checkout transparently.
2.  **Config Loading**: Reads `devx-ci.yaml` using `yq`.
3.  **Validation**: Ensures required fields (`project.language`, `nexus.url`) exist.
4.  **Security Gates**: Runs SAST and IaC scans in parallel *before* the build to fail fast.
5.  **Build Routing**:
    -   If `project.language == 'node'`, calls `node-build.yaml`.
    -   Input: `node_version`, `run_tests`, `build_script`.
    -   Output: `artifact_name`.
6.  **Docker Step**: (Optional) Downloads the artifact from the previous step and builds a container.
7.  **Post-Processing**: Scans the container (Trivy) and generates SBOMs (Syft).

### CD Orchestrator Logic
1.  **Inputs**: Receives `environment` config path and `image_uri`.
2.  **Config Loading**: Reads `devx-config.yaml`.
3.  **Target Selection**: Determines if target is EKS, ECS, EC2, or Generic K8s.
4.  **Deployment**: Calls the specific deployment module.
5.  **Verification**: Calls `health-check.yaml` to hit the endpoint or check K8s status.
6.  **Action**:
    -   If Health Check passes: Send "Success" notification.
    -   If Health Check fails: Trigger `rollback.yaml` and send "Failure" notification.

---

## 🧠 Decision Logic

### Build Caching Strategy
To optimize performance, we use a multi-layer caching strategy:
1.  **Dependency Cache**: `~/.npm`, `~/.m2/repository`, `~/.cache/pip`. Keyed by `lock` files.
2.  **Build Cache**: Non-deterministic build outputs are NOT cached to ensure correctness.
3.  **Docker Layer Cache**: Uses `gha` (GitHub Actions) cache backend for BuildKit.

### Security Gates
-   **Blocking**: If `fail_on_findings: true`, the pipeline stops immediately.
-   **Audit Mode**: If `fail_on_findings: false`, the pipeline continues but uploads a SARIF report.
-   **Trivy**: Ignores "unfixed" vulnerabilities by default to reduce noise.

---

## 📦 Module Design

Each module (e.g., `node-build.yaml`, `deploy-eks.yaml`) adheres to a strict contract:

### Input Contract
-   **Config objects are passed as JSON strings** if complex.
-   **Secrets use `inherit`** to simplify passing credentials.
-   **Strict typing**: All inputs have types defined in `workflow_call`.

### Output Contract
-   **`artifact_name`**: The name of the uploaded artifact (for download by subsequent jobs).
-   **`image_uri`**: The full URI of the built Docker image.
-   **`image_digest`**: The SHA256 digest of the image (immutable).

---

## 🔄 Data Flow

1.  **Source Code** → **Build Module**
2.  **Build Module** → **Nexus** (Artifact Upload)
3.  **Nexus** → **Docker Module** (Artifact Download)
4.  **Docker Module** → **Container Registry** (Push)
5.  **Container Registry** → **CD Orchestrator** (Image URI)
6.  **CD Orchestrator** → **Deployment Module**
7.  **Deployment Module** → **Cluster/Instance**

---

## 🔐 Security Architecture

### 1. OIDC Authentication (AWS)
We do NOT use long-lived AWS Access Keys (`AWS_ACCESS_KEY_ID`). Instead, we use **GitHub OIDC**:
1.  GitHub Actions requests a JWT.
2.  AWS STS validates the JWT against the IAM Identity Provider.
3.  AWS returns a temporary role session.
4.  This role is strictly scoped to the repo and operation needed.

### 2. Supply Chain Security
-   **Pinning**: All 3rd-party actions are pinned to a specific SHA or strict version tag.
-   **SBOM**: Every build generates an SBOM to track dependencies.
-   **Provenance**: We can trace every Docker image back to the exact commit and workflow run that created it.

### 3. Secret Management
-   Secrets are never echoed.
-   Secrets are passed only to jobs that need them.
-   Logs are automatically masked by GitHub Actions runner.