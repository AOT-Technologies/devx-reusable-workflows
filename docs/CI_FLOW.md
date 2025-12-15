# DevX Reusable Workflows - CI Flow Documentation

This document explains the architecture, available modules, and how to use the DevX reusable workflow system.

---

## 📋 **Table of Contents**

- [Architecture Overview](#architecture-overview)
- [Available Modules](#available-modules)
- [CI Flow Stages](#ci-flow-stages)
- [Usage Examples](#usage-examples)
- [Module Reference](#module-reference)

---

## 🏗️ **Architecture Overview**

The DevX reusable workflow system follows a **modular, composable architecture**:

```
┌─────────────────────────────────────────────────┐
│   Project Repository (.github/workflows/ci.yml) │
│                                                 │
│   Calls reusable workflows from:                │
│   AOT-Technologies/devx-reusable-workflows      │
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│       DevX Reusable Workflows Repository        │
│                                                 │
│  ┌────────────────┐  ┌────────────────┐        │
│  │ Build Modules  │  │  Scan Modules  │        │
│  ├────────────────┤  ├────────────────┤        │
│  │ node-build     │  │ trivy-scan     │        │
│  │ python-build   │  │ sast-scan      │        │
│  │ maven-build    │  │ iac-scan       │        │
│  │ docker-build   │  │ sbom-gen       │        │
│  └────────────────┘  └────────────────┘        │
│                                                 │
│  ┌────────────────────────────────────┐        │
│  │       Common Utilities              │        │
│  ├────────────────────────────────────┤        │
│  │ common-cache-setup                  │        │
│  └────────────────────────────────────┘        │
└─────────────────────────────────────────────────┘
```

**Key Principles:**
- **Modular**: Each workflow does one thing well
- **Reusable**: Called from any project repository
- **Version-pinned**: All actions pinned for deterministic builds
- **Secure by default**: Security scans enabled, blocks on findings
- **Configurable**: Flexible inputs for different use cases

---

## 📦 **Available Modules**

### **Build Modules**

| Module | Purpose | Languages |
|--------|---------|-----------|
| [`node-build.yaml`](#node-build) | Build & test Node.js apps | JavaScript, TypeScript |
| [`python-build.yaml`](#python-build) | Build & test Python apps | Python 3.x |
| [`maven-build.yaml`](#maven-build) | Build & test Java apps | Java (Maven) |
| [`docker-build.yaml`](#docker-build) | Build & push container images | Universal (ECR, GHCR, Docker Hub) |

### **Security Scan Modules**

| Module | Purpose | Targets |
|--------|---------|---------|
| [`trivy-scan.yaml`](#trivy-scan) | Vulnerability scanning | Filesystems & Container Images |
| [`sast-scan.yaml`](#sast-scan) | Static Application Security Testing | Source code (Semgrep) |
| [`iac-scan.yaml`](#iac-scan) | Infrastructure as Code scanning | Terraform, K8s, CloudFormation, etc. |
| [`sbom-gen.yaml`](#sbom-gen) | Software Bill of Materials | Source code & Container Images |

### **Common Utilities**

| Module | Purpose |
|--------|---------|
| [`common-cache-setup.yaml`](#common-cache) | Dependency caching for Node, Python, Maven |

---

## 🔄 **CI Flow Stages**

A typical CI pipeline using DevX modules follows these stages:

```
1. Code Checkout
      ↓
2. Cache Dependencies (common-cache-setup)
      ↓
3. Build & Unit Test (node/python/maven-build)
      ↓
4. Security Scans
   ├─ SAST Scan (sast-scan)
   ├─ Filesystem Scan (trivy-scan)
   └─ IaC Scan (iac-scan) [if applicable]
      ↓
5. Docker Build (docker-build) [if needed]
      ↓
6. Image Security Scan (trivy-scan)
      ↓
7. SBOM Generation (sbom-gen)
      ↓
8. Deploy [handled by project-specific workflow]
```

---

## 🚀 **Usage Examples**

### **Example 1: Simple Node.js CI**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  build-and-test:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/node-build.yaml@main
    with:
      working_directory: .
      node_version: "20"
      run_tests: true
```

### **Example 2: Node.js with Docker and Security Scans**

```yaml
name: Full CI Pipeline

on:
  push:
    branches: [main]

jobs:
  # Step 1: Build and test
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/node-build.yaml@main
    with:
      working_directory: .
      run_tests: true
      artifact_path: "dist/"

  # Step 2: SAST scan
  sast:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/sast-scan.yaml@main
    with:
      scan_path: ./src
      exclude_paths: "node_modules/,dist/,tests/"
      fail_on_findings: true

  # Step 3: Build Docker image
  docker:
    needs: [build, sast]
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/docker-build.yaml@main
    with:
      image_name: my-app
      registry_type: ecr
      role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
      aws_region: us-east-1
    secrets: inherit

  # Step 4: Scan container image
  trivy:
    needs: docker
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/trivy-scan.yaml@main
    with:
      scan_type: image
      image_uri: ${{ needs.docker.outputs.image_uri }}
      fail_on_vuln: true
```

### **Example 3: Python with IaC Scanning**

```yaml
name: Python + Terraform CI

on: [push, pull_request]

jobs:
  # Build Python application
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/python-build.yaml@main
    with:
      python_version: "3.11"
      run_tests: true

  # Scan Terraform infrastructure
  iac-scan:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/iac-scan.yaml@main
    with:
      working_directory: ./infrastructure
      frameworks: terraform
      soft_fail: false  # Block on security issues
```

---

## 📚 **Module Reference**

### **node-build**

Build and test Node.js applications with caching and optional artifact upload.

**Location:** `.github/workflows/node-build.yaml`

**Inputs:**
- `working_directory` (string, default: `.`) - Directory containing package.json
- `node_version` (string, default: `20`) - Node.js version
- `run_tests` (boolean, default: `true`) - Run unit tests before build
- `test_script` (string, default: `npm test`) - Test command
- `build_script` (string, default: `npm run build`) - Build command
- `artifact_path` (string, default: `""`) - Path to upload as artifact

**Outputs:**
- `artifact_name` - Name of uploaded artifact (empty if no upload)

**Example:**
```yaml
jobs:
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/node-build.yaml@main
    with:
      node_version: "18"
      run_tests: true
      artifact_path: "dist/"
```

---

### **python-build**

Build and test Python applications with pip caching.

**Location:** `.github/workflows/python-build.yaml`

**Inputs:**
- `working_directory` (string, default: `.`) - Directory containing requirements.txt
- `python_version` (string, default: `3.11`) - Python version
- `install_command` (string, default: `pip install -r requirements.txt`) - Install command
- `run_tests` (boolean, default: `true`) - Run unit tests
- `test_script` (string, default: `python -m pytest`) - Test command
- `build_command` (string, default: `""`) - Optional build/package command
- `artifact_path` (string, default: `""`) - Path to upload as artifact

**Outputs:**
- `artifact_name` - Name of uploaded artifact

**Example:**
```yaml
jobs:
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/python-build.yaml@main
    with:
      python_version: "3.11"
      test_script: "pytest tests/ -v"
      build_command: "python -m build"
      artifact_path: "dist/"
```

---

### **maven-build**

Build and test Java applications using Maven.

**Location:** `.github/workflows/maven-build.yaml`

**Inputs:**
- `working_directory` (string, default: `.`) - Directory containing pom.xml
- `java_version` (string, default: `8`) - Java version
- `distribution` (string, default: `temurin`) - JDK distribution
- `run_tests` (boolean, default: `true`) - Run unit tests
- `test_script` (string, default: `mvn test -B`) - Test command
- `maven_args` (string) - Maven packaging arguments (tests skipped by default)
- `artifact_path` (string, default: `""`) - Path to JAR/WAR file

**Outputs:**
- `artifact_name` - Name of uploaded artifact

**Example:**
```yaml
jobs:
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/maven-build.yaml@main
    with:
      java_version: "17"
      artifact_path: "target/*.jar"
```

---

### **docker-build**

Universal Docker build supporting AWS ECR (OIDC) and generic registries.

**Location:** `.github/workflows/docker-build.yaml`

**Inputs:**
- `working_directory` (string, default: `.`) - Directory containing Dockerfile
- `dockerfile` (string, default: `Dockerfile`) - Dockerfile name
- `image_name` (string, **required**) - Image name
- `image_tag` (string, default: git SHA) - Image tag
- `registry_type` (string, default: `ecr`) - Registry type: `ecr` or `generic`
- `registry_url` (string) - Registry URL (for generic mode)
- `aws_region` (string, default: `us-east-1`) - AWS region (for ECR)
- `role_to_assume` (string) - IAM role ARN (for ECR)
- `build_args` (string) - Build arguments (KEY=VALUE format)
- `platforms` (string, default: `linux/amd64`) - Target platforms

**Secrets:**
- `registry_username` - Username (generic mode only)
- `registry_password` - Password/token (generic mode only)

**Outputs:**
- `image_uri` - Full URI of pushed image

**Example (ECR):**
```yaml
jobs:
  docker:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/docker-build.yaml@main
    with:
      image_name: my-app
      registry_type: ecr
      role_to_assume: arn:aws:iam::123456789012:role/GHARole
      build_args: |
        VERSION=1.0.0
        BUILD_DATE=${{ github.event.head_commit.timestamp }}
```

**Example (GHCR):**
```yaml
jobs:
  docker:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/docker-build.yaml@main
    with:
      image_name: my-org/my-app
      registry_type: generic
      registry_url: ghcr.io
    secrets:
      registry_username: ${{ github.actor }}
      registry_password: ${{ secrets.GITHUB_TOKEN }}
```

---

### **trivy-scan**

Universal security scanning for filesystems and container images.

**Location:** `.github/workflows/trivy-scan.yaml`

**Inputs:**
- `scan_type` (string, default: `image`) - Scan target: `fs` or `image`
- `scan_path` (string, default: `.`) - Path to scan (fs mode)
- `image_uri` (string) - Image URI (image mode)
- `severity_threshold` (string, default: `CRITICAL,HIGH`) - Severities to report
- `fail_on_vuln` (boolean, default: `true`) - Block pipeline on vulnerabilities
- `ignore_unfixed` (boolean, default: `true`) - Ignore unfixable CVEs
- `scanners` (string, default: `vuln,secret,misconfig,config,license`) - Scanner types
- `output_format` (string, default: `sarif`) - Output format

**Example (Filesystem):**
```yaml
jobs:
  scan-code:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/trivy-scan.yaml@main
    with:
      scan_type: fs
      scan_path: .
      fail_on_vuln: true
```

**Example (Container Image):**
```yaml
jobs:
  scan-image:
    needs: docker-build
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/trivy-scan.yaml@main
    with:
      scan_type: image
      image_uri: ${{ needs.docker-build.outputs.image_uri }}
      severity_threshold: "CRITICAL,HIGH,MEDIUM"
```

---

### **sast-scan**

Static Application Security Testing using Semgrep (local-only mode).

**Location:** `.github/workflows/sast-scan.yaml`

**Inputs:**
- `scan_path` (string, default: `.`) - Path to source code
- `exclude_paths` (string) - Paths to exclude (e.g., `tests/,vendor/`)
- `ruleset` (string, default: `p/ci`) - Semgrep ruleset: `p/ci`, `p/default`, `p/owasp-top-ten`
- `severity_threshold` (string, default: `ERROR`) - Minimum severity: `INFO`, `WARNING`, `ERROR`
- `fail_on_findings` (boolean, default: `true`) - Block on security findings
- `upload_sarif` (boolean, default: `true`) - Upload to GitHub Security tab

**Example:**
```yaml
jobs:
  sast:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/sast-scan.yaml@main
    with:
      scan_path: ./src
      exclude_paths: "node_modules/,tests/,migrations/"
      ruleset: p/owasp-top-ten
      fail_on_findings: true
```

---

### **iac-scan**

Infrastructure as Code security scanning using Checkov.

**Location:** `.github/workflows/iac-scan.yaml`

**Inputs:**
- `working_directory` (string, default: `.`) - Root directory to scan
- `quiet_output` (boolean, default: `true`) - Suppress detailed console output
- `soft_fail` (boolean, default: `false`) - Audit mode (don't block pipeline)
- `skip_check` (string) - Comma-separated Checkov IDs to skip
- `frameworks` (string) - Frameworks to scan (auto-detect if empty)
- `upload_sarif` (boolean, default: `true`) - Upload to GitHub Security

**Supported Frameworks:**
- Terraform
- CloudFormation
- Kubernetes
- Helm
- ARM
- Serverless

**Example:**
```yaml
jobs:
  iac-scan:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/iac-scan.yaml@main
    with:
      working_directory: ./terraform
      frameworks: terraform
      soft_fail: false  # Block on security issues
      skip_check: "CKV_AWS_20,CKV_AWS_21"  # Skip specific checks
```

---

### **sbom-gen**

Generate Software Bill of Materials using Syft.

**Location:** `.github/workflows/sbom-gen.yaml`

**Inputs:**
- `image` (string) - Container image to scan
- `path` (string, default: `.`) - Filesystem path to scan
- `format` (string, default: `cyclonedx-json`) - SBOM format

**Outputs:**
- `sbom_path` - Path to generated SBOM file

**Example:**
```yaml
jobs:
  sbom:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/sbom-gen.yaml@main
    with:
      image: ghcr.io/my-org/my-app:latest
      format: cyclonedx-json
```

---

### **common-cache-setup**

Unified dependency caching for Node.js, Python, and Maven.

**Location:** `.github/workflows/common-cache-setup.yaml`

**Inputs:**
- `language` (string, **required**) - Language: `node`, `python`, or `maven`
- `working_directory` (string, default: `.`) - Project directory

**Outputs:**
- `node_cache_hit` - Whether Node cache was hit
- `python_cache_hit` - Whether Python cache was hit
- `maven_cache_hit` - Whether Maven cache was hit

**Example:**
```yaml
jobs:
  cache:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/common-cache-setup.yaml@main
    with:
      language: node
      working_directory: ./app
```

---

## 🔐 **Security Best Practices**

1. **Pin Workflow Versions**: Use `@main` or `@v1` tags
2. **Review SARIF Reports**: Check GitHub Security tab regularly
3. **Enable Required Scans**: Make security scans required status checks
4. **Use Secrets Properly**: Never commit credentials, use GitHub Secrets
5. **Monitor Dependencies**: Enable Dependabot for automated updates

---

## 📞 **Support**

For issues or questions:
- Open an issue in the `devx-reusable-workflows` repository
- Contact the DevOps team
- See examples in `/examples` directory

---

**Last Updated:** 2025-12-15
