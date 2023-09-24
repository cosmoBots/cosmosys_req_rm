class AddNewdefaultvalues < ActiveRecord::Migration[5.2]
  def up
    rqtrck = Tracker.find_by_name('rq')
    cftype = IssueCustomField.find_by_name("rqType")
    rqrefdocfield = IssueCustomField.find_by_name('rqRefDocs')
    rqcomprefdocfield = IssueCustomField.find_by_name('rqComplianceDocs')
    rqcompliancefield = IssueCustomField.find_by_name('rqComplanceState')

    Issue.all.each{|i|
      if i.tracker == rqtrck then
        i.reload
        if (i.children.size <= 0) then
          typecv = i.custom_field_values.select{|a| a.custom_field_id == cftype.id }.first
          if typecv.value != 'Info' then
            thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqrefdocfield.id }.first
            thiscv.value=rqrefdocfield.default_value
            thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqcomprefdocfield.id }.first
            thiscv.value=rqcomprefdocfield.default_value
            thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqcompliancefield.id }.first
            thiscv.value=rqcompliancefield.default_value              
            i.save
          end
        end
      end
    }

  end
end
