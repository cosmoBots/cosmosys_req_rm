module CosmosysReq
  module Hooks
    class ModelIssueHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, :partial => "cosmosys_req/issues" 
    end
  end
end