Redmine::Plugin.register :cosmosys_req do
  name 'cosmoSys-Req plugin'
  author 'cosmoBots.eu'
  description 'This plugin converts a Redmine server in a cosmSys-Req one'
  version '0.0.1'
  url 'http://cosmobots.eu/projects/csysreq/wiki'
  author_url 'http://cosmobots.eu/'


  permission :view_cosmosys, :cosmosys_reqs => :project_menu
  permission :tree_cosmosys, :cosmosys_reqs => :tree
  permission :download_cosmosys, :cosmosys_reqs => :download
  permission :dstopexport_cosmosys, :cosmosys_reqs => :dstopexport
  permission :dstopimport_cosmosys, :cosmosys_reqs => :dstopimport
  permission :propagate_cosmosys, :cosmosys_reqs => :propagate
  permission :report_cosmosys, :cosmosys_reqs => :report
  permission :upload_cosmosys, :cosmosys_reqs => :upload
  permission :validate_cosmosys, :cosmosys_reqs => :validate
  permission :create_repo, :cosmosys_reqs => :create_repo
  permission :show_cosmosys, :cosmosys_reqs => :show

  menu :project_menu, :cosmosys_reqs, {:controller => 'cosmosys_reqs', :action => 'project_menu' }, :caption => 'cosmoSys-Req', :after => :activity, :param => :id
  menu :project_menu, :cosmosys_req_tree, {:controller => 'cosmosys_reqs', :action => 'tree' }, :caption => 'ReqTree', :after => :issues, :param => :id
  menu :project_menu, :cosmosys_show, {:controller => 'cosmosys_reqs', :action => 'show' }, :caption => 'ReqShow', :after => :issues, :param => :id

  settings :default => {
    'repo_local_path' => "/home/cosmobots/repos/req_%project_id%",
    'repo_server_sync' => :false,
    'repo_server_path'  => 'http://gitlab.com/cosmobots/reqs/req_%project_id%.git',
    'repo_template_id'  => 'template',
    'repo_redmine_path' => "/home/cosmobots/repos_redmine/req_%project_id%.git",
    'repo_redmine_sync' => :true,
    'relative_uploadfile_path' => "uploading/RqUpload.ods",
    'relative_downloadfile_path' => "downloading/RqDownload.ods",
    'relative_reporting_path' => "reporting",
    'relative_img_path' => "reporting/doc/img"
  }, :partial => 'settings/cosmosys_req_settings'

  require 'cosmosys_req'
end
