# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

module CosmosysReq
  module Hooks
    class ModelIssueHook < Redmine::Hook::ViewListener

      render_on :view_projects_show_left, :partial => "cosmosys_reqs/project_overview" 
      #render_on :view_projects_show_right, :partial => "cosmosys_reqs/project_overview_sidebar" 
      render_on :view_issues_show_description_bottom, :partial => "cosmosys_reqs/issues" 

    end
  end
end
