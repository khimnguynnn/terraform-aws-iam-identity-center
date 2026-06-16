output "user_ids" {
  description = "Map of email => identity store user ID."
  value       = { for k, v in aws_identitystore_user.this : k => v.user_id }
}

output "group_ids" {
  description = "Map of group name => identity store group ID."
  value       = { for k, v in aws_identitystore_group.this : k => v.group_id }
}

output "permission_set_arns" {
  description = "Map of permission set name => ARN."
  value       = { for k, v in aws_ssoadmin_permission_set.this : k => v.arn }
}

output "instance_arn" {
  description = "ARN of the SSO instance."
  value       = local.instance_arn
}

output "identity_store_id" {
  description = "ID of the Identity Store."
  value       = local.identity_store_id
}
