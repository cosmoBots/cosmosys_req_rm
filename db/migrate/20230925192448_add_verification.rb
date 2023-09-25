class AddVerification < ActiveRecord::Migration[5.2]
	# Read-only fields
	def ro_field(t,fn,r,s1,s2)
		WorkflowPermission.create!(:tracker_id => t,
			:role_id => r, :old_status_id => s1, 
			:new_status_id => s2, rule: "readonly",
			field_name: fn)
	end

  def up

    rqtrck = Tracker.find_by_name('rq')
    stdraft = IssueStatus.find_by_name('rqDraft')

    rqverifstrfield = IssueCustomField.create!(:name => 'rqVerifDescr', 
		:field_format => 'text',
		:description => 'Verification description',
		:min_length => '', :max_length => '', :regexp => '',
		:default_value => "", :is_required => false, 
		:is_filter => true, :searchable => true, 
		:visible => true, :role_ids => [],
		:full_width_layout => "1", :text_formatting => "full",
		:is_for_all => true, :tracker_ids => [rqtrck.id])  



    posval = ['To Be Defined', 'Design','Analysis','Test','Inspection']
    rqveriffield = IssueCustomField.create!(:name => 'rqVerif', 
      :field_format => 'list', :possible_values => posval, 
      :multiple => true, :format_store => {:url_pattern => "", :edit_tag_style => 'check_box'},
      :description => 'Verification method',
      :is_filter => true, :is_required => true,
      :default_value => posval[0],
      :is_for_all => true, :tracker_ids => [rqtrck.id])


    WorkflowTransition.all.each{|wft|
      if (wft.tracker == rqtrck) then
        if wft.old_status_id != stdraft.id then
          # We ar not in the draft status, so we have to block all the requirements fields
          ro_field(wft.tracker_id,rqveriffield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
          ro_field(wft.tracker_id,rqverifstrfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
        end
      end
    }

    Issue.all.each{|i|
      if i.tracker == rqtrck then
        i.reload
        thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqveriffield.id }.first
        thiscv.value=rqveriffield.default_value
        i.save
      end
    }


  end

  def down
		tmp = IssueCustomField.find_by_name('rqVerif')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqVerifDescr')
		if (tmp != nil) then
			tmp.destroy
		end
  end

end
