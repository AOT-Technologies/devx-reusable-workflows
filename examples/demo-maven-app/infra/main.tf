# 0. Get the Existing Hosted Zone
data "aws_route53_zone" "this" {
  zone_id = var.hosted_zone_id
}

# 1. GET AVAILABLE ZONES DYNAMICALLY
data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------------------------------------------------------------
# 0a. SSL Certificate for Backend API (ALB) - Regional (ca-central-1)
# -------------------------------------------------------------------------
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name       = "${var.backend_subdomain}.${data.aws_route53_zone.this.name}"
  zone_id           = data.aws_route53_zone.this.zone_id
  validation_method = "DNS"

  wait_for_validation = true
  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 0b. SSL Certificate for CloudFront CDN (Files) - Global (us-east-1)
#     CRITICAL: CloudFront REQUIRES certs in us-east-1
# -------------------------------------------------------------------------
module "acm_cloudfront" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name       = "files.${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"
  zone_id           = data.aws_route53_zone.this.zone_id
  validation_method = "DNS"

  wait_for_validation = true
  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 0c. DNS Record for Backend API
# -------------------------------------------------------------------------
resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.backend_subdomain}.${data.aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

# -------------------------------------------------------------------------
# 1. VPC (Foundation)
# -------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_max_aggregation_interval    = 60

  manage_default_security_group = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 2. Security Groups
# -------------------------------------------------------------------------
module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project}-app-sg"
  vpc_id      = module.vpc.vpc_id
  
  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  egress_rules = ["all-all"]
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project}-db-sg"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]
  
  # Developer Access (Public IP Whitelist - replace 0.0.0.0/0 with Office IP)
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Dev Team Access"
      cidr_blocks = "0.0.0.0/0" 
    }
  ]
}

# -------------------------------------------------------------------------
# 3. Application Load Balancer
# -------------------------------------------------------------------------
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "${var.project}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  create_security_group = true
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http_redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = module.acm.acm_certificate_arn
      forward         = { target_group_key = "backend" }
    }
  }

  target_groups = {
    backend = {
      name              = "${var.project}-tg"
      protocol          = "HTTP"
      port              = 3000
      target_type       = "ip"
      create_attachment = false
      health_check = {
        path    = "/api/health"
        matcher = "200"
      }
    }
  }
  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 4. ECR (Docker Registry)
# -------------------------------------------------------------------------
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  repository_name = "${var.project}-backend"
  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection    = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 5. ECS Cluster & Service
# -------------------------------------------------------------------------
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"
  cluster_name = "${var.project}-cluster"
  
  cluster_settings = {
    "name": "containerInsights",
    "value": "enabled"
  }

  cloudwatch_log_group_retention_in_days = 365

  fargate_capacity_providers = {
    FARGATE = { default_capacity_provider_strategy = { weight = 100 } }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "public.ecr.aws/nginx/nginx:latest" 
      essential = true
      portMappings = [{ containerPort = 3000, protocol = "tcp" }]
      
      environment = [
        { name = "NODE_ENV",       value = "production" },
        { name = "PORT",           value = "3000" },
        { name = "DB_HOST",        value = module.rds.db_instance_address },
        { name = "DB_PORT",        value = "5432" },
        { name = "DB_NAME",        value = var.db_name },
        { name = "DB_USER",        value = var.db_username },
        { name = "DB_PASSWORD",    value = var.db_password },
        { name = "JWT_SECRET",     value = var.jwt_secret },
        { name = "FRONTEND_URL",   value = "https://${var.branch_name}.${aws_amplify_app.frontend.default_domain}" },
        
        { name = "CLOUDFRONT_URL", value = "https://files.${var.frontend_subdomain}.${data.aws_route53_zone.this.name}" },
        
        { name = "AWS_S3_BUCKET",  value = module.s3.s3_bucket_id },
        { name = "AWS_REGION",     value = var.aws_region },
        { name = "AWS_S3_ACL",     value = "private" },

        { name = "OPENROUTE_API_KEY", value = var.openroute_api_key },
        { name = "OPENAI_API_KEY",    value = var.openai_api_key },
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.project}-service"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.app_sg.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["backend"].arn
    container_name   = "backend"
    container_port   = 3000
  }
  
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# -------------------------------------------------------------------------
# 6. RDS (Database)
# -------------------------------------------------------------------------
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project}-db"
  engine     = "postgres"
  engine_version = "16"
  family     = "postgres16"
  major_engine_version = "16"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  vpc_security_group_ids = [module.db_sg.security_group_id]
  
  # Public Access for Devs
  subnet_ids             = module.vpc.public_subnets
  create_db_subnet_group = true
  publicly_accessible    = true 
  
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  manage_master_user_password_rotation = false # Disable for demo to avoid CKV_AWS_304
}

# -------------------------------------------------------------------------
# 7. Amplify (Frontend Hosting)
# -------------------------------------------------------------------------
resource "aws_amplify_app" "frontend" {
  name         = "${var.project}-frontend"
  repository   = var.github_repository
  access_token = var.github_token

  build_spec = <<-EOT
    version: 1
    applications:
      - frontend:
          phases:
            preBuild:
              commands:
                - cd poc-frontend
                - npm install
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: poc-frontend/dist
            files:
              - '**/*'
          cache:
            paths:
              - poc-frontend/node_modules/**/*
        appRoot: poc-frontend
  EOT

  environment_variables = {
    VITE_API_BASE_URL = "https://${var.backend_subdomain}.${data.aws_route53_zone.this.name}"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.branch_name
  enable_auto_build = true
}

resource "aws_iam_role" "execution" {
  name = "${var.project}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------------------------------------------------
# 7b. Amplify Custom Domain
# -------------------------------------------------------------------------
resource "aws_amplify_domain_association" "frontend" {
  app_id      = aws_amplify_app.frontend.id
  domain_name = "${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }
  wait_for_verification = false 
}

# -------------------------------------------------------------------------
# 8. S3 Bucket
# -------------------------------------------------------------------------
module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${var.project}-${var.environment}-files-"
  
  # Security Fixes
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = { enabled = true }

  lifecycle_rule = [
    {
      id      = "abort-failed-uploads"
      enabled = true
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  cors_rule = [
    {
      allowed_methods = ["PUT", "GET", "POST"]
      allowed_origins = [
        "https://${var.frontend_subdomain}.${data.aws_route53_zone.this.name}",
        "http://localhost:8000"
      ]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
  tags = var.common_tags
}

# -------------------------------------------------------------------------
# 9. Task Role
# -------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  name = "${var.project}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.project}-s3-policy"
  description = "Allow ECS to read/write S3"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [
          module.s3.s3_bucket_arn,
          "${module.s3.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# -------------------------------------------------------------------------
# 10. CloudFront (Public Read)
# -------------------------------------------------------------------------

# A. Origin Access Control
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project}-oac"
  description                       = "OAC for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# B. CloudFront Distribution
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.2"

  aliases = ["files.${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"]

  comment             = "File Distribution for ${var.project}"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = false
  
  origin = {
    s3_bucket = {
      domain_name              = module.s3.s3_bucket_bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_bucket"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }
  
  viewer_certificate = {
    # USES THE NEW CERTIFICATE
    acm_certificate_arn      = module.acm_cloudfront.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.common_tags
}

# C. Update S3 Policy
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = module.s3.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# D. DNS Record for Files
resource "aws_route53_record" "cloudfront" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "files.${var.frontend_subdomain}.${data.aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_distribution_domain_name
    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}