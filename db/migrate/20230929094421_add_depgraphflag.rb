class AddDepgraphflag < ActiveRecord::Migration[5.2]
  def up
    # This is for ensuring that everybody in cosmosys knows about this field.
    # In some cases the trackers could not have it imported
    rqdephgraphsfield = IssueCustomField.find_by_name('depGrahInReports')
    Issue.all.each{|i|
      i.reload
      thiscv = i.custom_field_values.select{|a| a.custom_field_id == rqdephgraphsfield.id }.first
      if (thiscv.value != rqdephgraphsfield.default_value) then
        thiscv.value = rqdephgraphsfield.default_value
        i.save
      end
    }    
  end
end
