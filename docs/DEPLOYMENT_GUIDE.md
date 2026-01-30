# Deployment Guide

This guide details how to deploy applications using the DevX CD Pipeline.

## Prerequisites

1.  **GitHub Secrets Configured**:
    *   `AWS_ROLE_ARN`: IAM Role for OIDC.
    *   `GOOGLE_CHAT_WEBHOOK`: For notifications.
    *   `SSH_PRIVATE_KEY`: (Only for EC2 SSH deployment).
2.  **DevX Config**: `devx-config.yaml` present in the repository root.
3.  **Permissions**: User must have 'Write' access to the repository Actions.

## Triggering a Deployment

### 1. Automatic Deployment (CI/CD)

Deployments are typically triggered automatically after a successful CI build (on `main` branch push).
Ensure your CI workflow calls the CD orchestrator:

```yaml
  cd-deploy:
    needs: ci-build
    uses: ./.github/workflows/cd-orchestrator.yaml
    with:
      environment: dev
      image_uri: ${{ needs.ci-build.outputs.image_uri }}
```

### 2. Manual Deployment (Workflow Dispatch)

You can manually trigger a deployment from the GitHub Actions tab.

1.  Go to **Actions** tab in your repository.
2.  Select **Orchestrator: CD Pipeline**.
3.  Click **Run workflow**.
4.  Select the **Branch** (usually `main`).
5.  Fill in the inputs:
    *   **Environment**: Select `dev`, `qa`, `staging`, or `production`.
    *   **Image URI**: Full URI (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0`).
6.  Click **Run workflow**.

## Deployment Lifecycle

1.  **Validation**: Inputs and `devx-config.yaml` are validated.
2.  **Notification**: "Starting" message sent to Google Chat.
3.  **Deployment**:
    *   **EKS**: Helm upgrade with atomic rollback support.
    *   **EC2**: Docker Compose update via SSM or SSH. Pre-deployment state saved for rollback.
    *   **ECS**: Task Definition update and Service stability wait.
4.  **Health Check**: Verifies application health (HTTP/K8s/TCP).
5.  **Rollback** (If failure): Automatically triggers if `auto_rollback: true`.
6.  **Summary**: Final status report and notification.

## Verifying Success

1.  Check the **GitHub Actions Run** logs.
2.  Look for the **CD Pipeline Summary** at the bottom of the run page.
3.  Check **Google Chat** for the success notification.

## Troubleshooting

See [CD_TROUBLESHOOTING.md](./CD_TROUBLESHOOTING.md) for common issues.
