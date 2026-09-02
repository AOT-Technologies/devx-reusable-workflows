# Changelog

All notable changes to the DevX reusable workflows are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this repository adheres to [Semantic Versioning](https://semver.org/). Consumers
should pin to an immutable `vX.Y.Z` tag; the `vX` alias moves with each release
in that major line.

## [Unreleased]

## [1.1.0]

Maintainability and security hardening pass. No interface was removed or
renamed, so this is backwards compatible for existing callers.

### Fixed

- **`cd-orchestrator`: `ingress_domain` and `image_pull_secret` were always
  empty.** Both were written to `$GITHUB_OUTPUT` by the `extract` step and read
  by three downstream jobs, but neither was declared in `validate-and-load`'s
  `outputs:` map, so both resolved to `""`. EKS deployments received no image
  pull secret (`ImagePullBackOff` against private registries) and no application
  URL was produced for EKS, EC2 or the health check.
- **`cd-orchestrator`: the health check never ran after a `patch`-method EKS
  deployment.** `health-check` tested `needs.deploy-eks-patch.result` without
  listing `deploy-eks-patch` in its `needs:`, so the condition could never be
  true and the URL fallback was dead.
- **`cd-orchestrator`: the `k8s` deployment target was broken end to end.**
  `secrets.KUBECONFIG_DATA` was passed to `deploy-k8s` and `health-check` but
  never declared in `on.workflow_call.secrets`; `deploy-k8s` declared no
  workflow outputs while `needs.deploy-k8s.outputs.url` was consumed; and
  `deploy-k8s` was absent from `notify-result`, so a successful k8s deployment
  reported failure.
- **`deploy-ecs`: no `url` output** despite `cd-orchestrator` consuming
  `needs.deploy-ecs.outputs.url`, leaving the ECS health check with no target.
- **`deploy-eks` / `deploy-k8s`: image references were split on the first `:`,**
  which mis-parsed registries carrying an explicit port (`host:5000/img:tag`)
  and digest references (`img@sha256:…`).
- `cd-orchestrator`: the `k8s` branch of the config extractor did not read
  `helm.values_file` or `atomic`, so both were silently dropped.

### Security

- **Removed the shell-injection surface across all workflows.** No `run:` block
  interpolates `${{ … }}` any more; 290 expressions across 82 steps now pass
  through step-level `env:` and are read as `"$VAR"`, so a value can no longer
  be spliced into the script as code.
- **Replaced command-string construction with argv arrays** in `deploy-eks`,
  `deploy-ecs` and `deploy-k8s`. `deploy-eks` previously built a Helm command
  into a job output and re-parsed it; `deploy-ecs` used `eval`.
- **Pinned every third-party action to a full commit SHA** (63 references),
  with the version retained as a trailing comment. This removes the mutable-tag
  supply-chain risk and normalises inconsistent pinning (`@v4` vs `@v4.0.2`).
- **Replaced three actions pinned to `@master`** — `sonarqube-scan-action`,
  `sonarqube-quality-gate-action` and the deprecated `sonarcloud-github-action`
  — with pinned releases, unifying on `sonarqube-scan-action`.
- **Stopped passing the Sonar token as a command-line flag** in the Maven
  analysis step, where it was visible in `ps` output and Maven debug logs.
  `SONAR_TOKEN` was already exported for the step.
- **Pinned the Grype installer to its release tag** instead of fetching
  `install.sh` from the mutable `main` branch and piping it to `sh` as root.
- **Dropped `actions: write` from six workflows** to `actions: read`. The scope
  was justified in comments as required for artifact uploads, which is not the
  case; it also permits cancelling runs and deleting artifacts and logs.
- **Scoped `contents: write` to the `auto-merge` job alone** rather than
  granting it across the CI pipeline.
- `azure/setup-helm` moved from v3 (Node 16, end of life) to v4.
- Added `permissions:` and `timeout-minutes` to `deploy-k8s` and `auto-merge`,
  which had neither, and input validation to `auto-merge`'s `merge_method`.

### Added

- `repo-ci.yaml` — this repository now validates itself on every pull request:
  actionlint with shellcheck, the contract validator, example-config parsing,
  and a check that no real AWS account or tunnel hostname appears in `examples/`.
- `.github/scripts/validate_workflows.py` — static validation of the contracts
  *between* workflows. Catches every "Fixed" item above, all of which GitHub
  reports at run time as an empty string rather than as an error.
- `release.yaml` — cuts an immutable `vX.Y.Z` tag and moves the `vX` alias.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, `dependabot.yml`,
  `.gitignore`, `.gitattributes`, `.editorconfig`.
- `deploy-ecs`: `ingress_domain` input and a `url` output resolved from the
  service's load balancer.
- `deploy-k8s`: `helm_values_file`, `ingress_domain` and `dry_run` inputs;
  `status` and `url` outputs; chart validation and post-deploy verification.

### Changed

- **Scrubbed the public examples.** `examples/demo-*` carried a real AWS account
  ID and IAM role ARN, plus live Cloudflare-tunnel and ngrok hostnames for an
  internal Nexus, across 18 files in a public repository. All replaced with
  documented placeholders, and CI now fails if either reappears. The values
  remain in git history; the affected IAM role's OIDC trust policy should be
  reviewed and the tunnels are ephemeral and already expired.
- Added the required `permissions:` block to the Node.js and Python example
  callers, which lacked one — with a default-read token, OIDC and SARIF upload
  would have failed there while the Maven example worked.
- `demo-nodejs-app/cd.yaml`: `image_uri` is now required. It was documented as
  optional ("uses latest from Nexus if empty"), which was never implemented and
  produced a confusing mid-pipeline validation error.

### Removed

- Committed build output (`old-examples-made-for-reference/java-springboot/target/`)
  and three `*.bak` configuration files, two of which still carried the real
  AWS account ID.

## [1.0.0]

Initial release: CI and CD orchestrators driven by `devx-ci.yaml` /
`devx-config.yaml`, language build modules (Node, Python, Maven) with Nexus
upload, Docker build and push, deployment modules for EKS, ECS, EC2 and generic
Kubernetes, security scanning (Semgrep, SonarQube, Trivy, Checkov, Syft, Grype),
health checks, rollback and Google Chat notifications.

[Unreleased]: https://github.com/AOT-Technologies/devx-reusable-workflows/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/AOT-Technologies/devx-reusable-workflows/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/AOT-Technologies/devx-reusable-workflows/releases/tag/v1.0.0
