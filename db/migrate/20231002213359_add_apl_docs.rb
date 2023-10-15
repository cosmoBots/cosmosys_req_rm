class AddAplDocs < ActiveRecord::Migration[5.2]

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

    rqrefdocfield = IssueCustomField.create!(:name => 'rqAplDocs', 
		:field_format => 'text',
		:description => 'Reference documents for current requirement. Please use conventional format!',
		:min_length => '', :max_length => '', :regexp => '',
		:default_value => "", :is_required => false, 
		:is_filter => true, :searchable => true, 
		:visible => true, :role_ids => [],
		:full_width_layout => "1", :text_formatting => "full",
		:is_for_all => true, :tracker_ids => [rqtrck.id])

    WorkflowTransition.all.each{|wft|
      if (wft.tracker == rqtrck) then
        if wft.old_status_id != stdraft.id then
          # We ar not in the draft status, so we have to block all the requirements fields
          ro_field(wft.tracker_id,rqrefdocfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
        end
      end
    }
=begin
    Issue.all.each{|i|
      if i.tracker == rqtrck then
        i.reload
        if (i.children.size <= 0) then
          typecv = i.custom_field_values.select{|a| a.custom_field_id == cftype.id }.first
          if typecv.value != 'Info' then
            thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqrefdocfield.id }.first
            thiscv.value=rqrefdocfield.default_value
            i.save
          end
        end
      end
    }
=end

  end

  def down
		tmp = IssueCustomField.find_by_name('rqAplDocs')
		if (tmp != nil) then
			tmp.destroy
		end    
  end

end
