class AdditionalSettings < ActiveRecord::Migration[5.2]
	def ro_field(t,fn,r,s1,s2)
		WorkflowPermission.create!(:tracker_id => t,
				:role_id => r, :old_status_id => s1, 
				:new_status_id => s2, rule: "readonly",
				 field_name: fn)
	end

	def up
		r = IssueCustomField.find_by_name("RqTitle")
		r.is_required = true
		r.is_filter = true
		r.save

		r = IssueCustomField.find_by_name('RqType')
		r.is_required = true
		r.save

		r = IssueCustomField.find_by_name("RqLevel")
		r.is_required = true
		r.save

		r = IssueCustomField.find_by_name("RqChapter")
		r.is_required = true
		r.is_filter = true
		r.save

		rdtracker = Tracker.find_by_name("ReqDoc")
		rqtracker = Tracker.find_by_name("Req")
		cfchapter = IssueCustomField.find_by_name("RqChapter")
		WorkflowTransition.all.each{|wft|
			if (wft.tracker == rqtracker) or (wft.tracker == rdtracker) then
				ro_field(wft.tracker_id,"subject",wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,"project_id",wft.role_id,wft.old_status_id,wft.new_status_id)
				ro_field(wft.tracker_id,cfchapter.id,wft.role_id,wft.old_status_id,wft.new_status_id)
			end
		}

	end
	def down
	end
end