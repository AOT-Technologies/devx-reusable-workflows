# DevX Reusable Workflows - Examples

This directory contains complete, working examples of how to use DevX reusable workflows in different project types.

---

## 📁 **Available Examples**

### **1. [sample-node](./sample-node/.github/workflows/ci.yml)**
Complete Node.js CI pipeline demonstrating:
- Build & unit testing
- Parallel security scans (SAST + Trivy)
- Docker build on main branch
- Container image scanning
- SBOM generation

**Use for:** Node.js, TypeScript, React, Vue, Angular projects

---

### **2. [sample-python](./sample-python/.github/workflows/ci.yml)**
Complete Python CI pipeline demonstrating:
- Python build & pytest testing
- Code coverage reporting
- Security scanning
- Docker build with Python base
- Container vulnerability scanning

**Use for:** Python, Django, Flask, FastAPI projects

---

### **3. [sample-maven](./sample-maven/.github/workflows/ci.yml)**
Complete Java/Maven CI pipeline demonstrating:
- Maven build with separate test phase
- JAR artifact generation
- Security scanning
- Docker build for Spring Boot apps
- Image security scanning

**Use for:** Java, Spring Boot, Maven projects

---

### **4. [sample-terraform](./sample-terraform/.github/workflows/ci.yml)**
Infrastructure-as-Code CI pipeline demonstrating:
- Terraform validation & formatting
- Checkov IaC security scanning
- SAST for Terraform code
- Terraform plan on PRs
- Plan commenting on pull requests

**Use for:** Terraform, Infrastructure projects

---

### **5. [sample-microservices](./sample-microservices/.github/workflows/ci.yml)**
Advanced multi-service pipeline demonstrating:
- Multiple builds (frontend + backend)
- Parallel security scans per service
- Separate Docker images
- Independent SBOM generation
- Complex dependency management

**Use for:** Microservices, multi-repo, monorepo projects

---

## 🚀 **How to Use These Examples**

### **Quick Start**

1. **Choose the example** that matches your project type
2. **Copy the workflow** to your project's `.github/workflows/ci.yml`
3. **Update the configuration**:
   - Change `role_to_assume` with your AWS IAM role ARN
   - Update `image_name` to match your application
   - Adjust `working_directory` if your code isn't in the root
   - Modify `aws_region` if not using `us-east-1`

### **Customization Examples**

#### **Change Node Version**
```yaml
with:
  node_version: "18"  # or "16", "20"
```

#### **Skip Tests Temporarily**
```yaml
with:
  run_tests: false
```

#### **Use Different Registry (GHCR instead of ECR)**
```yaml
docker-build:
  uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/docker-build.yaml@main
  with:
    image_name: my-org/my-app
    registry_type: generic
    registry_url: ghcr.io
  secrets:
    registry_username: ${{ github.actor }}
    registry_password: ${{ secrets.GITHUB_TOKEN }}
```

#### **Audit Mode (Don't Block on Findings)**
```yaml
sast-scan:
  uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/sast-semgrep.yaml@main
  with:
    fail_on_findings: false  # Report only, don't block
```

---

## 📋 **Common Patterns**

### **Pattern 1: Simple Build & Test**
Minimum viable CI for any project:
```yaml
jobs:
  build:
    uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/node-build.yaml@main
    with:
      run_tests: true
```

### **Pattern 2: Full Security Pipeline**
Comprehensive security scanning:
```yaml
jobs:
  build:
    uses: .../node-build.yaml@main
  
  sast:
    uses: .../sast-semgrep.yaml@main
  
  trivy:
    uses: .../trivy-scan.yaml@main
```

### **Pattern 3: Build → Scan → Deploy**
Production deployment pipeline:
```yaml
jobs:
  build:
    uses: .../node-build.yaml@main

  security:
    needs: build
    uses: .../sast-semgrep.yaml@main

  docker:
    needs: security
    if: github.ref == 'refs/heads/main'
    uses: .../docker-build.yaml@main

  deploy:
    needs: docker
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        run: # your deployment logic
```

---

## 🔐 **Required Secrets & Permissions**

### **For ECR Docker Builds**
Your workflow needs these permissions:
```yaml
permissions:
  id-token: write  # For AWS OIDC authentication
  contents: read
```

Configure AWS OIDC:
1. Create IAM role in AWS with trust policy for GitHub
2. Attach `AmazonEC2ContainerRegistryPowerUser` policy
3. Use role ARN in `role_to_assume` input

### **For GitHub Container Registry (GHCR)**
```yaml
permissions:
  packages: write
```

Use `GITHUB_TOKEN` secret (automatically available).

### **For Security Scanning**
```yaml
permissions:
  security-events: write  # For SARIF upload
```

---

## 💡 **Tips & Best Practices**

1. **Pin Workflow Versions**: Use `@main` for latest, or `@v1` for stability
2. **Use Branch Protection**: Make security scans required status checks
3. **Review Security Tab**: Regularly check GitHub Security tab for findings
4. **Customize Exclusions**: Use `exclude_paths` to skip vendor code
5. **Test Locally First**: Validate Terraform/Docker locally before pushing

---

## 📞 **Need Help?**

- See full documentation: [../docs/CI_FLOW.md](../docs/CI_FLOW.md)
- Open an issue in `devx-reusable-workflows` repository
- Contact DevOps team

---

**Last Updated:** 2025-12-15
