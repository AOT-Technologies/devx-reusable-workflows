# dexterra-infra

This repo contains the Terraform configuration to provision Dexterra infrastructure in AWS.

**Key resources created**
- VPC (2 AZs)
- Public/private subnets, NAT
- ALB (HTTP)
- ECS Fargate cluster and service (backend)
- RDS PostgreSQL
- S3 bucket (private)
- Amplify App & Branch (frontend auto-build)
- CloudWatch Log Group for ECS

**Usage**
1. Copy `terraform.tfvars.example` → `terraform.tfvars` and fill secrets (prefer CI secret injection).
2. `terraform init`
3. `terraform plan -var-file="terraform.tfvars"`
4. `terraform apply -var-file="terraform.tfvars"`

**Notes & best practices**
- Do not commit `terraform.tfvars` with secrets.
- For CI, prefer GitHub OIDC to assume an AWS role instead of long-lived keys.
- Run first in a sandbox AWS account.
