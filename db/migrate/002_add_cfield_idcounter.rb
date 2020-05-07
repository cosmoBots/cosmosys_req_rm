class AddCfieldIdcounter < ActiveRecord::Migration[5.2]
  def up
		# Custom fields
    rqdoctrck = Tracker.find_by_name('ReqDoc')
    rqmngr = Role.find_by_name('RqMngr')
		rqidcounter = IssueCustomField.create!(:name => 'RqIdCounter', 
			:field_format => 'int', :searchable => false,
			:description => 'Counter for generating identifiers',
			:default_value => '1', :is_required => true, 
      :is_filter => false, :visible => false,
      :role_ids => [rqmngr.id],
			:is_for_all => true, :tracker_ids => [rqdoctrck.id])
  end
  def down
		tmp = IssueCustomField.find_by_name('RqIdCounter')
		if (tmp != nil) then
			tmp.destroy
		end
  end
end
