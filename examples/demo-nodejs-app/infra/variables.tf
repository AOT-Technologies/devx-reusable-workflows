# --- General ---
variable "aws_region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS Region to deploy to"
}

variable "project" {
  type        = string
  default     = "dexterra"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "branch_name" {
  type        = string
  default     = "main"
}

# --- Database ---
variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database master username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database master password"
}

# --- App Config ---
variable "jwt_secret" {
  type        = string
  sensitive   = true
}

# --- GitHub / Amplify ---
variable "github_repository" {
  description = "URL of the github repo"
}

variable "github_token" {
  description = "GitHub Personal Access Token for Amplify"
  sensitive   = true
}

# --- DNS Configuration ---
variable "hosted_zone_id" {
  type        = string
  description = "The specific Route53 Hosted Zone ID (e.g. Z1234567890ABC)"
}

variable "frontend_subdomain" {
  type        = string
  default     = "facilityiq" # URL: https://facilityiq.aot-technologies.com
}

variable "backend_subdomain" {
  type        = string
  default     = "facilityiq-api" # URL: https://facilityiq-api.aot-technologies.com
}

# --- Image ---
variable "image_uri" {
  description = "Docker image URI (optional override)"
  type        = string
  default     = "" 
}

# --- Common Tags ---
variable "common_tags" {
  type = map(string)
  default = {
    Project   = "Dexterra"
    Terraform = "true"
  }
}

# --- Third Party APIs ---
variable "openroute_api_key" {
  type        = string
  sensitive   = true
  description = "API Key for OpenRoute Service"
}

variable "openai_api_key" {
  type        = string
  sensitive   = true
  description = "API Key for OpenAI"
}