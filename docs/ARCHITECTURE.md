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
- [Caching Strategy](#caching-strategy)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)

---

## 🏗️ System Overview

### **Core Principles**

1. **Config-Driven:** Single YAML file (`devx-ci.yaml`) controls entire pipeline
2. **Modular:** Each workflow does one thing well, composable like LEGO blocks
3. **Language-Agnostic:** Same orchestrator works for Node, Python, Java
4. **Security-First:** Multiple security gates with fail-fast behavior
5. **Deterministic:** Version-pinned actions, reproducible builds
6. **Artifact-Centric:** Nexus is the source of truth for all build outputs

### **Repository Structure**

```
devx-reusable-workflows/
├── .github/workflows/          # All reusable workflows
│   ├── ci-orchestrator.yaml    # The Brain (orchestrates everything)
│   ├── node-build.yaml         # Language-specific builds
│   ├── python-build.yaml
│   ├── maven-build.yaml
│   ├── docker-build.yaml       # Universal container builder
│   ├── sast-semgrep.yaml       # Security modules
│   ├── sast-sonarqube.yaml
│   ├── iac-scan.yaml
│   ├── trivy-scan.yaml
│   ├── sbom-generate.yaml
│   └── sbom-scan.yaml
├── docs/                        # Documentation
├── examples/                    # Template projects
└── README.md
```

---

## 🎯 Architecture Diagram

### **High-Level Flow**

```
┌────────────────────────────────────────────────────────────────┐
│                       PROJECT REPOSITORY                       │
│                                                                │
│  ┌──────────────────────┐      ┌─────────────────────────┐     │
│  │ .github/workflows/   │      │    devx-ci.yaml         │     │
│  │   ci.yaml            │────> │  (Configuration)        │     │
│  │                      │      │                         │     │
│  │ Triggers on:         │      │  project:               │     │
│  │  - push              │      │    language: node       │     │
│  │  - pull_request      │      │  security:              │     │
│  │                      │      │    sast: enabled        │     │
│  │ Calls reusable       │      │  docker:                │     │
│  │ workflow ──────────┐ │      │    enabled: true        │     │
│  └────────────────────┼─┘      └─────────────────────────┘     │
│                       │                                        │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        │ workflow_call
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│              REUSABLE WORKFLOWS REPOSITORY                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              CI ORCHESTRATOR (The Brain)                 │   │
│  │                                                          │   │
│  │  1. Load & Parse devx-ci.yaml                            │   │
│  │  2. Extract language & SAST tool                         │   │
│  │  3. Route to correct workflows based on config           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
│              ┌───────────────┼───────────────┐                  │
│              ▼               ▼               ▼                  │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ │
│  │ SAST-Semgrep     │ │ SAST-SonarQube   │ │ IaC-Checkov      │ │
│  │ (if tool=semgrep)│ │ (if tool=sonar)  │ │ (if iac.enabled) │ │
│  └────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘ │
│           │                    │                    │           │
│           └────────────────────┴────────────────────┘           │
│                                │                                │
│                                ▼                                │
│                 ┌──────────────────────────────┐                │
│                 │   LANGUAGE BUILD (Routed)    │                │
│                 ├──────────────────────────────┤                │
│                 │  if language == 'node'       │                │
│                 │    → node-build.yaml         │                │
│                 │  if language == 'python'     │                │
│                 │    → python-build.yaml       │                │
│                 │  if language == 'maven'      │                │
│                 │    → maven-build.yaml        │                │
│                 └──────────────┬───────────────┘                │
│                                │                                │
│                                ▼                                │
│              ┌──────────────────────────────┐                   │
│              │   DOCKER BUILD (Conditional) │                   │
│              ├──────────────────────────────┤                   │
│              │  if docker.enabled == true   │                   │
│              │    → docker-build.yaml       │                   │
│              │       - Downloads from Nexus │                   │
│              │       - Builds & pushes      │                   │
│              └──────────────┬───────────────┘                   │
│                             │                                   │
│                             ▼                                   │
│              ┌──────────────────────────────┐                   │
│              │   POST-BUILD SECURITY        │                   │
│              │   (Sequential Chain)         │                   │
│              ├──────────────────────────────┤                   │
│              │ 1. trivy-scan.yaml           │                   │
│              │ 2. sbom-generate.yaml        │                   │
│              │ 3. sbom-scan.yaml            │                   │
│              └──────────────────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Orchestration Flow

### **Phase 1: Configuration Loading**

```yaml
load-config:
  runs-on: ubuntu-latest
  outputs:
    config: ${{ steps.parse.outputs.config }}
    language: ${{ steps.extract.outputs.language }}
    sast_tool: ${{ steps.extract.outputs.sast_tool }}
    artifact_name: ${{ steps.extract.outputs.artifact_name }}
```

**What Happens:**
1. Checks if `devx-ci.yaml` exists
2. Validates YAML syntax with `yq`
3. Validates required fields (`project.language`)
4. Validates language value (must be `node`, `python`, or `maven`)
5. Detects SAST tool (semgrep or sonarqube)
6. Determines artifact naming based on language
7. Outputs config as JSON for downstream jobs

**Critical Validations:**
```bash
# Config exists?
if [[ ! -f "${{ inputs.config_path }}" ]]; then
  exit 1
fi

# Valid YAML?
yq '.' ${{ inputs.config_path }} > /dev/null

# Language specified?
LANGUAGE=$(yq '.project.language' ${{ inputs.config_path }})
if [[ "$LANGUAGE" == "null" ]]; then
  exit 1
fi

# Valid language?
if [[ ! "$LANGUAGE" =~ ^(node|python|maven)$ ]]; then
  exit 1
fi
```

---

### **Phase 2: Security Gates (Parallel Execution)**

The orchestrator supports two SAST tools that are mutually exclusive:

```yaml
sast-semgrep:
  needs: load-config
  if: |
    fromJson(needs.load-config.outputs.config).security.sast.enabled == true &&
    needs.load-config.outputs.sast_tool == 'semgrep'

sast-sonarqube:
  needs: load-config
  if: |
    fromJson(needs.load-config.outputs.config).security.sast.enabled == true &&
    needs.load-config.outputs.sast_tool == 'sonarqube'
```

**Execution Strategy:**
- SAST (Semgrep OR SonarQube) and IaC run **simultaneously** (parallel)
- Only ONE SAST tool runs based on config
- Results evaluated before proceeding to build

**Decision Matrix:**

| SAST Result | IaC Result | Build Proceeds? |
|-------------|------------|-----------------|
| success     | success    | ✅ Yes          |
| success     | skipped    | ✅ Yes          |
| skipped     | success    | ✅ Yes          |
| skipped     | skipped    | ✅ Yes          |
| failure     | *          | ❌ No           |
| *           | failure    | ❌ No           |

---

### **Phase 3: Language Build (Conditional Routing)**

```yaml
build-node:
  needs: [load-config, sast-semgrep, sast-sonarqube, iac]
  if: |
    always() &&
    needs.load-config.result == 'success' &&
    (needs.sast-semgrep.result == 'success' || needs.sast-semgrep.result == 'skipped') &&
    (needs.sast-sonarqube.result == 'success' || needs.sast-sonarqube.result == 'skipped') &&
    (needs.iac.result == 'success' || needs.iac.result == 'skipped') &&
    !contains(needs.*.result, 'failure') &&
    !contains(needs.*.result, 'cancelled') &&
    needs.load-config.outputs.language == 'node'
```

**Routing Logic:**

```
IF language == 'node'
  THEN execute node-build.yaml → uploads to Nexus NPM
ELSE IF language == 'python'
  THEN execute python-build.yaml → uploads to Nexus PyPI
ELSE IF language == 'maven'
  THEN execute maven-build.yaml → uploads to Nexus Maven
```

**Why This Pattern:**
- Only ONE build job runs (not all three)
- Uses GitHub Actions native conditional execution
- No wasted runner minutes
- Each build uploads directly to Nexus using native protocols

---

### **Phase 4: Docker Build (With Artifact Download)**

```yaml
docker:
  needs: [load-config, build-node, build-python, build-maven]
  with:
    # Nexus Artifact Download (Optimization)
    nexus_artifact_base_url: ${{ config.nexus.url }}
    nexus_artifact_repo: ${{ config.nexus.repository }}
    nexus_artifact_path: ${{ needs.build-maven.outputs.nexus_path || needs.build-node.outputs.nexus_path || needs.build-python.outputs.nexus_path }}
```

**Optimized Flow:**
1. Receives `nexus_path` from build job
2. Downloads artifact directly from Nexus using curl
3. Passes artifact filename via `ARTIFACT_NAME` build arg
4. Dockerfile uses `ARG ARTIFACT_NAME` to receive the file
5. No GitHub Artifacts transfer needed!

**Registry Decision Tree:**

```
IF registry_type == 'nexus'
  THEN
    1. Login to Nexus Docker registry
    2. Build with artifact from Nexus
    3. Push to Nexus
ELSE IF registry_type == 'ecr'
  THEN
    1. Configure AWS OIDC credentials
    2. Login to ECR
    3. Build and push
ELSE IF registry_type == 'generic'
  THEN
    1. Login to GHCR/DockerHub
    2. Build and push
```

---

### **Phase 5: Post-Build Security (Sequential)**

```yaml
trivy:
  needs: [load-config, docker]
  if: |
    needs.docker.result == 'success' &&
    config.security.trivy.enabled == true

sbom:
  needs: [load-config, docker, trivy]
  if: |
    needs.docker.result == 'success' &&
    (needs.trivy.result == 'success' || needs.trivy.result == 'skipped')

sbom-scan:
  needs: [load-config, sbom]
  if: |
    needs.sbom.result == 'success'
```

**Execution Order:**
```
1. Trivy Scan
   └─ Scans Docker image for vulnerabilities
   └─ CAN FAIL the pipeline (if fail_on_vuln=true)

2. SBOM Generation (waits for Trivy)
   └─ Creates software bill of materials
   └─ Never fails

3. SBOM Scan (waits for SBOM)
   └─ Scans SBOM for CVEs
   └─ Never fails (report only)
```

---

## 🧩 Module Design

### **Build Modules**

All build modules follow the same pattern:

1. **Setup** - Install language runtime with native caching
2. **Install** - Install dependencies
3. **Test** - Run unit tests (if enabled)
4. **Build** - Create artifact (JAR, wheel, tarball)
5. **Upload** - Publish to Nexus using native protocol

**Key Outputs:**
- `nexus_path` - Path to artifact in Nexus (for Docker to download)
- `artifact_file` - Filename of the artifact

### **node-build.yaml**

```yaml
# Supports two repository types:
nexus_repo_type: "npm"   # Uses npm publish
nexus_repo_type: "raw"   # Uses curl PUT
```

### **python-build.yaml**

```yaml
# Supports two repository types:
nexus_repo_type: "pypi"  # Uses twine upload
nexus_repo_type: "raw"   # Uses curl PUT
```

### **maven-build.yaml**

```yaml
# Always uses Maven repository layout:
# [groupId]/[artifactId]/[version]/[artifactId]-[version].jar
```

---

### **Docker Build Module**

The `docker-build.yaml` supports three registry types:

1. **ECR** - AWS OIDC authentication (no static keys)
2. **Generic** - Username/password (GHCR, Docker Hub)
3. **Nexus** - Nexus Docker registry

**Key Feature: Direct Artifact Download**

```yaml
- name: Download Artifact from Nexus
  if: inputs.nexus_artifact_path != ''
  run: |
    ARTIFACT_NAME=$(basename "$ARTIFACT_PATH")
    curl -f -u "$NEXUS_USER:$NEXUS_PASS" \
      -o "./$ARTIFACT_NAME" \
      "$BASE_URL/repository/$REPO/$ARTIFACT_PATH"
```

This bypasses GitHub Artifacts entirely, making Docker builds faster and more reliable.

---

### **Security Modules**

#### **sast-semgrep.yaml**
- **Tool:** Semgrep (free, fast)
- **Mode:** Local-only (no cloud dependency)
- **Output:** SARIF → GitHub Security tab
- **Configurable:** Severity threshold, exclusions, rulesets

#### **sast-sonarqube.yaml**
- **Tool:** SonarQube (enterprise, comprehensive)
- **Features:** PR decoration, quality gates, technical debt
- **Output:** SonarQube dashboard + PR comments

#### **iac-scan.yaml**
- **Tool:** Checkov
- **Targets:** Terraform, K8s, CloudFormation, ARM, Serverless
- **Mode:** Graph-based analysis
- **Output:** SARIF → GitHub Security tab

#### **trivy-scan.yaml**
- **Tool:** Trivy
- **Modes:** Filesystem OR Image
- **Scans:** Vulnerabilities, secrets, misconfigurations
- **Registry Auth:** ECR (OIDC), Generic, Nexus

#### **sbom-generate.yaml**
- **Tool:** Syft
- **Formats:** CycloneDX, SPDX
- **Purpose:** Create inventory (non-blocking)

#### **sbom-scan.yaml**
- **Tool:** Grype
- **Input:** SBOM from previous job
- **Mode:** Always report-only (never fails)

---

## 📊 Data Flow

### **Configuration Flow**

```
devx-ci.yaml (YAML)
        ↓
    yq parse
        ↓
    JSON string (stored in output)
        ↓
fromJson() in downstream jobs
        ↓
Access nested properties
```

### **Artifact Flow (Optimized)**

```
Build Job
    ↓
Upload to Nexus (native protocol)
    ↓
Output: nexus_path
    ↓
Docker Build Job
    ↓
Download from Nexus (curl)
    ↓
Build image with artifact
    ↓
Push to registry
```

### **SARIF Flow**

```
Security Scan Job
    ↓
Generate SARIF file
    ↓
github/codeql-action/upload-sarif
    ↓
GitHub Security Tab
    ↓
Code Scanning Alerts UI
```

---

## 🔐 Security Architecture

### **Defense in Depth**

```
Layer 1: Pre-Build
    ├─ SAST (Semgrep/SonarQube)
    └─ IaC (Checkov)

Layer 2: Build
    ├─ Dependency resolution
    ├─ Unit tests
    └─ Artifact validation

Layer 3: Container
    ├─ Trivy scan
    ├─ SBOM generation
    └─ SBOM CVE scan
```

### **Credential Management**

**AWS ECR (No Stored Credentials):**
```yaml
# Uses OIDC federation - no AWS keys in GitHub
role-to-assume: arn:aws:iam::123:role/GHA
```

**Nexus (Encrypted Secrets):**
```yaml
# Stored in GitHub Secrets (encrypted at rest)
# Never logged, automatically masked
secrets:
  NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
  NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
```

### **Permissions Model**

```yaml
permissions:
  contents: read          # Read code
  security-events: write  # Upload SARIF
  actions: write          # Upload artifacts
  id-token: write         # OIDC token (ECR)
  packages: write         # GHCR push
  pull-requests: write    # SonarQube PR decoration
```

---

## 💾 Caching Strategy

### **Language Caching**

```yaml
# Node.js
- uses: actions/setup-node@v4
  with:
    cache: npm
    cache-dependency-path: package-lock.json

# Python
- uses: actions/setup-python@v5
  with:
    cache: pip
    cache-dependency-path: requirements.txt

# Maven
- uses: actions/setup-java@v4
  with:
    cache: maven
    cache-dependency-path: pom.xml
```

### **Docker Layer Caching**

```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## ⚡ Performance Optimization

### **Parallel Execution**

Security gates run simultaneously:
```
Sequential: SAST (5min) + IaC (3min) = 8min
Parallel:   max(SAST, IaC) = 5min
Savings:    37.5%
```

### **Conditional Execution**

Jobs skip entirely if disabled in config:
```yaml
if: fromJson(needs.load-config.outputs.config).docker.enabled == true
```

### **Direct Nexus Downloads**

Docker builds download from Nexus instead of GitHub Artifacts:
- Faster (Nexus is typically on same network)
- More reliable (dedicated artifact storage)
- Lower GitHub Actions billing

### **Concurrency Control**

```yaml
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

Prevents multiple runs on same branch, but protects main branch.

---

## ⚠️ Error Handling

### **Fail-Fast Validation**

All inputs validated before execution:
```yaml
if [[ -z "$ROLE_ARN" ]]; then
  echo "::error::role_to_assume is required for ECR"
  exit 1
fi
```

### **Timeout Protection**

```yaml
jobs:
  build:
    timeout-minutes: 30  # Job level

  steps:
    - name: Run Tests
      timeout-minutes: 15  # Step level
```

### **Always Blocks**

```yaml
- name: Upload Test Results
  if: always() && inputs.run_tests == true
```

Ensures artifacts are captured even on failure.

### **Report-Only Mode**

For SBOM scan:
```yaml
continue-on-error: true  # Never fails the pipeline
```