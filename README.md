# terraform-aws-identity-center

Terraform module to manage AWS IAM Identity Center (SSO): users, groups, permission sets, and account assignments.

## Usage

```hcl
module "identity_center" {
  source = "git::https://github.com/<your-org>/terraform-aws-identity-center.git?ref=v1.0.0"

  users = {
    "alice@example.com" = {
      given_name  = "Alice"
      family_name = "Smith"
    }
  }

  groups = {
    "SRE" = {
      description = "Site Reliability Engineers"
      members     = ["alice@example.com"]
    }
  }

  permission_sets = {
    "SRE_AdministratorAccess" = {
      description      = "Admin access for SRE"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }

    "DEV_S3BucketOnly" = {
      description      = "S3 access limited to a specific bucket"
      session_duration = "PT8H"
      inline_policy    = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
            Resource = ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
          }
        ]
      })
    }
  }

  accounts = {
    "management" = "111122223333"
    "production"  = "444455556666"
    "staging"     = "777788889999"
  }

  account_groups = {
    "non_prod" = ["staging"]
  }

  assignments = [
    # Assign to all accounts
    {
      group          = "SRE"
      permission_set = "SRE_AdministratorAccess"
      all_accounts   = true
    },

    # Assign to specific accounts only
    {
      group          = "DEV"
      permission_set = "DEV_S3BucketOnly"
      accounts       = ["staging"]
    },

    # Assign via account_group (named set of accounts)
    {
      group          = "Auditors"
      permission_set = "ReadOnlyAccess"
      account_groups = ["non_prod"]
    },

    # All accounts but exclude production
    {
      group            = "QA"
      permission_set   = "ReadOnlyAccess"
      all_accounts     = true
      exclude_accounts = ["production"]
    },

    # Mix: specific accounts + account_group, exclude one
    {
      group            = "Contractors"
      permission_set   = "ReadOnlyAccess"
      accounts         = ["management"]
      account_groups   = ["non_prod"]
      exclude_accounts = ["staging"]
    },
  ]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `users` | `map(object)` | `{}` | Map of email → user attributes |
| `groups` | `map(object)` | `{}` | Map of group name → members + description |
| `permission_sets` | `map(object)` | `{}` | Map of permission set name → policies |
| `accounts` | `map(string)` | required | Map of account alias → AWS account ID |
| `account_groups` | `map(list(string))` | `{}` | Named groups of account keys |
| `assignments` | `list(object)` | `[]` | Group-to-account assignment rules |

### Assignment rule fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `group` | `string` | required | Group name (must exist in `var.groups`) |
| `permission_set` | `string` | required | Permission set name (must exist in `var.permission_sets`) |
| `accounts` | `list(string)` | `[]` | Specific account keys to assign |
| `account_groups` | `list(string)` | `[]` | Named account groups to assign |
| `all_accounts` | `bool` | `false` | Assign to all accounts in `var.accounts` |
| `exclude_accounts` | `list(string)` | `[]` | Account keys to exclude from assignment |

## Outputs

| Name | Description |
|------|-------------|
| `user_ids` | Map of email → identity store user ID |
| `group_ids` | Map of group name → identity store group ID |
| `permission_set_arns` | Map of permission set name → ARN |
| `instance_arn` | ARN of the SSO instance |
| `identity_store_id` | ID of the Identity Store |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 5.0 |

The AWS provider must be configured by the caller (region `us-east-1` or where SSO is enabled).
