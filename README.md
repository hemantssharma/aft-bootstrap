Perfect 🚀 — let’s build **5 ready-to-use repo skeletons**. Each repo will contain the minimum Terraform + GitHub Actions workflow you need to get started. You can fork them into your GitHub org, update account IDs, and push.
 
---
 
# 🔹 1. `aft-bootstrap` (deploy the AFT framework)
 
**Repo structure:**
 
```
aft-bootstrap/
├─ main.tf
├─ versions.tf
├─ variables.tf
└─ .github/workflows/deploy.yml
```
 
**main.tf**
 
```hcl
# I hope this time it should work

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
```
 
**.github/workflows/deploy.yml**
 
```yaml
name: Deploy AFT Bootstrap
 
on:
  push:
    branches: [ "main" ]
    paths:
      - 'terraform/**.tf'
 
permissions:
  id-token: write
  contents: read
 
jobs:
  terraform:
    runs-on: ubuntu-latest
 
    steps:
      - name: Checkout
        uses: actions/checkout@v4
 
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::314431539167:role/AFTGitHubRole
          aws-region: us-east-1
 
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.5
 
      - name: Terraform Init
        run: terraform init -reconfigure

      - name: Import existing DynamoDB table
        run: terraform import module.aft.module.aft_backend.aws_dynamodb_table.lock-table aft-backend-314431539167 || true

      - name: Import existing IAM Roles
        run: |
          terraform import module.aft.module.aft_iam_roles.module.ct_management_exec_role.aws_iam_role.role AWSAFTExecution || true
          terraform import module.aft.module.aft_iam_roles.module.ct_management_service_role.aws_iam_role.role AWSAFTService || true
 
      - name: Terraform Validate
        run: terraform validate
 
      - name: Terraform Plan
        run: terraform plan -out=tfplan
 
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
```
 
---
 
# 🔹 2. `aft-account-request` (declare new accounts)
 
**Repo structure:**
 
```
aft-account-request/
├─ terraform/
│ └─ dev-team1.tf
└─ .github/workflows/apply.yml
```
 
**terraform/dev-team1.tf**
 
```hcl
module "dev_team1" {
  source  = "aws-ia/control-tower-account-factory-request/aws"
  version = "1.3.3"

  control_tower_parameters = {
    AccountEmail              = "mr.hemantksharma+devaccount-3@gmail.com"
    AccountName               = "devaccount-3"
    ManagedOrganizationalUnit = "Sandbox"
    SSOUserEmail              = "mr.hemantksharma+devaccount-3@gmail.com"
    SSOUserFirstName          = "Dev"
    SSOUserLastName           = "Account-3"
  }

  account_tags = {
    owner = "Dev"
    env   = "sandbox"
  }
}
}

```
 
**.github/workflows/apply.yml**
 
```yaml
name: Apply Account Requests
on:
  push:
    branches: [ "main" ]
    paths:
      - 'terraform/**.tf'
permissions:
  id-token: write

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: terraform   # 👈 important! point to your terraform folder

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.7

      - name: Terraform Init
        run: terraform init -upgrade

      - name: Terraform Plan
        run: terraform plan

      - name: Terraform Apply
        run: terraform apply -auto-approve
```
 
---
 
# 🔹 3. `aft-global-customizations` (applies everywhere)
 
**Repo structure:**
 
```
aft-global-customizations/
├─ terraform/
│ └─ main.tf
└─ .github/workflows/apply.yml
```
 
**terraform/main.tf**
 
```hcl
# Example: enable GuardDuty in all accounts
resource "aws_guardduty_detector" "this" {
  enable = true
}
```
 
**.github/workflows/apply.yml** (same as account-request but runs on all changes)
 
```yaml
name: Apply Global Customizations
on:
  push:
    branches: [ "main" ]
 
jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
 
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::314431539167:role/AFTGitHubRole
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform apply -auto-approve
```
 
---
 
# 🔹 4. `aft-account-customizations` (per-account extras)
 
**Repo structure:**
 
```
aft-account-customizations/
├─ dev-team1/
│ └─ main.tf
└─ .github/workflows/apply.yml
```
 
**dev-team1/main.tf**
 
```hcl
# Example: create IAM role in dev-team1 account
resource "aws_iam_role" "dev_role" {
  name = "DevTeam1Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::767397915550:root" }
      Action = "sts:AssumeRole"
    }]
  })
}
```
 
---
 
# 🔹 5. `aft-provisioning-customizations` (advanced tweaks)
 
**Repo structure:**
 
```
aft-provisioning-customizations/
└─ terraform/
└─ main.tf
```
 
**terraform/main.tf**
 
```hcl
# Example placeholder - advanced provisioning hooks
output "provisioning" {
  value = "Custom provisioning logic goes here"
}
```
 
---
 
# 🔹 How they all connect
 
* `aft-bootstrap` → deploys AFT into your **AFT management account**.
* AFT is configured (via bootstrap) to watch your 4 GitHub repos.
* When you push:
 
  * `aft-account-request` → provisions new AWS accounts.
  * `aft-global-customizations` → runs in *all* accounts.
  * `aft-account-customizations` → runs in specific accounts.
  * `aft-provisioning-customizations` → modifies how provisioning happens.
 
---
 
⚡ Next Step for You:
Fork/create these repos in your GitHub org.
Update:
 
* `ct_management_account_id: 767397915550`
* `aft_management_account_id: 314431539167`
* `your-github-user: hemantssharma` in repo names
* OIDC IAM role ARNs
 
Then trigger `Deploy AFT` workflow in **`aft-bootstrap`** to wire everything together.
 
---

```hcl
# IAM role AFTGitHubRole trust-relationship 
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::314431539167:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:hemantssharma/aft-bootstrap:*",
                        "repo:hemantssharma/aft-account-request:*",
                        "repo:hemantssharma/aft-global-customizations:*",
                        "repo:hemantssharma/aft-account-customizations:*",
                        "repo:hemantssharma/aft-provisioning-customizations:*"
                    ]
                }
            }
        }
    ]
}
```
