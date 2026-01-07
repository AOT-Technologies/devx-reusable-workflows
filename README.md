# DevX-reusable-workflows
A centralized collection of reusable GitHub Actions workflows across AOT projects

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