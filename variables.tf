variable "users" {
  description = "Map of users. KEY = email = user_name (matches NameID sent via SAML)."
  type = map(object({
    given_name   = string
    display_name = optional(string, "")
    family_name  = string
  }))
  default = {}
}

variable "groups" {
  description = "Map of groups. 'members' is a list of EMAILs (= keys of var.users)."
  type = map(object({
    description = optional(string, "")
    members     = list(string)
  }))
  default = {}
}

variable "permission_sets" {
  description = "Map of permission sets."
  type = map(object({
    description      = optional(string, "")
    session_duration = optional(string, "PT1H")
    managed_policies = optional(list(string), [])
    inline_policy    = optional(string)
  }))
  default = {}
}

variable "accounts" {
  description = "Map of account name => AWS account ID."
  type        = map(string)
}

variable "account_groups" {
  description = "Named groups of account keys, used in assignment rules."
  type        = map(list(string))
  default     = {}
}

variable "assignments" {
  description = "List of group-to-account assignment rules."
  type = list(object({
    group            = string
    permission_set   = string
    accounts         = optional(list(string), [])
    account_groups   = optional(list(string), [])
    all_accounts     = optional(bool, false)
    exclude_accounts = optional(list(string), [])
  }))
  default = []
}
