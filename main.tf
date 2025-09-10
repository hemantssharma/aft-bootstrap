terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket         = "my-terraform-state-bucket-aftbootstrap"
    key            = "aft-bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "aft" {
  source  = "aws-ia/control_tower_account_factory/aws"
  version = "1.7.0"   # 👈 always pin a version 

  ct_management_account_id  = "767397915550"   # Control Tower Mgmt
  aft_management_account_id = "314431539167"   # AFT Mgmt
  ct_home_region            = "us-east-1"

  # 👇 Add these required variables
  audit_account_id           = "753862336665"
  log_archive_account_id     = "844840482771"
  tf_backend_secondary_region = "us-west-2"   # or another CT-supported region

  vcs_provider                                = "github"
  account_request_repo_name                   = "hemantssharma/aft-account-request"
  account_request_repo_branch                 = "main"
  global_customizations_repo_name             = "hemantssharma/aft-global-customizations"
  account_customizations_repo_name            = "hemantssharma/aft-account-customizations"
  account_provisioning_customizations_repo_name = "hemantssharma/aft-provisioning-customizations"
}
