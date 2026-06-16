# IDENTITY STORE USER
resource "aws_identitystore_user" "this" {
  for_each          = var.users
  identity_store_id = local.identity_store_id
  display_name      = coalesce(each.value.display_name, "${each.value.given_name} ${each.value.family_name}")
  user_name         = each.key
  name {
    family_name = each.value.family_name
    given_name  = each.value.given_name
  }
  emails {
    value = each.key
  }
}

# IDENTITY STORE GROUP
resource "aws_identitystore_group" "this" {
  for_each          = var.groups
  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}

# IDENTITY STORE GROUP MEMBERSHIP
resource "aws_identitystore_group_membership" "this" {
  for_each          = local.memberships
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = aws_identitystore_user.this[each.value.member].user_id
}

# PERMISSION SET
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = var.permission_sets
  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = local.managed_policy_attachments
  instance_arn       = local.instance_arn
  managed_policy_arn = each.value.arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.name].arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each           = local.inline_policies
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value
}

# ACCOUNT ASSIGNMENT
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = aws_identitystore_group.this[each.value.group].group_id
  principal_type = "GROUP"

  target_id   = var.accounts[each.value.account]
  target_type = "AWS_ACCOUNT"
}
