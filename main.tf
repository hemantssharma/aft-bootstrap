terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket         = "my-terraform-state-bucket-aft-bootstrap"
    key            = "aft-bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "aft" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory"

  ct_management_account_id  = "767397915550"
  aft_management_account_id = "314431539167"
  ct_home_region            = "us-east-1"

  vcs_provider                                = "github"
  account_request_repo_name                   = "hemantssharma/aft-account-request"
  account_request_repo_branch                 = "main"
  global_customizations_repo_name             = "hemantssharma/aft-global-customizations"
  account_customizations_repo_name            = "hemantssharma/aft-account-customizations"
  account_provisioning_customizations_repo_name = "hemantssharma/aft-provisioning-customizations"
}
