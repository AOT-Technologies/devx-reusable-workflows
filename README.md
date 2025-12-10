# DevX-reusable-workflows
A centralized collection of reusable GitHub Actions workflows across AOT projects

```
devx-reusable-workflows/
├── .github/
│   └── workflows/
│       ├── ci/
│       │   ├── node-ci.yaml
│       │   ├── python-ci.yaml
│       │   ├── maven-ci.yaml
│       │   ├── generic-ci.yaml
│       │   └── scan-only.yaml
│       ├── common/
│       │   ├── sbom-gen.yaml
│       │   ├── sast-runner.yaml
│       │   ├── sca-runner.yaml
│       │   ├── container-scan.yaml
│       │   ├── iac-scan.yaml
│       │   └── cache-setup.yaml
│       └── utilities/
│           ├── upload-artifacts.yaml
│           └── publish-metadata.yaml
├── examples/
│   ├── sample-node/
│   │   └── .github/workflows/ci.yml
│   ├── sample-python/
│   │   └── .github/workflows/ci.yml
│   └── sample-maven/
│       └── .github/workflows/ci.yml
├── docs/
│   ├── CI_FLOW.md
│   └── devx.config.schema.md
└── devx.config.yml.example
```