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

### **Repository Structure**

```
devx-reusable-workflows/
├── .github/workflows/           # All reusable workflows
│   ├── ci-orchestrator.yaml    # The Brain (orchestrates everything)
│   ├── node-build.yaml         # Language-specific builds
│   ├── python-build.yaml
│   ├── maven-build.yaml
│   ├── docker-build.yaml       # Universal container builder
│   ├── sast-semgrep.yaml          # Security modules
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
┌─────────────────────────────────────────────────────────────────┐
│                       PROJECT REPOSITORY                        │
│                                                                 │
│  ┌──────────────────────┐      ┌─────────────────────────┐      │
│  │ .github/workflows/   │      │    devx-ci.yaml         │      │
│  │   ci.yaml            │────▶ │  (Configuration)        │      │
│  │                      │      │                         │      │
│  │ Triggers on:         │      │  project:               │      │
│  │  - push              │      │    language: node       │      │
│  │  - pull_request      │      │  security:              │      │
│  │                      │      │    sast: enabled        │      │
│  │ Calls reusable       │      │  docker:                │      │
│  │ workflow ──────────┐ │      │    enabled: true        │      │
│  └────────────────────┼─┘      └─────────────────────────┘      │
│                       │                                         │
└───────────────────────┼─────────────────────────────────────────┘
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
│  │  2. Extract language & routing info                      │   │
│  │  3. Route to correct workflows based on config           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                    ┌─────────┴─────────┐                        │
│                    ▼                   ▼                        │
│         ┌──────────────────┐  ┌──────────────────┐              │
│         │ SECURITY GATES   │  │ SECURITY GATES   │              │
│         │   (Parallel)     │  │   (Parallel)     │              │
│         ├──────────────────┤  ├──────────────────┤              │
│         │ sast-scan.yaml   │  │ iac-scan.yaml    │              │
│         │ (Semgrep)        │  │ (Checkov)        │              │
│         └────────┬─────────┘  └────────┬─────────┘              │
│                  │                     │                        │
│                  └──────────┬──────────┘                        │
│                             ▼                                   │
│                    ┌─────────────────┐                          │
│                    │   Gates Pass?   │                          │
│                    └────────┬────────┘                          │
│                             │ yes                               │
│                             ▼                                   │
│              ┌──────────────────────────────┐                   │
│              │   LANGUAGE BUILD (Routed)    │                   │
│              ├──────────────────────────────┤                   │
│              │  if language == 'node'       │                   │
│              │    → node-build.yaml         │                   │
│              │  if language == 'python'     │                   │
│              │    → python-build.yaml       │                   │
│              │  if language == 'maven'      │                   │
│              │    → maven-build.yaml        │                   │
│              └──────────────┬───────────────┘                   │
│                             │                                   │
│                             ▼                                   │
│              ┌──────────────────────────────┐                   │
│              │   DOCKER BUILD (Conditional) │                   │
│              ├──────────────────────────────┤                   │
│              │  if docker.enabled == true   │                   │
│              │    → docker-build.yaml       │                   │
│              │       - ECR (OIDC)           │                   │
│              │       - GHCR/DockerHub       │                   │
│              └──────────────┬───────────────┘                   │
│                             │                                   │
│                             ▼                                   │
│              ┌──────────────────────────────┐                   │
│              │   POST-BUILD SECURITY        │                   │
│              │   (Sequential)               │                   │
│              ├──────────────────────────────┤                   │
│              │ 1. trivy-scan.yaml           │                   │
│              │    (Container vuln scan)     │                   │
│              │ 2. sbom-generate.yaml        │                   │
│              │    (Create SBOM)             │                   │
│              │ 3. sbom-scan.yaml            │                   │
│              │    (SBOM vuln analysis)      │                   │
│              └──────────────────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Orchestration Flow

### **Phase 1: Configuration Loading**

```yaml
jobs:
  load-config:
    runs-on: ubuntu-latest
    outputs:
      config: ${{ steps.parse.outputs.config }}
      language: ${{ steps.extract.outputs.language }}
```

**What Happens:**
1. Checks if `devx-ci.yaml` exists
2. Validates YAML syntax with `yq`
3. Validates required fields (`project.language`)
4. Validates language value (must be `node`, `python`, or `maven`)
5. Parses entire config to JSON
6. Extracts language for routing
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

```yaml
sast:
  needs: load-config
  if: fromJson(needs.load-config.outputs.config).security.sast.enabled == true

iac:
  needs: load-config
  if: fromJson(needs.load-config.outputs.config).security.iac.enabled == true
```

**Execution Strategy:**
- Both gates start **simultaneously** (parallel)
- Independent of each other
- Each can be enabled/disabled independently
- Results evaluated before proceeding to build

**Decision Matrix:**

| SAST Result | IaC Result | Build Proceeds? |
|-------------|------------|-----------------|
| success | success | ✅ Yes |
| success | skipped | ✅ Yes |
| skipped | success | ✅ Yes |
| skipped | skipped | ✅ Yes |
| failure | * | ❌ No |
| * | failure | ❌ No |

---

### **Phase 3: Language Build (Conditional Routing)**

```yaml
build-node:
  needs: [load-config, sast, iac]
  if: |
    always() &&
    needs.load-config.result == 'success' &&
    (needs.sast.result == 'success' || needs.sast.result == 'skipped') &&
    (needs.iac.result == 'success' || needs.iac.result == 'skipped') &&
    !contains(needs.*.result, 'failure') &&
    !contains(needs.*.result, 'cancelled') &&
    needs.load-config.outputs.language == 'node'
```

**Routing Logic:**

```
IF language == 'node'
  THEN execute node-build.yaml
ELSE IF language == 'python'
  THEN execute python-build.yaml
ELSE IF language == 'maven'
  THEN execute maven-build.yaml
ELSE
  FAIL (invalid language)
```

**Why This Pattern:**
- Only ONE build job runs (not all three)
- Uses GitHub Actions native conditional execution
- No wasted runner minutes
- Deterministic routing based on config

**Important:** The condition `always()` ensures the job evaluates even if previous jobs were skipped, but the rest of the conditions prevent execution on failures.

---

### **Phase 4: Docker Build (Conditional)**

```yaml
docker:
  needs: [load-config, build-node, build-python, build-maven]
  if: |
    always() && 
    fromJson(needs.load-config.outputs.config).docker.enabled == true &&
    !contains(needs.*.result, 'failure') && 
    !contains(needs.*.result, 'cancelled')
```

**Execution Logic:**
1. Waits for ALL build jobs to complete (only one actually runs)
2. Checks if Docker is enabled in config
3. Checks that no failures occurred upstream
4. Routes to appropriate registry:
   - `registry_type: ecr` → AWS ECR with OIDC
   - `registry_type: generic` → GHCR/Docker Hub with credentials

**Registry Decision Tree:**

```
IF registry_type == 'ecr'
  THEN
    1. Validate role_to_assume exists
    2. Configure AWS credentials via OIDC
    3. Login to ECR
    4. Build and push
ELSE IF registry_type == 'generic'
  THEN
    1. Validate registry_url exists
    2. Validate credentials exist
    3. Login to generic registry
    4. Build and push
ELSE
  FAIL (invalid registry_type)
```

---

### **Phase 5: Post-Build Security (Sequential)**

```yaml
trivy:
  needs: [load-config, docker]
  if: |
    always() &&
    fromJson(needs.load-config.outputs.config).security.trivy.enabled == true &&
    needs.docker.result == 'success'

sbom:
  needs: [load-config, docker]
  if: |
    always() &&
    fromJson(needs.load-config.outputs.config).security.sbom.enabled == true &&
    needs.docker.result == 'success'

sbom-scan:
  needs: [load-config, sbom]
  if: |
    always() &&
    fromJson(needs.load-config.outputs.config).security.sbom_scan.enabled == true &&
    needs.sbom.result == 'success'
```

**Execution Order:**
```
1. Trivy Scan (parallel with SBOM generation)
   └─ Scans Docker image directly

2. SBOM Generation (parallel with Trivy)
   └─ Creates software bill of materials

3. SBOM Scan (waits for SBOM)
   └─ Scans SBOM for vulnerabilities
```

**Why This Order:**
- Trivy and SBOM can run in parallel (independent)
- SBOM Scan MUST wait for SBOM to be generated
- All are optional (can be disabled independently)

---

## 🧠 Decision Logic

### **Security Gate Bypass Prevention**

**Problem:** If security gates are disabled, jobs might proceed without validation.

**Solution:** Explicit result checking:

```yaml
if: |
  always() &&
  needs.load-config.result == 'success' &&
  (needs.sast.result == 'success' || needs.sast.result == 'skipped') &&
  (needs.iac.result == 'success' || needs.iac.result == 'skipped') &&
  !contains(needs.*.result, 'failure') &&
  !contains(needs.*.result, 'cancelled')
```

**What This Does:**
1. `always()` - Evaluate condition even if deps skipped
2. Check load-config succeeded (config is valid)
3. Check SAST either passed OR was skipped (not failed)
4. Check IaC either passed OR was skipped (not failed)
5. Ensure no failures anywhere
6. Ensure nothing was cancelled

---

### **Language Routing Decision**

**Implementation:**
```yaml
needs.load-config.outputs.language == 'node'  # Only for Node
needs.load-config.outputs.language == 'python'  # Only for Python
needs.load-config.outputs.language == 'maven'  # Only for Maven
```

**Why Not Use Matrix Strategy:**
- Matrix would run ALL builds (waste)
- We only want ONE build to run
- Config-driven routing is more explicit
- Easier to debug and understand

---

### **Docker Conditional Logic**

**Config Check:**
```yaml
fromJson(needs.load-config.outputs.config).docker.enabled == true
```

**Why JSON Parsing:**
- Config is passed as JSON string
- `fromJson()` parses it to object
- Can then access nested properties
- Type-safe boolean comparison

---

## 🧩 Module Design

### **Build Modules (node-build.yaml, python-build.yaml, maven-build.yaml)**

**Common Pattern:**
```yaml
on:
  workflow_call:
    inputs:
      working_directory:
        type: string
        default: "."
      run_tests:
        type: boolean
        default: true
      artifact_path:
        type: string
        default: ""
    outputs:
      artifact_name:
        value: ${{ jobs.build.outputs.artifact_name }}
```

**Execution Flow:**
1. Setup language runtime (with native caching)
2. Install dependencies
3. Run unit tests (if enabled)
4. Capture test results as artifact
5. Build application
6. Upload build artifact (if path specified)

**Why Separate Test Step:**
- Tests run BEFORE build (fail-fast)
- Test results captured even on failure
- Build can skip tests (already ran)

---

### **Docker Build Module (docker-build.yaml)**

**Dual Strategy Pattern:**

```yaml
# Strategy A: AWS ECR with OIDC
- name: Configure AWS Credentials
  if: inputs.registry_type == 'ecr'
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ inputs.role_to_assume }}

# Strategy B: Generic with Username/Password
- name: Login to Generic Registry
  if: inputs.registry_type == 'generic'
  uses: docker/login-action@v3
  with:
    registry: ${{ inputs.registry_url }}
    username: ${{ secrets.registry_username }}
    password: ${{ secrets.registry_password }}
```

**Image URI Construction:**

```bash
# Determine registry
if [[ "${{ inputs.registry_type }}" == "ecr" ]]; then
  REGISTRY="${{ steps.login-ecr.outputs.registry }}"
else
  REGISTRY="${{ inputs.registry_url }}"
fi

# Construct full URI
FULL_URI="$REGISTRY/${{ inputs.image_name }}:$TAG"
```

**Multi-Stage Caching:**
```yaml
cache-from: type=gha          # Read from GitHub Actions cache
cache-to: type=gha,mode=max   # Write all layers to cache
```

---

### **Security Modules**

#### **SAST (sast-scan.yaml)**
- **Tool:** Semgrep
- **Mode:** Local-only (no cloud)
- **Output:** SARIF → GitHub Security tab
- **Configurable:** Severity threshold, exclusions

#### **IaC (iac-scan.yaml)**
- **Tool:** Checkov
- **Targets:** Terraform, K8s, CloudFormation, etc.
- **Mode:** Graph-based analysis
- **Configurable:** Soft-fail, skip checks, frameworks

#### **Container Scan (trivy-scan.yaml)**
- **Tool:** Trivy
- **Modes:** Filesystem OR Image
- **Scans:** Vulnerabilities, secrets, misconfigs
- **Configurable:** Severity, ignore unfixed

#### **SBOM (sbom-generate.yaml)**
- **Tool:** Syft
- **Modes:** Filesystem OR Image
- **Formats:** CycloneDX, SPDX
- **Purpose:** Inventory only (non-blocking)

#### **SBOM Scan (sbom-scan.yaml)**
- **Tool:** Grype
- **Input:** SBOM from previous job
- **Purpose:** CVE analysis
- **Mode:** Always non-blocking (report only)

---

## 📊 Data Flow

### **Configuration Flow**

```
devx-ci.yaml (YAML)
        ↓
    yq parse
        ↓
    JSON string
        ↓
  GitHub Output
        ↓
fromJson() in downstream jobs
        ↓
  Access properties
```

### **Artifact Flow**

```
Build Job
    ↓
upload-artifact
    ↓
GitHub Artifacts Storage
    ↓
download-artifact (if needed)
    ↓
Next Job
```

### **Image Flow**

```
docker-build.yaml
    ↓
Build & Push
    ↓
Container Registry (ECR/GHCR/DockerHub)
    ↓
Output: image_uri + image_digest
    ↓
trivy-scan.yaml (scans from registry)
    ↓
sbom-generate.yaml (analyzes from registry)
```

### **SARIF Flow**

```
Security Scan Job
    ↓
Generate SARIF file
    ↓
upload-sarif action
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
    ├─ SAST (source code analysis)
    └─ IaC (infrastructure configuration)

Layer 2: Build
    ├─ Dependency resolution
    ├─ Unit tests
    └─ Build validation

Layer 3: Container
    ├─ Trivy (image vulnerabilities)
    ├─ SBOM (dependency inventory)
    └─ SBOM Scan (CVE analysis)

Layer 4: Deployment Gate
    └─ Policy enforcement (fail_on_vuln)
```

### **Credential Management**

**AWS ECR (No Stored Credentials):**
```yaml
# Uses OIDC federation
# No AWS keys in GitHub
role-to-assume: arn:aws:iam::123:role/GHA

# GitHub becomes trusted identity provider
# Temporary credentials issued per run
```

**Generic Registries (Encrypted Secrets):**
```yaml
# Stored in GitHub Secrets (encrypted at rest)
secrets:
  registry_username: ${{ secrets.REGISTRY_USERNAME }}
  registry_password: ${{ secrets.REGISTRY_PASSWORD }}

# Never logged, never exposed
# Automatically masked in logs
```

### **Permissions Model**

**Minimum Required Permissions:**
```yaml
permissions:
  contents: read          # Read code
  security-events: write  # Upload SARIF
  actions: write          # Upload artifacts
  id-token: write         # OIDC token (ECR)
  packages: write         # GHCR push (if used)
```

**Why These:**
- `contents: read` - Checkout code
- `security-events: write` - Security tab integration
- `actions: write` - Artifact upload
- `id-token: write` - AWS OIDC authentication
- `packages: write` - GHCR publishing

---

## 💾 Caching Strategy

### **Native Language Caching**

**Node.js:**
```yaml
- uses: actions/setup-node@v4
  with:
    cache: npm
    cache-dependency-path: package-lock.json
```
- Caches `~/.npm` and `node_modules`
- Key: Hash of `package-lock.json`
- Automatic restoration

**Python:**
```yaml
- uses: actions/setup-python@v5
  with:
    cache: pip
    cache-dependency-path: requirements.txt
```
- Caches `~/.cache/pip`
- Key: Hash of `requirements.txt`
- Automatic restoration

**Maven:**
```yaml
- uses: actions/setup-java@v4
  with:
    cache: maven
    cache-dependency-path: pom.xml
```
- Caches `~/.m2/repository`
- Key: Hash of `pom.xml`
- Automatic restoration

### **Docker Layer Caching**

```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**How It Works:**
1. First build: All layers built, cached to GHA
2. Second build: Unchanged layers restored from cache
3. Only changed layers rebuilt
4. Significant speed improvement (5-10x faster)

**Cache Scope:**
- Per repository
- Per branch (with fallback to default branch)
- Shared across workflow runs

---

## ⚠️ Error Handling

### **Validation Errors (Fail Fast)**

```yaml
- name: Validate Inputs
  run: |
    if [[ "${{ inputs.registry_type }}" == "ecr" ]]; then
      if [[ -z "${{ inputs.role_to_assume }}" ]]; then
        echo "::error::role_to_assume is required for ECR"
        exit 1
      fi
    fi
```

**Strategy:**
- Validate ALL inputs before execution
- Fail with clear error messages
- Provide remediation guidance

### **Timeout Protection**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Job level

    steps:
      - name: Run Tests
        timeout-minutes: 15  # Step level
```

**Why Both:**
- Step timeout: Catch individual hung steps
- Job timeout: Catch overall workflow issues
- Prevents infinite runner consumption

### **Conditional Failure Handling**

```yaml
continue-on-error: ${{ inputs.fail_on_findings == false }}
```

**Use Cases:**
- Security scans (audit mode vs enforcement)
- Optional checks
- Backward compatibility

### **Always Blocks for Cleanup**

```yaml
- name: Upload Test Results
  if: always() && inputs.run_tests == true
```

**Guarantees:**
- Test results captured even on failure
- Artifacts uploaded for debugging
- Proper cleanup on error

---

## ⚡ Performance Optimization

### **Parallel Execution**

```yaml
# Security gates run simultaneously
sast:
  needs: [load-config]

iac:
  needs: [load-config]  # No dependency on sast
```

**Time Savings:**
```
Sequential: SAST (5min) + IaC (3min) = 8min
Parallel:   max(SAST, IaC) = 5min
Savings:    3min (37.5%)
```

### **Conditional Execution**

```yaml
if: fromJson(needs.load-config.outputs.config).docker.enabled == true
```

**Benefits:**
- Skip unnecessary jobs
- Reduce runner time
- Faster feedback

### **Smart Caching**

**Impact:**
```
First Run:  Dependencies (5min) + Build (3min) = 8min
Cached Run: Cache Hit (10sec) + Build (3min) = 3min 10sec
Savings:    60% reduction
```

### **Job Concurrency Control**

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Benefits:**
- Cancel old runs on new push
- Save runner minutes
- Faster feedback on latest code

---

## 📈 Scalability Considerations

### **Multi-Repository Design**

**Centralized:**
- Single source of truth
- Version-controlled workflows
- Consistent across all projects

**Project-Specific:**
- Minimal configuration (2 files)
- Full customization possible
- No workflow duplication

### **Resource Management**

**Runner Usage:**
- Average pipeline: 15-25 minutes
- Typical cost: $0.008/minute (GitHub hosted)
- Per run cost: $0.12 - $0.20

**Optimization:**
- Caching reduces costs 40-60%
- Parallel execution reduces time 30-40%
- Conditional jobs reduce unnecessary work

---

## 🔄 Workflow Lifecycle

### **Development → Production**

```
1. Change Workflow
   ↓
2. Test with workflow_dispatch
   ↓
3. Version with git tag (v1.x.x)
   ↓
4. Projects reference @v1
   ↓
5. Update moves to @v1.1.0
   ↓
6. Projects automatically get fixes (minor versions)
   ↓
7. Breaking changes require @v2
```

### **Version Strategy**

**Recommended:**
```yaml
# Projects should use:
uses: org/workflows/.github/workflows/ci-orchestrator.yaml@v1

# Not:
uses: org/workflows/.github/workflows/ci-orchestrator.yaml@main
```

**Why:**
- `@v1` tracks latest `v1.x.x` (gets fixes)
- `@main` gets breaking changes
- Controlled rollout of major versions

---

## 🎯 Design Decisions

### **Why Config File Instead of Workflow Inputs?**

**Config File Approach:**
```yaml
# devx-ci.yaml
project:
  language: node
security:
  sast:
    enabled: true
```

**Alternative (Not Used):**
```yaml
# .github/workflows/ci.yaml
with:
  language: node
  sast_enabled: true
  sast_severity: ERROR
  # ... 30+ more inputs
```

**Reasons for Config File:**
1. Single source of truth
2. Easier to read and maintain
3. Version controlled with code
4. Can be validated independently
5. Better for complex configurations

### **Why Orchestrator Instead of Composite Actions?**

**Orchestrator Pattern:**
- Clearer job dependency visualization
- Better parallel execution control
- Easier to debug (each job separate)
- GitHub Actions UI shows flow

**Composite Actions:**
- All steps in single job
- Harder to parallelize
- Less visibility in UI
- More complex error handling

### **Why No Workflow Templates?**

**Our Approach:**
- Reusable workflows called from projects
- Projects have minimal `.github/workflows/ci.yaml`

**Workflow Templates:**
- GitHub feature for repository creation
- Creates copy of workflow in new repo
- No centralized updates
- Leads to drift

**Our approach ensures:**
- Central updates propagate automatically
- Consistent behavior across all projects
- Single source of truth

---

## 📊 Metrics & Observability

### **Built-in Observability**

**GitHub Actions Provides:**
- Job duration tracking
- Success/failure rates
- Step-level timing
- Log aggregation

**Our Additions:**
- Pipeline summary job (overall status)
- Artifact uploads (test results, coverage)
- SARIF uploads (security findings)

### **Recommended Monitoring**

**Metrics to Track:**
- Average pipeline duration per language
- Success rate per workflow
- Most common failure points
- Security findings trends
- Runner minute consumption

**Alerts to Set:**
- Pipeline duration > 30min
- Success rate < 90%
- Security findings increase
- Cost anomalies

---

## 📝 Summary

### **Key Architectural Patterns**

1. **Config-Driven:** Single YAML controls everything
2. **Modular:** Composable workflow building blocks
3. **Fail-Fast:** Early validation and security gates
4. **Parallel:** Maximize concurrency where possible
5. **Conditional:** Skip unnecessary work
6. **Cached:** Optimize for speed and cost
7. **Secure:** Multiple security layers
8. **Observable:** Clear feedback and artifacts

### **Design Philosophy**

- **Simplicity:** Easy to understand and use
- **Consistency:** Same patterns across all workflows
- **Flexibility:** Highly configurable
- **Reliability:** Deterministic and reproducible
- **Security:** Defense in depth
- **Performance:** Optimized for speed and cost