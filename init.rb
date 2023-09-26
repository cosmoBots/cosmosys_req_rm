Redmine::Plugin.register :cosmosys_req do
  name 'Cosmosys Req plugin'
  author 'Txinto Vaz'
  description 'This is a plugin for Redmine, which converts a cosmoSys instance into a cosmoSys-Req instance'
  version '0.2.1'
  url 'http://cosmobots.eu'
  author_url 'http://cosmobots.eu'

  requires_redmine_plugin :cosmosys, :version_or_higher => '0.0.2'
  requires_redmine_plugin :cosmosys_git, :version_or_higher => '0.0.2'

  permission :csys_req_zombie, :csys_req => :zombie
  permission :csys_req_erase, :csys_req => :erase
  permission :csys_req_clone, :csys_req => :derive
  permission :csys_req_derive, :csys_req => :derive
  permission :csys_req_menu, :csys_req => :menu
  permission :csys_req_show, :csys_req => :show

  menu :project_menu, :csys_req, {:controller => 'csys_req', :action => 'menu' }, :caption => 'cosmoSysReq', :after => :activity, :param => :id


  require 'cosmosys_req'

  # Patches to the Redmine core.
  require 'cosmosys_issue_patch'
  require 'cosmosys_tracker_patch'
end
