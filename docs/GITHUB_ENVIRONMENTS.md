# GitHub Environments Setup

This guide explains how to set up GitHub Environments to secure your deployments.

## Why Use Environments?
*   **Protection Rules**: Require manual approval for Production.
*   **Secrets Isolation**: Different secrets (e.g., SSH keys) for Dev vs. Prod.
*   **Deployment History**: improved UI for tracking deployments.

## Setup Steps

1.  Go to your GitHub Repository -> **Settings**.
2.  Select **Environments** from the sidebar.
3.  Click **New environment**.

### Recommended Environments
Create the following environments matching your `devx-config.yaml`:
*   `dev`
*   `qa`
*   `staging`
*   `production`

### Configuring Protection Rules (Production)

For the `production` environment:
1.  Enable **Required reviewers**.
2.  Select senior team members or DevOps engineers.
3.  (Optional) Set **Deployment branches** to restrict deployment only from `main`.

### Configuring Secrets

If you have environment-specific secrets (like distinct SSH keys for EC2), add them here instead of Repository Secrets.

*   `SSH_PRIVATE_KEY`
*   `GOOGLE_CHAT_WEBHOOK` (if different per env)

The pipeline automatically picks up Environment Secrets when running in that environment context.
