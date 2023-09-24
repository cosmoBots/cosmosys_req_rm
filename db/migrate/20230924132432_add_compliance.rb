class AddCompliance < ActiveRecord::Migration[5.2]
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

    rqcomprefdocfield = IssueCustomField.create!(:name => 'rqComplianceDocs', 
		:field_format => 'text',
		:description => 'Reference documents for the compliance of the requirement. Please use conventional format!',
		:min_length => '', :max_length => '', :regexp => '',
		:default_value => "", :is_required => false, 
		:is_filter => false, :searchable => true, 
		:visible => true, :role_ids => [],
		:full_width_layout => "1", :text_formatting => "full",
		:is_for_all => true, :tracker_ids => [rqtrck.id])  


    rqjustiffield = IssueCustomField.create!(:name => 'rqComplianceJustif', 
      :field_format => 'text',
      :description => 'Justification of Not compliance for the requirement. Please use conventional format!',
      :min_length => '', :max_length => '', :regexp => '',
      :default_value => '', :is_required => false, 
      :is_filter => false, :searchable => true, 
      :visible => true, :role_ids => [],
      :full_width_layout => "1", :text_formatting => "full",
      :is_for_all => true, :tracker_ids => [rqtrck.id])  



    posval = ['To Be Confirmed', 'Not Compliant','Compliant','Not Applicable','Partially Compliant']
    rqcompliancefield = IssueCustomField.create!(:name => 'rqComplanceState', 
      :field_format => 'list', :possible_values => posval, 
      :description => 'State of Compliance',
      :is_filter => true, :is_required => true,
      :default_value => posval[0],
      :is_for_all => true, :tracker_ids => [rqtrck.id])


    WorkflowTransition.all.each{|wft|
      if (wft.tracker == rqtrck) then
        if wft.old_status_id != stdraft.id then
          # We ar not in the draft status, so we have to block all the requirements fields
          ro_field(wft.tracker_id,rqcomprefdocfield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
          ro_field(wft.tracker_id,rqjustiffield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
          ro_field(wft.tracker_id,rqcompliancefield.id,wft.role_id,wft.old_status_id,wft.new_status_id)
        end
      end
    }



  end

  def down
		tmp = IssueCustomField.find_by_name('rqComplianceDocs')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqComplianceJustif')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('rqComplanceState')
		if (tmp != nil) then
			tmp.destroy
		end        
  end
end
