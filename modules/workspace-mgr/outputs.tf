output "workspace" {
  #value = var.workspacename
  value = tfe_workspace.ws-vcs.name
}
output "ws-id" {
  value = tfe_workspace.ws-vcs.id
}