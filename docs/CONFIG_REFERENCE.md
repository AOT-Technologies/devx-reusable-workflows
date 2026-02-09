# devx-ci.yaml Configuration Reference

Complete reference for all configuration options in the `devx-ci.yaml` file.

> **Looking for CD Configuration?**  
> Check out the [CD Configuration Reference](CD_CONFIG_REFERENCE.md) for `devx-config.yaml`.

---

## 📋 Table of Contents

- [Minimum Configuration](#minimum-configuration)
- [Full Configuration Template](#full-configuration-template)
- [Project Section](#project-section)
- [Build Section](#build-section)
- [Nexus Section](#nexus-section)
- [Security Section](#security-section)
- [Docker Section](#docker-section)
- [AWS Section](#aws-section)
- [Complete Examples](#complete-examples)

---

## 🏗️ Minimum Configuration

The only required field is `project.language`:

```yaml
project:
  language: node  # REQUIRED: node | python | maven
```

---

## 📄 Full Configuration Template

```yaml
# =============================================================================
# PROJECT SETTINGS
# =============================================================================
project:
  language: node              # REQUIRED: node | python | maven
  version: "20"               # Optional: language version
  working_directory: "."      # Optional: project root

# =============================================================================
# BUILD SETTINGS
# =============================================================================
build:
  run_tests: true             # Optional: run unit tests
  test_script: "test"         # Optional: custom test command
  run_build: false            # Optional: run build step
  build_script: "build"       # Optional: custom build command
  build_command: ""           # Optional: custom build command (Python)
  maven_args: ""              # Optional: Maven build arguments
  artifact_path: ""           # Optional: path to build output

# =============================================================================
# NEXUS SETTINGS
# =============================================================================
nexus:
  url: ""                     # Nexus base URL
  repository: "raw-releases"  # Target repository name
  repo_type: "raw"            # raw | npm | pypi
  upload_path: ""             # Custom path (raw mode only)
  docker_registry_url: ""     # Nexus Docker registry URL
  docker_repository: "docker-hosted"

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
security:
  sast:
    enabled: true
    tool: semgrep             # semgrep | sonarqube
    scan_path: "."
    exclude_paths: ""
    severity: ERROR           # INFO | WARNING | ERROR
    fail_on_findings: true
    # SonarQube-specific
    sonar_host_url: ""
    sonar_organization: ""
    sonar_project_key: ""
    fail_on_quality_gate: true
    coverage_report_path: ""
  
  iac:
    enabled: false
    working_directory: "."
    frameworks: ""            # terraform,kubernetes,cloudformation
    soft_fail: false
    skip_check: ""            # CKV_AWS_1,CKV_K8S_2
  
  trivy:
    enabled: true
    severity: "CRITICAL,HIGH"
    fail_on_vuln: true
    ignore_unfixed: true
    scanners: "vuln,secret,misconfig"
  
  sbom:
    enabled: true
    format: cyclonedx-json    # cyclonedx-json | spdx-json
  
  sbom_scan:
    enabled: true
    severity: medium          # negligible | low | medium | high | critical
    format: sarif

# =============================================================================
# DOCKER SETTINGS
# =============================================================================
docker:
  enabled: false
  working_directory: "."
  dockerfile: Dockerfile
  image_name: ""              # REQUIRED if docker.enabled=true
  image_tag: ""               # Optional: defaults to git SHA
  registry_type: ecr          # ecr | generic | nexus
  registry_url: ""            # Required for generic
  build_args: ""              # Multi-line KEY=VALUE
  platforms: linux/amd64      # linux/amd64,linux/arm64

# =============================================================================
# AWS SETTINGS (Required for ECR)
# =============================================================================
aws:
  region: us-east-1
  role_to_assume: ""          # Required for ECR
```

---

## 📦 Project Section

Defines your project's language and basic configuration.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `language` | string | **REQUIRED** | `node`, `python`, or `maven` |
| `version` | string | Auto-detected | Language runtime version |
| `working_directory` | string | `.` | Directory containing project files |

**Version Defaults:**
- Node.js: `"20"`
- Python: `"3.11"`
- Maven/Java: `"17"`

**Example:**
```yaml
project:
  language: python
  version: "3.11"
  working_directory: "./backend"
```

---

## 🔨 Build Section

Controls build and test execution. Fields vary by language.

### **Common Fields**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `run_tests` | boolean | `true` | Run unit tests before building |
| `artifact_path` | string | `""` | Path to build output to upload |

### **Node.js Specific**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `test_script` | string | `"test"` | Script name or command for tests |
| `run_build` | boolean | `false` | Enable build step |
| `build_script` | string | `"build"` | Script name or command for build |

**Example:**
```yaml
build:
  run_tests: true
  test_script: "test:unit"     # Runs `npm run test:unit`
  run_build: true
  build_script: "build"        # Runs `npm run build`
  artifact_path: "dist/"
```

### **Python Specific**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `test_script` | string | `"python -m pytest"` | Test command |
| `build_command` | string | `""` | Build command (e.g., `python setup.py bdist_wheel`) |
| `install_command` | string | `"pip install -r requirements.txt"` | Install command |

**Example:**
```yaml
build:
  run_tests: true
  test_script: "python -m pytest -v"
  build_command: "pip install wheel && python setup.py bdist_wheel"
  artifact_path: "dist/*.whl"
```

### **Maven Specific**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `test_script` | string | `"mvn test -B"` | Test command |
| `maven_args` | string | `-B clean package...` | Maven build arguments |

**Example:**
```yaml
build:
  run_tests: true
  test_script: "mvn test -B"
  maven_args: "-B clean package -DskipTests"
  artifact_path: "target/*.jar"
```

---

## 📦 Nexus Section

Configure artifact publishing to Sonatype Nexus.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `url` | string | `""` | Base URL (e.g., `https://nexus.example.com`) |
| `repository` | string | `"raw-releases"` | Target repository name |
| `repo_type` | string | `"raw"` | `npm`, `pypi`, or `raw` |
| `upload_path` | string | `""` | Custom path (raw mode only) |
| `docker_registry_url` | string | `""` | Nexus Docker registry URL |
| `docker_repository` | string | `"docker-hosted"` | Nexus Docker repository name |

### **Repository Types**

| Type | Protocol | Example Repository |
|------|----------|-------------------|
| `npm` | Native NPM | `npm-hosted` |
| `pypi` | Twine upload | `pypi-hosted` |
| `raw` | HTTP PUT | `raw-releases` |

**NPM Example:**
```yaml
nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"
  repo_type: "npm"
```

**PyPI Example:**
```yaml
nexus:
  url: "https://nexus.example.com"
  repository: "pypi-hosted"
  repo_type: "pypi"
```

**Maven Example:**
```yaml
nexus:
  url: "https://nexus.example.com"
  repository: "maven-releases"
  # repo_type not needed for Maven - uses standard layout
```

---

## 🔐 Security Section

Configure security scanning modules.

### **SAST (Static Application Security Testing)**

Supports two tools: **Semgrep** (default, free) or **SonarQube** (enterprise).

#### **Semgrep Configuration**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable SAST scanning |
| `tool` | string | `"semgrep"` | `semgrep` or `sonarqube` |
| `scan_path` | string | `"."` | Path to source code |
| `exclude_paths` | string | `""` | Comma-separated paths to exclude |
| `severity` | string | `"ERROR"` | `INFO`, `WARNING`, or `ERROR` |
| `fail_on_findings` | boolean | `true` | Block pipeline on findings |
| `ruleset` | string | `"p/ci"` | Semgrep ruleset |

**Example:**
```yaml
security:
  sast:
    enabled: true
    tool: semgrep
    scan_path: "./src"
    exclude_paths: "tests/,migrations/,node_modules/"
    severity: ERROR
    fail_on_findings: true
```

#### **SonarQube Configuration**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `sonar_host_url` | string | `""` | SonarQube server URL |
| `sonar_organization` | string | `""` | Organization key (SonarCloud) |
| `sonar_project_key` | string | `""` | Project key |
| `fail_on_quality_gate` | boolean | `true` | Block on quality gate failure |
| `coverage_report_path` | string | `""` | Path to coverage report |

**Example:**
```yaml
security:
  sast:
    enabled: true
    tool: sonarqube
    sonar_host_url: "https://sonarqube.example.com"
    sonar_project_key: "my-project"
    fail_on_quality_gate: true
```

**Required Secret:** `SONAR_TOKEN`

---

### **IaC (Infrastructure as Code) Scanning**

Scans infrastructure code using Checkov.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable IaC scanning |
| `working_directory` | string | `"."` | Directory containing IaC files |
| `frameworks` | string | `""` | Frameworks to scan (auto-detect if empty) |
| `soft_fail` | boolean | `false` | Audit mode - don't fail pipeline |
| `skip_check` | string | `""` | Comma-separated Checkov IDs to skip |

**Supported Frameworks:**
- `terraform`
- `kubernetes`
- `cloudformation`
- `arm`
- `serverless`
- `helm`

**Example:**
```yaml
security:
  iac:
    enabled: true
    working_directory: "./infrastructure"
    frameworks: "terraform,kubernetes"
    soft_fail: false
    skip_check: "CKV_AWS_18,CKV_AWS_21"
```

---

### **Trivy (Container/Filesystem Scanning)**

Universal vulnerability scanner.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable Trivy scanning |
| `severity` | string | `"CRITICAL,HIGH"` | Severities to report |
| `fail_on_vuln` | boolean | `true` | Block pipeline on findings |
| `ignore_unfixed` | boolean | `true` | Skip vulns with no fix |
| `scanners` | string | `"vuln,secret,misconfig"` | Types of scans |

**Severity Levels:**
- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

**Example:**
```yaml
security:
  trivy:
    enabled: true
    severity: "CRITICAL,HIGH,MEDIUM"
    fail_on_vuln: true
    ignore_unfixed: true
    scanners: "vuln,secret,misconfig"
```

---

### **SBOM (Software Bill of Materials)**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable SBOM generation |
| `format` | string | `"cyclonedx-json"` | Output format |

**Formats:**
- `cyclonedx-json`
- `cyclonedx-xml`
- `spdx-json`
- `spdx-tag-value`

---

### **SBOM Scan**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable SBOM vulnerability scan |
| `severity` | string | `"medium"` | Minimum severity to report |
| `format` | string | `"sarif"` | Output format |

**Note:** SBOM scan **never fails** the pipeline - it's report-only.

---

## 🐳 Docker Section

Configure Docker image building and registry.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable Docker build |
| `working_directory` | string | `"."` | Directory with Dockerfile |
| `dockerfile` | string | `"Dockerfile"` | Dockerfile name |
| `image_name` | string | **REQUIRED** | Image name |
| `image_tag` | string | Git SHA | Image tag |
| `registry_type` | string | `"ecr"` | `ecr`, `generic`, or `nexus` |
| `registry_url` | string | `""` | Registry URL (generic mode) |
| `build_args` | string | `""` | Multi-line build arguments |
| `platforms` | string | `"linux/amd64"` | Target platforms |

### **Registry Types**

| Type | Use Case | Required Fields |
|------|----------|-----------------|
| `ecr` | AWS ECR | `aws.role_to_assume` |
| `generic` | Docker Hub, GHCR | `registry_url`, secrets |
| `nexus` | Nexus Docker | `nexus.docker_registry_url` |

**Multi-Architecture Example:**
```yaml
docker:
  enabled: true
  image_name: my-app
  registry_type: nexus
  platforms: "linux/amd64,linux/arm64"
  build_args: |
    VERSION=1.0.0
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
```

---

## ☁️ AWS Section

Required when using ECR.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `region` | string | `"us-east-1"` | AWS region |
| `role_to_assume` | string | `""` | IAM Role ARN for OIDC |

**Example:**
```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

## 📚 Complete Examples

### **Node.js with NPM and Nexus**

```yaml
project:
  language: node
  version: "20"

build:
  run_tests: true
  run_build: true
  build_script: "build"
  artifact_path: "dist/"

nexus:
  url: "https://nexus.example.com"
  repository: "npm-hosted"
  repo_type: "npm"
  docker_registry_url: "nexus.example.com:8082"

security:
  sast:
    enabled: true
    exclude_paths: "node_modules/,tests/"
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-node-app
  registry_type: nexus
```

---

### **Python with PyPI and SonarQube**

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

security:
  sast:
    enabled: true
    tool: sonarqube
    sonar_host_url: "https://sonar.example.com"
    sonar_project_key: "my-python-app"
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-python-app
  registry_type: nexus
```

---

### **Java with Maven and IaC Scanning**

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

security:
  sast:
    enabled: true
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: "terraform"
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: my-java-app
  registry_type: ecr

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```