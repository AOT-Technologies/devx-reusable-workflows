# devx-ci.yaml Configuration Reference

Complete reference for the `devx-ci.yaml` configuration file.

---

## 📋 Table of Contents

- [Configuration Schema](#configuration-schema)
- [Project Section](#project-section)
- [Build Section](#build-section)
- [Security Section](#security-section)
- [Docker Section](#docker-section)
- [AWS Section](#aws-section)
- [Complete Examples](#complete-examples)

---

## 🏗️ Configuration Schema

### **Minimum Required Configuration**

```yaml
project:
  language: node  # REQUIRED: node | python | maven
```

### **Full Configuration Template**

```yaml
project:
  language: node              # REQUIRED
  version: "20"               # Optional: language version
  working_directory: "."      # Optional: project root

build:
  run_tests: true             # Optional: run unit tests
  test_script: ""             # Optional: custom test command
  build_script: ""            # Optional: custom build command
  artifact_path: ""           # Optional: path to build output

security:
  sast:
    enabled: true
    scan_path: "."
    exclude_paths: ""
    severity: ERROR
    fail_on_findings: true
  
  iac:
    enabled: false
    working_directory: "."
    frameworks: ""
    soft_fail: false
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  sbom:
    enabled: true
    format: cyclonedx-json
  
  sbom_scan:
    enabled: true
    severity: medium
    format: sarif

docker:
  enabled: false
  working_directory: "."
  dockerfile: Dockerfile
  image_name: ""              # REQUIRED if docker.enabled=true
  image_tag: ""               # Optional: defaults to git SHA
  registry_type: ecr          # ecr | generic
  registry_url: ""            # Required for generic
  build_args: ""
  platforms: linux/amd64

aws:
  region: us-east-1
  role_to_assume: ""          # Required for ECR
```

---

## 📦 Project Section

Defines your project's language and basic configuration.

### **Fields**

#### `language` (REQUIRED)
**Type:** string  
**Valid Values:** `node` | `python` | `maven`  
**Description:** Programming language of your project

```yaml
project:
  language: node
```

#### `version` (Optional)
**Type:** string  
**Default:** 
- Node: `"20"`
- Python: `"3.11"`
- Maven/Java: `"17"`

**Description:** Language/runtime version to use

```yaml
project:
  language: node
  version: "18"  # Use Node 18 instead of default 20
```

#### `working_directory` (Optional)
**Type:** string  
**Default:** `"."`  
**Description:** Directory containing your project files

```yaml
project:
  language: python
  working_directory: "./backend"  # Project is in backend/ subdirectory
```

---

## 🔨 Build Section

Controls build and test execution.

### **Fields**

#### `run_tests` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Run unit tests before building

```yaml
build:
  run_tests: true  # Run tests
```

#### `test_script` (Optional)
**Type:** string  
**Default:** 
- Node: `npm test`
- Python: `python -m pytest`
- Maven: `mvn test -B`

**Description:** Custom command to run tests.

```yaml
build:
  test_script: "npm run test:unit"  # Run specific test script
```

#### `build_script` (Optional)
**Type:** string  
**Default:** 
- Node: `npm run build`
- Python: `""` (none)
- Maven: `-B clean package ...`

**Description:** Custom command to build the application. Set to `none` to skip the build step.

```yaml
build:
  build_script: "npm run build:prod"  # Custom build command
```

```yaml
build:
  build_script: "none"  # Skip build step entirely
```

#### `artifact_path` (Optional)
**Type:** string  
**Default:** `""` (no artifact upload)  
**Description:** Path to build output to upload as artifact

**Node.js Example:**
```yaml
build:
  artifact_path: "dist/"  # Upload dist/ directory
```

**Python Example:**
```yaml
build:
  artifact_path: "dist/*.whl"  # Upload wheel files
```

**Maven Example:**
```yaml
build:
  artifact_path: "target/*.jar"  # Upload JAR files
```

---

## 🔐 Security Section

Configure security scanning modules.

### **SAST (Static Application Security Testing)**

Scans source code for vulnerabilities using Semgrep.

#### `sast.enabled` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Enable SAST scanning

#### `sast.scan_path` (Optional)
**Type:** string  
**Default:** `"."`  
**Description:** Path to source code

```yaml
security:
  sast:
    enabled: true
    scan_path: "./src"  # Only scan src/ directory
```

#### `sast.exclude_paths` (Optional)
**Type:** string  
**Default:** `""`  
**Description:** Comma-separated paths to exclude

```yaml
security:
  sast:
    exclude_paths: "node_modules/,tests/,vendor/"
```

#### `sast.severity` (Optional)
**Type:** string  
**Default:** `"ERROR"`  
**Valid Values:** `INFO` | `WARNING` | `ERROR`  
**Description:** Minimum severity to report

```yaml
security:
  sast:
    severity: WARNING  # Report WARNING and ERROR findings
```

#### `sast.fail_on_findings` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Fail pipeline if vulnerabilities found

```yaml
security:
  sast:
    fail_on_findings: false  # Audit mode - don't block builds
```

**Complete SAST Example:**
```yaml
security:
  sast:
    enabled: true
    scan_path: "./src"
    exclude_paths: "tests/,migrations/"
    severity: ERROR
    fail_on_findings: true
```

---

### **IaC (Infrastructure as Code) Scanning**

Scans infrastructure code using Checkov.

#### `iac.enabled` (Optional)
**Type:** boolean  
**Default:** `false`  
**Description:** Enable IaC scanning

#### `iac.working_directory` (Optional)
**Type:** string  
**Default:** `"."`  
**Description:** Directory containing IaC files

```yaml
security:
  iac:
    enabled: true
    working_directory: "./terraform"
```

#### `iac.frameworks` (Optional)
**Type:** string  
**Default:** `""` (auto-detect)  
**Valid Values:** `terraform`, `kubernetes`, `cloudformation`, `arm`, `serverless`  
**Description:** Specific frameworks to scan

```yaml
security:
  iac:
    enabled: true
    frameworks: terraform,kubernetes  # Only scan these
```

#### `iac.soft_fail` (Optional)
**Type:** boolean  
**Default:** `false`  
**Description:** Audit mode - don't block builds on failures

```yaml
security:
  iac:
    enabled: true
    soft_fail: true  # Report but don't fail
```

**Complete IaC Example:**
```yaml
security:
  iac:
    enabled: true
    working_directory: "./infrastructure"
    frameworks: terraform
    soft_fail: false  # Block on security issues
```

---

### **Trivy (Container/Filesystem Scanning)**

Scans containers and filesystems for vulnerabilities.

#### `trivy.enabled` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Enable Trivy scanning

#### `trivy.severity` (Optional)
**Type:** string  
**Default:** `"CRITICAL,HIGH"`  
**Valid Values:** `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `UNKNOWN`  
**Description:** Comma-separated severities to report

```yaml
security:
  trivy:
    enabled: true
    severity: CRITICAL,HIGH,MEDIUM  # Include MEDIUM severity
```

#### `trivy.fail_on_vuln` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Fail pipeline if vulnerabilities found

```yaml
security:
  trivy:
    fail_on_vuln: false  # Audit mode
```

**Complete Trivy Example:**
```yaml
security:
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
```

---

### **SBOM (Software Bill of Materials)**

Generate inventory of software components.

#### `sbom.enabled` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Enable SBOM generation

#### `sbom.format` (Optional)
**Type:** string  
**Default:** `"cyclonedx-json"`  
**Valid Values:** `cyclonedx-json`, `cyclonedx-xml`, `spdx-json`, `spdx-tag-value`  
**Description:** SBOM output format

```yaml
security:
  sbom:
    enabled: true
    format: spdx-json  # Use SPDX format
```

---

### **SBOM Scan**

Scan SBOM for vulnerabilities using Grype.

#### `sbom_scan.enabled` (Optional)
**Type:** boolean  
**Default:** `true`  
**Description:** Enable SBOM vulnerability scanning

#### `sbom_scan.severity` (Optional)
**Type:** string  
**Default:** `"medium"`  
**Valid Values:** `negligible`, `low`, `medium`, `high`, `critical`  
**Description:** Minimum severity threshold

```yaml
security:
  sbom_scan:
    enabled: true
    severity: high  # Only report high and critical
```

#### `sbom_scan.format` (Optional)
**Type:** string  
**Default:** `"sarif"`  
**Valid Values:** `sarif`, `json`, `table`  
**Description:** Output format

**Complete SBOM Example:**
```yaml
security:
  sbom:
    enabled: true
    format: cyclonedx-json
  sbom_scan:
    enabled: true
    severity: medium
    format: sarif
```

---

## 🐳 Docker Section

Configure Docker image building.

### **Fields**

#### `docker.enabled` (Optional)
**Type:** boolean  
**Default:** `false`  
**Description:** Enable Docker image building

#### `docker.working_directory` (Optional)
**Type:** string  
**Default:** `"."`  
**Description:** Directory containing Dockerfile

```yaml
docker:
  enabled: true
  working_directory: "./app"
```

#### `docker.dockerfile` (Optional)
**Type:** string  
**Default:** `"Dockerfile"`  
**Description:** Dockerfile name

```yaml
docker:
  enabled: true
  dockerfile: "Dockerfile.prod"
```

#### `docker.image_name` (REQUIRED if enabled)
**Type:** string  
**Description:** Docker image name

```yaml
docker:
  enabled: true
  image_name: my-app
```

For Docker Hub with organization:
```yaml
docker:
  enabled: true
  image_name: myorg/my-app
```

#### `docker.image_tag` (Optional)
**Type:** string  
**Default:** Git commit SHA  
**Description:** Image tag

```yaml
docker:
  enabled: true
  image_name: my-app
  image_tag: v1.0.0
```

#### `docker.registry_type` (Optional)
**Type:** string  
**Default:** `"ecr"`  
**Valid Values:** `ecr` | `generic`  
**Description:** Container registry type

**ECR (AWS):**
```yaml
docker:
  registry_type: ecr
```

**GHCR (GitHub):**
```yaml
docker:
  registry_type: generic
  registry_url: ghcr.io
```

**Docker Hub:**
```yaml
docker:
  registry_type: generic
  registry_url: docker.io
```

#### `docker.registry_url` (Required for generic)
**Type:** string  
**Description:** Registry URL for generic mode

```yaml
docker:
  registry_type: generic
  registry_url: ghcr.io
```

#### `docker.build_args` (Optional)
**Type:** string (multi-line)  
**Default:** `""`  
**Description:** Docker build arguments (KEY=VALUE format)

```yaml
docker:
  build_args: |
    VERSION=1.0.0
    BUILD_DATE=2025-01-01
    ENVIRONMENT=production
```

#### `docker.platforms` (Optional)
**Type:** string  
**Default:** `"linux/amd64"`  
**Description:** Target platforms (comma-separated)

**Multi-architecture:**
```yaml
docker:
  platforms: linux/amd64,linux/arm64
```

**Complete Docker Example (ECR):**
```yaml
docker:
  enabled: true
  working_directory: "."
  dockerfile: Dockerfile
  image_name: my-app
  image_tag: v1.0.0
  registry_type: ecr
  build_args: |
    VERSION=1.0.0
  platforms: linux/amd64
```

**Complete Docker Example (GHCR):**
```yaml
docker:
  enabled: true
  image_name: my-org/my-app
  registry_type: generic
  registry_url: ghcr.io
  platforms: linux/amd64,linux/arm64
```

---

## ☁️ AWS Section

AWS-specific configuration (required for ECR).

### **Fields**

#### `aws.region` (Optional)
**Type:** string  
**Default:** `"us-east-1"`  
**Description:** AWS region

```yaml
aws:
  region: us-west-2
```

#### `aws.role_to_assume` (Required for ECR)
**Type:** string  
**Description:** IAM role ARN for OIDC authentication

```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

**Complete AWS Example:**
```yaml
aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole

docker:
  enabled: true
  image_name: my-app
  registry_type: ecr
```

---

## 📚 Complete Examples

### **Example 1: Simple Node.js App (No Docker)**

```yaml
project:
  language: node
  version: "20"
  working_directory: "."

build:
  run_tests: true
  artifact_path: "dist/"

security:
  sast:
    enabled: true
    exclude_paths: "node_modules/,tests/"
    severity: ERROR
    fail_on_findings: true
  
  iac:
    enabled: false
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  sbom:
    enabled: true
    format: cyclonedx-json
  
  sbom_scan:
    enabled: true
    severity: medium

docker:
  enabled: false
```

---

### **Example 2: Python with Docker (ECR)**

```yaml
project:
  language: python
  version: "3.11"
  working_directory: "."

build:
  run_tests: true
  artifact_path: "dist/"

security:
  sast:
    enabled: true
    scan_path: "./src"
    severity: ERROR
    fail_on_findings: true
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  sbom:
    enabled: true

docker:
  enabled: true
  image_name: my-python-app
  registry_type: ecr
  dockerfile: Dockerfile
  platforms: linux/amd64

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

### **Example 3: Java with IaC Scanning**

```yaml
project:
  language: maven
  version: "17"
  working_directory: "."

build:
  run_tests: true
  artifact_path: "target/*.jar"

security:
  sast:
    enabled: true
    severity: ERROR
    fail_on_findings: true
  
  iac:
    enabled: true
    working_directory: "./terraform"
    frameworks: terraform
    soft_fail: false
  
  trivy:
    enabled: true
    severity: CRITICAL,HIGH
    fail_on_vuln: true
  
  sbom:
    enabled: true
    format: spdx-json

docker:
  enabled: true
  image_name: my-java-app
  registry_type: ecr
  build_args: |
    JAR_FILE=target/app.jar
    JAVA_OPTS=-Xmx512m

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

### **Example 4: Multi-Service Monorepo**

```yaml
project:
  language: node
  version: "20"
  working_directory: "./services/api"  # Build only API service

build:
  run_tests: true
  artifact_path: "dist/"

security:
  sast:
    enabled: true
    scan_path: "./services"  # Scan all services
    exclude_paths: "node_modules/,tests/"
  
  iac:
    enabled: true
    working_directory: "./infrastructure"
    frameworks: terraform,kubernetes
  
  trivy:
    enabled: true

docker:
  enabled: true
  working_directory: "./services/api"
  image_name: api-service
  registry_type: generic
  registry_url: ghcr.io

aws:
  region: us-east-1
```

---

### **Example 5: Development Environment (Lenient)**

```yaml
project:
  language: node
  version: "20"

build:
  run_tests: true

security:
  sast:
    enabled: true
    fail_on_findings: false  # Don't block on dev

  trivy:
    enabled: true
    fail_on_vuln: false  # Don't block on dev
  
  sbom:
    enabled: false  # Skip SBOM in dev

docker:
  enabled: false  # Build locally
```