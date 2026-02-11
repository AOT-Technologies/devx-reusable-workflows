# DevX CI Configuration Examples

This directory contains complete, working examples of `devx-ci.yaml` configurations for different project types.

---

## 📦 Available Examples

| Example | Description |
|---------|-------------|
| `devx-ci.node.yaml` | Node.js with NPM publish to Nexus |
| `devx-ci.python.yaml` | Python with PyPI (twine) upload to Nexus |
| `devx-ci.maven.yaml` | Java Maven with standard deploy to Nexus |
| `devx-ci.sonarqube.yaml` | Any language with SonarQube integration |
| `devx-ci.minimal.yaml` | Minimum viable configuration |

---

## 🚀 Full Examples

### **Node.js (devx-ci.node.yaml)**

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
  docker_registry_url: "nexus.example.com:8082"

security:
  sast:
    enabled: true
    exclude_paths: "node_modules/"
  trivy:
    enabled: true
  sbom:
    enabled: true

docker:
  enabled: true
  image_name: demo-node-app
  registry_type: nexus
```

### **Python (devx-ci.python.yaml)**

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
  docker_registry_url: "nexus.example.com:8082"

security:
  sast:
    enabled: true
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: demo-python-app
  registry_type: nexus
```

### **Java Maven (devx-ci.maven.yaml)**

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
  trivy:
    enabled: true

docker:
  enabled: true
  image_name: demo-java-app
  registry_type: nexus
```

### **With SonarQube (devx-ci.sonarqube.yaml)**

```yaml
project:
  language: node
  version: "20"

build:
  run_tests: true

security:
  sast:
    enabled: true
    tool: sonarqube
    sonar_host_url: "https://sonarqube.example.com"
    sonar_project_key: "my-project"
    fail_on_quality_gate: true
  trivy:
    enabled: true

docker:
  enabled: false
```

### **Minimal (devx-ci.minimal.yaml)**

```yaml
project:
  language: node
```

This will:
- Run tests with default Node 20
- Enable Semgrep SAST
- Skip Docker build
- Skip Nexus upload
