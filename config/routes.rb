# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'csys_req/:id/derive', :to => 'csys_req#derive'
post 'csys_req/:id/clone', :to => 'csys_req#clone'