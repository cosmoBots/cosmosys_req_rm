class CreateCsysReqs < ActiveRecord::Migration[5.2]
  def up

    create_table :csys_reqs do |t|
      t.integer :cosmosys_issue_id, foreign_key: true      
    end
    add_index :csys_reqs, :cosmosys_issue_id

    ##### CREATE REDMINE OBJECTS
		# Roles
		manager = Role.create! :name => 'rqMngr',
		:issues_visibility => 'all',
		:users_visibility => 'all'
		manager.permissions = manager.setable_permissions.collect {|p| p.name}
		manager.save!

		writer = Role.create!  :name => 'rqWriter',
		:permissions => [
			:manage_versions,
			:manage_categories,
			:view_issues,
			:add_issues,
			:edit_issues,
			:view_private_notes,
			:set_notes_private,
			:manage_issue_relations,
			:manage_subtasks,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:edit_wiki_pages,
			:delete_wiki_pages,
			:view_files,
			:manage_files,
			:browse_repository,
			:view_changesets,
			:commit_access,
			:manage_related_issues,
			:csys_iss_index,
			:csys_down,
			:csys_up,
			:csys_show,
			:csys_treeview,
			:csys_tree,
			:csys_menu,
			:csys_git_menu,
			:csys_git_report
		]

    reviewer = Role.create! :name => 'rqReviewer',
		:permissions => [
			:view_issues,
			:edit_issues,			
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:view_files,
			:browse_repository,
			:view_changesets,
			:csys_iss_index,
			:csys_down,
			:csys_up,
			:csys_show,
			:csys_treeview,
			:csys_tree,
			:csys_menu,
			:csys_git_menu,
			:csys_git_report
		]


		reader = Role.create! :name => 'rqReader',
		:permissions => [:view_issues,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:view_files,
			:browse_repository,
			:view_changesets,

			:csys_iss_index,
			:csys_show,
			:csys_treeview,
			:csys_tree,
			:csys_menu
		]

		rqroles = [writer,reviewer,reader,manager]

		# Statuses
		stdraft = IssueStatus.create!(:name => 'rqDraft', :is_closed => false)
		ststable = IssueStatus.create!(:name => 'rqStable', :is_closed => false)
		stapproved = IssueStatus.create!(:name => 'rqApproved', :is_closed => false)
		strejected = IssueStatus.create!(:name => 'rqRejected', :is_closed => false)
		sterased = IssueStatus.create!(:name => 'rqErased', :is_closed => true)
		stzombie = IssueStatus.create!(:name => 'rqZombie', :is_closed => true)

		rqstatuses = [stdraft, ststable, stapproved, strejected, sterased, stzombie]

		t = Tracker.create!(:name => 'rq',    
			:default_status_id => stdraft.id, 
			:is_in_chlog => true,  :is_in_roadmap => true)    

    # Writer transitions
=begin	
		# Creemos que no hace falta	
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => 0, 
      :new_status_id => stdraft.id)
=end
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => stdraft.id, 
      :new_status_id => ststable.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => stdraft.id, 
      :new_status_id => sterased.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => stdraft.id, 
      :new_status_id => stzombie.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => ststable.id, 
      :new_status_id => stdraft.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => stzombie.id, 
      :new_status_id => stdraft.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => stapproved.id, 
      :new_status_id => stdraft.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => strejected.id, 
      :new_status_id => sterased.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => writer.id, :old_status_id => strejected.id, 
      :new_status_id => stdraft.id)

    # Reviewer transitions
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => reviewer.id, :old_status_id => ststable.id, 
      :new_status_id => stapproved.id)
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => reviewer.id, :old_status_id => ststable.id, 
      :new_status_id => strejected.id)

    # Manager transitions
=begin	
		# Creemos que no hace falta
    WorkflowTransition.create!(:tracker_id => t.id,
      :role_id => manager.id, :old_status_id => 0, 
      :new_status_id => stdraft.id)	
=end
    rqstatuses.each { |os|	
      rqstatuses.each { |ns|
        WorkflowTransition.create!(:tracker_id => t.id, 
          :role_id => manager.id, 
          :old_status_id => os.id, 
          :new_status_id => ns.id) unless os == ns
      }
    }

	# Let's make the new roles to respect cosmosys cf permissions
	csid = IssueCustomField.find_by_name('csID')
	cschapter = IssueCustomField.find_by_name('csChapter')
	rqroles.each{|r|
		Tracker.all.each{|tr|
			IssueStatus.all.each{|s|
				WorkflowPermission.create(:role_id => r.id, :tracker_id => tr.id, :old_status_id => s.id, :field_name => csid.id, :rule => "readonly")
				WorkflowPermission.create(:role_id => r.id, :tracker_id => tr.id, :old_status_id => s.id, :field_name => cschapter.id, :rule => "readonly")
			}
		}
	}


	rqtypefield = IssueCustomField.create!(:name => 'rqType', 
		:field_format => 'list', :possible_values => ['Info', 'Complex','Opt','Mech','Hw','Sw'], 
		:is_filter => true, :is_required => true,
		:is_for_all => true, :tracker_ids => [t.id])

    rqlevelfield = IssueCustomField.create!(:name => 'rqLevel', 
		:field_format => 'list', :possible_values => ['None', 'System','Derived','External','Shared'], 
		:is_filter => true, :is_required => true,
		:is_for_all => true, :tracker_ids => [t.id])

    rqrationalefield = IssueCustomField.create!(:name => 'rqRationale', 
		:field_format => 'text',
		:description => 'Rationale for setting the requirement',
		:min_length => '', :max_length => '', :regexp => '',
		:default_value => '', :is_required => false, 
		:is_filter => false, :searchable => true, 
		:visible => true, :role_ids => [],
		:full_width_layout => "1", :text_formatting => "full",
		:is_for_all => true, :tracker_ids => [t.id])

    rqsrcfield = IssueCustomField.create!(:name => 'rqSources', 
		:field_format => 'string', :searchable => true,
		:is_for_all => true, :tracker_ids => [t.id])

    rqvarfield = IssueCustomField.create!(:name => 'rqVar', 
		:field_format => 'string', :searchable => true,
		:is_for_all => true, :tracker_ids => [t.id])

	rqvaluefield = IssueCustomField.create!(:name => 'rqValue', 
		:field_format => 'string', :searchable => true,
		:is_for_all => true, :tracker_ids => [t.id])

	# Read-only fields
	def ro_field(t,fn,r,s1,s2)
		WorkflowPermission.create!(:tracker_id => t,
			:role_id => r, :old_status_id => s1, 
			:new_status_id => s2, rule: "readonly",
			field_name: fn)
	end

=begin	
	#  This is here for debugging
	rqtypefield = IssueCustomField.find_by_name('rqType')
    rqlevelfield = IssueCustomField.find_by_name('rqLevel')
    rqrationalefield = IssueCustomField.find_by_name('rqRationale')
    rqsrcfield = IssueCustomField.find_by_name('rqSources')
    rqvarfield = IssueCustomField.find_by_name('rqVar')
	rqvaluefield = IssueCustomField.find_by_name('rqValue')

	t = Tracker.find_by_name("rq")
	stdraft = IssueStatus.find_by_name("rqDraft")
=end
	# If it is a requirement, belongs to the project it belongs, forever
	WorkflowTransition.all.each{|wft|
		if (wft.tracker == t) then
			ro_field(wft.tracker_id,"project_id",wft.role_id,wft.old_status_id,wft.new_status_id)
			if wft.old_status_id != stdraft.id then
				# We ar not in the draft status, so we have to block all the requirements fields
				ro_field(wft.tracker_id,"subject",wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,"description",wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,"tracker_id",wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqtypefield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqlevelfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqrationalefield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqsrcfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqvarfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,rqvaluefield.id,wft.role_id,wft.old_status_id,wft.new_status_id)				
			end
		end
	}



	# Adapting cosmosys custom fields to work with req tracker
	cfid = IssueCustomField.find_by_name("csID")
	cfold = IssueCustomField.find_by_name("csOldCode")
	cfchapter = IssueCustomField.find_by_name("csChapter")

	cfs = [cfid,cfold,cfchapter]
	cfs.each{|cf|
		cf.trackers << t
		cf.save
	}

  end

  def down

    rqtrck = Tracker.find_by_name('rq')

    # Custom fields
		tmp = IssueCustomField.find_by_name('rqType')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqLevel')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqRationale')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqSources')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqChapter')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqVar')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqValue')
		if (tmp != nil) then
			tmp.destroy
		end

		# Trackers
		if (rqtrck != nil) then
			WorkflowTransition.all.each{ |tr|
				if (tr.tracker == rqtrck) then
					tr.destroy
				end
			}
			rqtrck.destroy
		end

    # Statuses
		tmp = IssueStatus.find_by_name('rqDraft')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('rqStable')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('rqApproved')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('rqRejected')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('rqErased')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('rqZombie')
		if (tmp != nil) then
			tmp.destroy
		end    

		# Roles
		tmp = Role.find_by_name('rqWriter')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('rqReviewer')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('rqMngr')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('rqReader')
		if (tmp != nil) then
			tmp.destroy
		end

    remove_index :csys_reqs, :cosmosys_issue_id
    drop_table :csys_reqs
  end
end
