#Pull workspaces by tags and apply variable sets to targeted groups of workspaces.
#data "tfe_workspace_ids" "uswest2" {
#  tag_names    = ["aws", var.aws_default_region]
#  organization = var.organization
#}
#resource "tfe_variable_set" "cloud_creds" {
#  name          = "AWS_Cloud_Credentials"
#  description   = "AWS Creds for child workspaces in ${var.aws_default_region} to inherit"
#  organization  = var.organization
#  workspace_ids = values(data.tfe_workspace_ids.uswest2.ids)
#}
resource "tfe_variable_set" "cloud_creds" {
  name         = "AWS_Cloud_Credentials"
  description  = "AWS Creds for child workspaces to inherit"
  organization = var.organization
}
resource "tfe_variable" "aws_access_key_id" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = var.aws_access_key_id
  category        = "env"
  description     = "uswest2 AWS access key id"
  variable_set_id = tfe_variable_set.cloud_creds.id
}
resource "tfe_variable" "aws_secret_access_key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  value           = var.aws_secret_access_key
  category        = "env"
  sensitive       = true
  description     = "uswest2 AWS secret access key"
  variable_set_id = tfe_variable_set.cloud_creds.id
}