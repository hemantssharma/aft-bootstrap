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

resource "aws_dynamodb_table_replica" "lock-table-replica" {
  # ... config
 
  lifecycle {
    ignore_changes = all
  }
}
 
module "aft" {
  source  = "aws-ia/control_tower_account_factory/aws"
  version = "1.10.1" # upgrade to latest
 
  # Required inputs
  ct_management_account_id  = "767397915550"   # Control Tower Mgmt
  aft_management_account_id = "314431539167"   # AFT Mgmt
  ct_home_region            = "us-east-1"
  audit_account_id            = "753862336665" # <--- replace with your real Audit account
  log_archive_account_id      = "844840482771" # <--- replace with your real Log Archive account
  tf_backend_secondary_region = "us-west-2"    # <--- choose secondary region for backend
 
  # AFT repos (update with your GitHub org/user)
  vcs_provider                                = "github"
  account_request_repo_name                   = "hemantssharma/aft-account-request"
  account_request_repo_branch                 = "main"
  global_customizations_repo_name             = "hemantssharma/aft-global-customizations"
  account_customizations_repo_name            = "hemantssharma/aft-account-customizations"
  account_provisioning_customizations_repo_name = "hemantssharma/aft-provisioning-customizations"
 
}
