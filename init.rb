Redmine::Plugin.register :cosmosys_req do
  name 'Cosmosys Req plugin'
  author 'Txinto Vaz'
  description 'This is a plugin for Redmine, which converts a cosmoSys instance into a cosmoSys-Req instance'
  version '0.2.0'
  url 'http://cosmobots.eu'
  author_url 'http://cosmobots.eu'

  requires_redmine_plugin :cosmosys, :version_or_higher => '0.0.2'
  requires_redmine_plugin :cosmosys_git, :version_or_higher => '0.0.2'

  require 'cosmosys_req'

  # Patches to the Redmine core.
  require 'cosmosys_issue_patch'  
end
