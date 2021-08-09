class CsysReqController < ApplicationController
  before_action :find_this_issue
  #before_action :authorize
  def derive
    if request.get? then
      print("derive GET!!!!!")
    else
      print("derive POST!!!!!")
      puts(params)
      countstr = params[:count]
      if countstr != nil then
        count = countstr.to_i
        if count != nil and count >= 1 then
          pr = @issue.project
          par = @issue.parent
          cftype = IssueCustomField.find_by_name("rqType")
          cflevel = IssueCustomField.find_by_name("rqLevel")
          thistype = @issue.custom_values.where(custom_field: cftype).first.value
          for index in 1..count
            i = pr.issues.new
            i.parent = par
            i.subject = "[Derived:"+index.to_s+"] " + @issue.subject
            i.tracker = @issue.tracker
            cvtype = i.custom_field_values.select{|a| a.custom_field_id == cftype.id }.first
            cvtype.value = thistype
            cvlevel = i.custom_field_values.select{|a| a.custom_field_id == cflevel.id }.first
            cvlevel.value = "Derived"
            i.author = User.current
            i.save
            relation = @issue.relations_from.new
            relation.issue_to = i
            relation.relation_type = 'blocks'
            relation.errors.clear
            if (relation.save) then
              #print(relation.to_s+" ... ok\n")
            else
              #print(relation.to_s+" ... nok\n")
              relation.errors.full_messages.each  do |message|
                print("--> " + message + "\n")
              end                            
            end
            # Force the identifier creationg
            puts i.csys.identifier+" created!"
          end
          flash.now[:notice] = 'Derivation executed.  Check your ' + count.to_s + ' new derived requirements'
        else
          flash.now[:error] = 'Problem in the number of derived requirements'
        end
      else
      end
      redirect_to(issue_path(@issue))
    end    
  end

  def find_this_issue
    if(params[:id]) then
      @issue = Issue.find(params[:id])
    else
      @issue = nil
    end
  end  

end
