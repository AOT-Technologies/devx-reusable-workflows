# Rollback Procedures

This document outlines how rollbacks work in the DevX CD Pipeline and how to perform them manually if necessary.

## Automated Rollback

The pipeline is designed to **automatically rollback** if a deployment fails or if post-deployment health checks fail.

### Configuration
Enable auto-rollback in `devx-config.yaml`:

```yaml
deployment:
  environments:
    production:
      auto_rollback: true
```

### How it Works
*   **EKS**: Uses `helm upgrade --atomic` to automatically revert if the upgrade fails or times out.
*   **ECS**: Changes the Service to use the *previous* Task Definition revision.
*   **EC2**:
    1.  The pipeline "snapshots" the currently running image URI before deploying.
    2.  If deployment fails, it triggers a new deployment using the saved "previous" image URI.

## Manual Rollback

If you need to roll back a successful deployment (e.g., due to a logic bug discovered later), follow these steps.

### Method 1: Re-deploy Previous Image (Recommended)

The safest way to rollback is to manually deploy the known-good image version.

1.  Find the **Image URI** of the previous stable version (check GitHub Actions history).
2.  Go to **Actions** -> **Orchestrator: CD Pipeline**.
3.  Click **Run workflow**.
4.  Select the **Environment**.
5.  Paste the **Old Image URI**.
6.  Run the workflow.

### Method 2: Platform-Specific Manual Rollback

#### EKS (Helm)
Connect to the cluster and run:
```bash
helm rollback <release-name> <revision> -n <namespace>
```

#### ECS
1.  Go to AWS Console -> ECS -> Service.
2.  Click **Update Service**.
3.  Select the **Task Definition** revision that was working previously.
4.  Update.

#### EC2
**Via SSM:**
```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=production" \
  --parameters "commands=['docker pull <old-image>', 'sed -i \"s|image: .*|image: <old-image>|\" docker-compose.yaml', 'docker-compose up -d']"
```
