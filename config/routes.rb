# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'cosmosys_reqs', :to => 'cosmosys_reqs#index'
post 'cosmosys_reqs/:issue_id/validate', :to => 'cosmosys_reqs#validate'
get 'cosmosys_reqs/:project_id/project_menu', :to => 'cosmosys_reqs#project_menu'

get 'cosmosys_reqs/:project_id/create_repo', :to => 'cosmosys_reqs#create_repo'
get 'cosmosys_reqs/:project_id/upload', :to => 'cosmosys_reqs#upload'
get 'cosmosys_reqs/:project_id/download', :to => 'cosmosys_reqs#download'
get 'cosmosys_reqs/:project_id/dstopimport', :to => 'cosmosys_reqs#dstopimport'
get 'cosmosys_reqs/:project_id/dstopexport', :to => 'cosmosys_reqs#dstopexport'
get 'cosmosys_reqs/:project_id/report', :to => 'cosmosys_reqs#report'
get 'cosmosys_reqs/:project_id/validate', :to => 'cosmosys_reqs#validate'
get 'cosmosys_reqs/:project_id/propagate', :to => 'cosmosys_reqs#propagate'

post 'cosmosys_reqs/:project_id/create_repo', :to => 'cosmosys_reqs#create_repo'
post 'cosmosys_reqs/:project_id/upload', :to => 'cosmosys_reqs#upload'
post 'cosmosys_reqs/:project_id/download', :to => 'cosmosys_reqs#download'
post 'cosmosys_reqs/:project_id/dstopimport', :to => 'cosmosys_reqs#dstopimport'
post 'cosmosys_reqs/:project_id/dstopexport', :to => 'cosmosys_reqs#dstopexport'
post 'cosmosys_reqs/:project_id/report', :to => 'cosmosys_reqs#report'
post 'cosmosys_reqs/:project_id/validate', :to => 'cosmosys_reqs#validate'
post 'cosmosys_reqs/:project_id/propagate', :to => 'cosmosys_reqs#propagate'

