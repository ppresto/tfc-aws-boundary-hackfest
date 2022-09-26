variable "organization" {}

variable "workspacename" {}
variable "queue_all_runs" { default = true }
variable "auto_apply" { default = true }
variable "tfversion" { default = "1.1.9" }
variable "workingdir" { default = "" }
variable "global_remote_state" { default = "" }

variable "oauth_token_id" {}
variable "repo_branch" { default = "main" }
variable "identifier" {}
variable "agent_pool_id" { default = "" }
variable "variable_set" { default = null }

# Terraform Variables
variable "tf_variables" {
  type = map(any)
  default = {
    prefix = "myproject"
  }
}
# Terraform Variables
variable "tf_variables_map" {
  default = {
    labels = { "prefix" = "myproject" }
  }
}

# Terraform HCL Variables
variable "tf_variables_sec" {
  type    = map(any)
  default = {}
}

# Env Variables
variable "env_variables" {
  type    = map(any)
  default = {}
}

# Env Variables
variable "env_variables_sec" {
  type    = map(any)
  default = {}
}

variable "tag_names" {
  type    = list(any)
  default = ["auto"]
}
# IAM Teams Map
#variable "teams_config" {
#  type = map
#  default = {}
#}