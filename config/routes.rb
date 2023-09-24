# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'csys_req/:id/derive', :to => 'csys_req#derive'
post 'csys_req/:id/clone', :to => 'csys_req#clone'
get 'csys_req/:id/menu', :to => 'csys_req#menu'
get 'csys_req/:id', :to => 'csys_req#show'