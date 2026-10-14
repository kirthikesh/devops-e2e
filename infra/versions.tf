terraform {
  required_version = ">= 1.6"

  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.70" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }

  # Bucket comes from infra/backend.hcl (git-ignored), created by infra/bootstrap:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key            = "devops-e2e/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Owner     = "kirthikesh"
    }
  }
}
