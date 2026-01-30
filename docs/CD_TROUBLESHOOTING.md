# CD Pipeline Troubleshooting

Common issues and solutions for the DevX CD Pipeline.

## General Issues

### "Config file not found"
*   **Cause**: `devx-config.yaml` is missing from the repository root.
*   **Fix**: Ensure the file exists and is committed. Check the `config_path` input if using a custom location.

### "Invalid YAML syntax"
*   **Cause**: Syntax error in `devx-config.yaml`.
*   **Fix**: Use a YAML validator or `yq` to check the file structure.

## Deployment Failures

### EKS: "Release not found" / "Upgrade failed"
*   **Cause**: Helm could not connect to the cluster or chart is invalid.
*   **Fix**:
    *   Check `cluster_name` and `aws_region` config.
    *   Verify IAM Role permissions (OIDC).
    *   Check `helm_chart_path` exists.

### EC2: "SSM Command Failed"
*   **Cause**: Instance needs IAM Role with `AmazonSSMManagedInstanceCore`.
*   **Fix**: Attach the correct IAM policy to your EC2 instances. Ensure SSM Agent is running (`sudo systemctl status amazon-ssm-agent`).

### EC2: "SSH Connection Refused"
*   **Cause**: Security Group blocking port 22 or wrong key.
*   **Fix**:
    *   Allow Inbound 22 from GitHub Actions IPs (use a VPN or strictly scoped SG).
    *   Verify `SSH_PRIVATE_KEY` matches the public key in `~/.ssh/authorized_keys` on the instance.
    *   Check `ssh_user` (ubuntu vs ec2-user).

### ECS: "Service did not stabilize"
*   **Cause**: New task is failing health checks (flapping).
*   **Fix**: Check CloudWatch Logs for the container. The pipeline will timeout and likely rollback.

## Health Check Failures

### "CrashLoopBackOff detected"
*   **Cause**: Application is crashing on startup.
*   **Action**: Pipeline will trigger rollback. Check application logs.

### "HTTP 503 Service Unavailable"
*   **Cause**: Application not ready or load balancer issues.
*   **Fix**: Increase `initialDelaySeconds` in Kubernetes probes or adjust `wait_for_stability` settings.
