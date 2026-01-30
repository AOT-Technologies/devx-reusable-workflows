# CD Configuration Reference: `devx-config.yaml`

This document provides a comprehensive reference for the `devx-config.yaml` configuration file used by the DevX CD Pipeline.

## Structure Overview

The configuration is divided into two main sections:
1.  `aws`: Global AWS settings.
2.  `deployment`: CD pipeline settings.

## Global AWS Settings

```yaml
aws:
  default_region: "us-east-1"  # Default AWS region for all operations
  role_to_assume: "arn:aws:iam::123456789012:role/GitHubActionsRole" # OIDC Role ARN
```

## Deployment Settings

### General Settings

```yaml
deployment:
  enabled: true             # Master switch for deployments
  target: "eks"             # Main deployment target (eks, ec2, ecs)
  notifications:
    enabled: true           # Enable Google Chat notifications
```

### Environment Configuration

Define settings for each environment (`dev`, `qa`, `staging`, `production`).

```yaml
deployment:
  environments:
    dev:
      enabled: true
      # ... target specific settings
    production:
      enabled: true
      auto_rollback: true   # Enable automatic rollback on failure
```

### Target-Specific Configuration

#### 1. EKS (Elastic Kubernetes Service)

```yaml
deployment:
  target: "eks"
  environments:
    dev:
      cluster_name: "dev-cluster"
      namespace: "app-dev"
      helm:
        chart_path: "./charts/app"
        release_name: "my-app"
        values_file: "./charts/app/values-dev.yaml"
        set_values: "image.tag=latest,replicaCount=1"
```

#### 2. EC2 (Elastic Compute Cloud)

**Method 1: SSM (Systems Manager) - Recommended**

```yaml
deployment:
  target: "ec2"
  environments:
    dev:
      deploy_method: "ssm"
      target_type: "tag"
      target_tag_key: "Environment"
      target_tag_value: "dev"
      docker_compose_path: "/app/docker-compose.yaml"
      service_name: "web"
```

**Method 2: SSH (Secure Shell)**

```yaml
deployment:
  target: "ec2"
  environments:
    dev:
      deploy_method: "ssh"
      ssh_user: "ubuntu"
      instance_ids: "i-0123456789abcdef0" # Optional: target specific instances
      target_type: "instance"
```

#### 3. ECS (Elastic Container Service)

```yaml
deployment:
  target: "ecs"
  environments:
    dev:
      cluster_name: "dev-cluster"
      service_name: "my-app-service"
      task_definition_family: "my-app-task"
      container_name: "app-container"
```

### Health Checks

Configure post-deployment verification.

```yaml
deployment:
  environments:
    dev:
      health_check:
        enabled: true
        type: "http"        # http, k8s, or tcp
        endpoint: "/health" # URL path for HTTP check
```

## Example Full Configuration

```yaml
aws:
  default_region: "us-east-1"

deployment:
  enabled: true
  target: "eks"
  
  notifications:
    enabled: true

  environments:
    dev:
      enabled: true
      cluster_name: "dev-cluster"
      namespace: "my-app"
      helm:
        chart_path: "./helm"
        release_name: "app-dev"
        values_file: "./helm/values-dev.yaml"
      health_check:
        type: "k8s"
        
    production:
      enabled: true
      cluster_name: "prod-cluster"
      namespace: "my-app"
      auto_rollback: true
      helm:
        chart_path: "./helm"
        release_name: "app-prod"
        values_file: "./helm/values-prod.yaml"
```
