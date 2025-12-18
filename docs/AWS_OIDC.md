# AWS OIDC Setup for DevX CI/CD

This document explains how to configure **AWS IAM OIDC trust** so GitHub Actions can push Docker images to **Amazon ECR** using **OIDC (no static credentials)**.

This is required **only if**:
- `docker.registry_type: ecr` is used in `devx-ci.yaml`

---

## Why OIDC?

- No long-lived AWS access keys
- Credentials are short-lived and auto-rotated
- Access is scoped per repository
- Industry best practice (AWS recommended)

---

## One-Time Setup (Per AWS Account)

### 1️⃣ Create GitHub OIDC Provider (If Not Already Present)

Check if this already exists:

```bash
aws iam list-open-id-connect-providers
```

If not present, create it:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

---

2️⃣ Create IAM Role for GitHub Actions

Create an IAM role with this exact trust policy, then attach ECR permissions.

🔐 Trust Policy

Replace:
- ORG_NAME
- REPO_NAME
- BRANCH_NAME (or remove branch condition if needed)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG_NAME/REPO_NAME:ref:refs/heads/BRANCH_NAME"
        }
      }
    }
  ]
}
```
---
Examples

Allow only main branch:
```yaml
"repo:aot-technologies/my-service:ref:refs/heads/main"
```

Allow any branch:
```yaml
"repo:aot-technologies/my-service:*"
```

Allow all repos in an org (use with caution):
```yaml
"repo:aot-technologies/*"
```
3️⃣ Attach ECR Permissions to the Role

Attach either:

Option A: AWS Managed Policy (Quickest)
```yaml
AmazonEC2ContainerRegistryPowerUser
```
Option B: Minimal Custom Policy (Recommended)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "*"
    }
  ]
}
```

4️⃣ Reference the Role in devx-ci.yaml
```yaml
docker:
  enabled: true
  registry_type: ecr
  image_name: my-service

aws:
  region: us-east-1
  role_to_assume: arn:aws:iam::123456789012:role/devx-github-actions
```
5️⃣ Required Workflow Permissions (Already Set)

Your reusable workflows already include:
```yaml
permissions:
  id-token: write
  contents: read
```

If id-token: write is missing, OIDC will not work.
---
Common Errors & Fixes

❌ Not authorized to perform sts:AssumeRoleWithWebIdentity
- Trust policy sub does not match repo or branch
- Repo name mismatch (case-sensitive)

❌ NoCredentialProviders
- id-token: write permission missing
- Role ARN incorrect

❌ ECR push fails but role is assumed
- Missing ecr:* permissions
- Wrong AWS region
---
Security Notes
- Prefer repo-scoped trust policies
- Avoid wildcard org access unless necessary
- Rotate role names per environment if needed

Never store AWS access keys in GitHub Secrets for CI
---
Summary
- No AWS keys
- Short-lived credentials
- Repo-scoped access
- Secure by default

Once configured, no further AWS changes are needed unless you add new repositories.