# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'csys_req/:id/zombie', :to => 'csys_req#zombie'
post 'csys_req/:id/erase', :to => 'csys_req#erase'
post 'csys_req/:id/derive', :to => 'csys_req#derive'
post 'csys_req/:id/clone', :to => 'csys_req#clone'
get 'csys_req/:id', :to => 'csys_req#show'
get 'csys_req/:id/menu', :to => 'csys_req#menu'
get 'csys_req/compmatrix/:id', :to => 'csys_req#compmatrix'
get 'csys_req/refdocs/:id', :to => 'csys_req#refdocs'
get 'csys_req/apldocs/:id', :to => 'csys_req#apldocs'
get 'csys_req/compdocs/:id', :to => 'csys_req#compdocs'
