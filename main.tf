# I hope this time it should work.

terraform {
  required_version = ">= 1.6.0"
 
  backend "s3" {
    bucket         = "my-terraform-state-bucket--aftbootstrap"
    key            = "aft-bootstrap/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "my-terraform-locks"
  }
}
 
provider "aws" {
  region = "ap-south-1"
}

 
module "aft" {
  source  = "aws-ia/control_tower_account_factory/aws"
  version = "1.10.1" # upgrade to latest
 
  # Required inputs
  ct_management_account_id  = "429712912679"   # Control Tower Mgmt
  aft_management_account_id = "803356297187"   # AFT Mgmt
  ct_home_region            = "us-east-1"
  audit_account_id            = "096693758097" # <--- replace with your real Audit account
  log_archive_account_id      = "395298787173" # <--- replace with your real Log Archive account
  tf_backend_secondary_region = "us-west-2"    # <--- choose secondary region for backend
 
  # AFT repos (update with your GitHub org/user)
  vcs_provider                                = "github"
  account_request_repo_name                   = "hemantssharma/aft-account-request"
  account_request_repo_branch                 = "main"
  global_customizations_repo_name             = "hemantssharma/aft-global-customizations"
  account_customizations_repo_name            = "hemantssharma/aft-account-customizations"
  account_provisioning_customizations_repo_name = "hemantssharma/aft-provisioning-customizations"
 
}
