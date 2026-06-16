locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  all_account_keys  = keys(var.accounts)

  memberships = {
    for pair in flatten([
      for group, members in var.groups : [
        for member in members.members : {
          group  = group
          member = member
        }
      ]
    ]) : "${pair.group}/${pair.member}" => pair
  }

  managed_policy_attachments = {
    for pair in flatten([
      for ps_key, ps in var.permission_sets : [
        for arn in coalesce(ps.managed_policies, []) : {
          name = ps_key
          arn  = arn
        }
      ]
    ]) : "${pair.name}/${pair.arn}" => pair
  }

  inline_policies = {
    for ps_key, ps in var.permission_sets :
    ps_key => ps.inline_policy
    if ps.inline_policy != null
  }

  assignment_rules = [
    for a in var.assignments : {
      group          = a.group
      permission_set = a.permission_set
      accounts = setsubtract(
        toset(distinct(concat(
          a.all_accounts ? local.all_account_keys : [],
          a.accounts,
          flatten([for ag in a.account_groups : lookup(var.account_groups, ag, [])]),
        ))),
        toset(a.exclude_accounts),
      )
    }
  ]

  assignments = merge([
    for r in local.assignment_rules : {
      for acct in r.accounts :
      "${r.group}:${r.permission_set}:${acct}" => {
        group          = r.group
        permission_set = r.permission_set
        account        = acct
      }
    }
  ]...)
}
