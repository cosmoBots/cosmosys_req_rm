class AddCustomFieldIdCounter < ActiveRecord::Migration[5.2]
  def up
		# Custom fields
    rqdoctrck = Tracker.find_by_name('ReqDoc')
    
		rqidcounter = IssueCustomField.create!(:name => 'RqIdCounter', 
			:field_format => 'integer', :searchable => false,
			:description => 'Counter for generating identifiers',
			:default_value => 1, :is_required => true, 
      :is_filter => false, :visible => false,
			:is_for_all => true, :tracker_ids => [rqdoctrck.id])
  end
  def down
		tmp = IssueCustomField.find_by_name('RqIdCounter')
		if (tmp != nil) then
			tmp.destroy
		end
  end
end
