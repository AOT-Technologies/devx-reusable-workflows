# -------------------------------------------------------------------------
# 1. Entry Points (The URLs)
# -------------------------------------------------------------------------
output "frontend_url" {
  description = "Frontend Access URL"
  value       = "https://${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "https://${var.backend_subdomain}.${data.aws_route53_zone.this.name}"
}

output "files_url" {
  description = "Public URL base for files"
  value       = "https://files.${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"
}

# -------------------------------------------------------------------------
# 2. Container & Compute Details (For CI/CD Pipelines)
# -------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "URL to push Docker images to"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.this.name
}

output "execution_role_arn" {
  description = "IAM Role for ECS Agent (Pull images/Push logs)"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "IAM Role for the App (S3 Access)"
  value       = aws_iam_role.task.arn
}

# -------------------------------------------------------------------------
# 3. Database Connection Info (For App Config)
# -------------------------------------------------------------------------
output "rds_endpoint" {
  description = "Postgres Endpoint (Host:Port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "Postgres Hostname only"
  value       = module.rds.db_instance_address
}

# -------------------------------------------------------------------------
# 4. Storage (For App Config)
# -------------------------------------------------------------------------
output "s3_bucket_name" {
  description = "Name of the S3 Bucket for file storage"
  value       = module.s3.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 Bucket"
  value       = module.s3.s3_bucket_arn
}

# -------------------------------------------------------------------------
# 5. Network Details (For Debugging / Bastion Hosts)
# -------------------------------------------------------------------------
output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of Public Subnet IDs (ALB lives here)"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of Private Subnet IDs (ECS lives here)"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of Database Subnet IDs (RDS lives here)"
  value       = module.vpc.database_subnets
}

# -------------------------------------------------------------------------
# 6. Security Groups (For Debugging Access Issues)
# -------------------------------------------------------------------------
output "alb_security_group_id" {
  description = "SG for Load Balancer"
  value       = module.alb.security_group_id
}

output "app_security_group_id" {
  description = "SG for ECS Task"
  value       = module.app_sg.security_group_id
}

output "db_security_group_id" {
  description = "SG for RDS"
  value       = module.db_sg.security_group_id
}
