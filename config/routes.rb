# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'cosmosys_reqs/:id/project_menu', :to => 'cosmosys_reqs#project_menu'

get 'cosmosys_reqs/:id/create_repo', :to => 'cosmosys_reqs#create_repo'
get 'cosmosys_reqs/:id/upload', :to => 'cosmosys_reqs#upload'
get 'cosmosys_reqs/:id/download', :to => 'cosmosys_reqs#download'
get 'cosmosys_reqs/:id/dstopimport', :to => 'cosmosys_reqs#dstopimport'
get 'cosmosys_reqs/:id/dstopexport', :to => 'cosmosys_reqs#dstopexport'
get 'cosmosys_reqs/:id/report', :to => 'cosmosys_reqs#report'
get 'cosmosys_reqs/:id/validate', :to => 'cosmosys_reqs#validate'
get 'cosmosys_reqs/:id/propagate', :to => 'cosmosys_reqs#propagate'
get 'cosmosys_reqs/:id/tree', :to => 'cosmosys_reqs#tree'

post 'cosmosys_reqs/:id/create_repo', :to => 'cosmosys_reqs#create_repo'
post 'cosmosys_reqs/:id/upload', :to => 'cosmosys_reqs#upload'
post 'cosmosys_reqs/:id/download', :to => 'cosmosys_reqs#download'
post 'cosmosys_reqs/:id/dstopimport', :to => 'cosmosys_reqs#dstopimport'
post 'cosmosys_reqs/:id/dstopexport', :to => 'cosmosys_reqs#dstopexport'
post 'cosmosys_reqs/:id/report', :to => 'cosmosys_reqs#report'
post 'cosmosys_reqs/:id/validate', :to => 'cosmosys_reqs#validate'
post 'cosmosys_reqs/:id/propagate', :to => 'cosmosys_reqs#propagate'
post 'cosmosys_reqs/:id/tree', :to => 'cosmosys_reqs#tree'

get 'cosmosys_reqs/:id/req_menu', :to => 'cosmosys_reqs#req_menu'

get 'cosmosys_reqs/:id/req_validate', :to => 'cosmosys_reqs#req_validate'
get 'cosmosys_reqs/:id/req_propagate', :to => 'cosmosys_reqs#req_propagate'
get 'cosmosys_reqs/:id/req_tree', :to => 'cosmosys_reqs#req_tree'

post 'cosmosys_reqs/:id/req_validate', :to => 'cosmosys_reqs#req_validate'
post 'cosmosys_reqs/:id/req_propagate', :to => 'cosmosys_reqs#req_propagate'
post 'cosmosys_reqs/:id/req_tree', :to => 'cosmosys_reqs#req_tree'
