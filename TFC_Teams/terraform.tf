# ...

# Team 2: admins
resource "tfe_team" "admins" {
  organization = tfe_organization.example_org.name
  name         = "admins"
  
  project_permission = "manage"
  workspace_permission = "manage"
  settings_permission = "write_except_tasks_membership"
  registry_permission = "modules_providers"
}

# Add members xx1 and xx2 to the admins team
resource "tfe_team_member" "admin_member_xx1" {
  team_id  = tfe_team.admins.id
  username = "xx1"
  access   = "member"
}

resource "tfe_team_member" "admin_member_xx2" {
  team_id  = tfe_team.admins.id
  username = "xx2"
  access   = "member"
}

# Team 4: org_developer
resource "tfe_team" "org_developer" {
  organization = tfe_organization.example_org.name
  name         = "org_developer"
  
  project_permission = "read"
  workspace_permission = "read"
  settings_permission = "write_except_policies_vcs"
  registry_permission = "none"
}

# Add members yy1 and yy2 to the org_developer team
resource "tfe_team_member" "org_developer_member_yy1" {
  team_id  = tfe_team.org_developer.id
  username = "yy1"
  access   = "member"
}

resource "tfe_team_member" "org_developer_member_yy2" {
  team_id  = tfe_team.org_developer.id
  username = "yy2"
  access   = "member"
}

# Team 5: any_other_team
resource "tfe_team" "any_other_team" {
  organization = tfe_organization.example_org.name
  name         = "any_other_team"
  
  project_permission = "none"
  workspace_permission = "none"
  settings_permission = "none"
  registry_permission = "none"
}
