terraform {
  backend "s3" {
    bucket         = "aot-terraform-state-bucket"
    dynamodb_table = "aot-terraform-locks"
    encrypt        = true
    # key and region will be passed via CLI (key = "dexterra/${terraform.workspace}/terraform.tfstate", region = ca-central-1) using terraform init -backend-config=backend.conf
  }
}