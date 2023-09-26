class AddEraseZombie < ActiveRecord::Migration[5.2]

	def ro_field(t,fn,r,s1,s2)
		WorkflowPermission.create!(:tracker_id => t,
			:role_id => r, :old_status_id => s1, 
			:new_status_id => s2, rule: "readonly",
			field_name: fn)
	end

  def up
    add_column :cosmosys_issues, :relations_on_close, :string
    
    rqtrck = Tracker.find_by_name('rq')

    manager = Role.find_by_name('rqMngr')
    writer = Role.find_by_name('rqWriter')
    reviewer = Role.find_by_name('rqReviewer')
    reader = Role.find_by_name('rqReader')

    write_roles = [manager,writer]
    write_permissions = [:csys_req_clone, :csys_req_erase,:csys_req_zombie]

    write_roles.each{|r|
      r.permissions += write_permissions
      r.save
    }

    # BEGIN This is a fix

    read_roles = [manager,writer,reviewer,reader]
    read_permissions = [:csys_req_menu, :csys_req_show]

    read_roles.each{|r|
      r.permissions += read_permissions
      r.save
    }
    # END This is a fix

  end

  def down
    remove_column :cosmosys_issues, :relations_on_close
  end

end
