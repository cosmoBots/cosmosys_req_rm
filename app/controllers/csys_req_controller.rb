class CsysReqController < ApplicationController
  before_action :find_this_project
  before_action :authorize, :except => [:find_this_project]

  def zombie
    if request.get? then
      # print("zombie GET!!!!!")
    else
      # print("zombie POST!!!!!")
      st = IssueStatus.find_by_name("rqZombie")
      @issue.status = st
      @issue.save
      redirect_to issue_path(@issue)
    end
  end

  def erase
    if request.get? then
      # print("erase GET!!!!!")
    else
      # print("erase POST!!!!!")
      st = IssueStatus.find_by_name("rqErased")
      @issue.status = st
      @issue.save
      redirect_to issue_path(@issue)
    end
  end

  def derive
    if request.get? then
      # print("derive GET!!!!!")
    else
      # print("derive POST!!!!!")
      if @issue.tracker.name == "rq" then
        cftype = IssueCustomField.find_by_name("rqType")
        thistype = @issue.custom_values.where(custom_field: cftype).first.value
        if thistype != nil then
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
                i.csys.update_cschapter_no_bd
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
            end
            flash.now[:notice] = 'Derivation executed.  Check your ' + count.to_s + ' new derived requirements'
          else
            flash.now[:error] = 'Problem in the number of requirements to derive'
          end
        else
          flash.now[:error] = 'Problem in the number of requirements to derive'
        end
      else
        flash.now[:error] = 'This item is not a requirement'
      end
      redirect_to(issue_path(@issue))
    end
  end

  def menu
  end

  def compmatrix
  end

  def refdocs
  end

  def apldocs
  end

  def compdocs
  end

  def clone
    if request.get? then
      # print("clone GET!!!!!")
    else
      # print("clone POST!!!!!")
      puts(params)
      pr = @issue.project
      par = @issue.parent
      i = pr.issues.new
      i.parent = par
      i.subject = "[Cloned:" + @issue.subject+"]"
      i.tracker = @issue.tracker
      for src_cfv in @issue.custom_field_values
        src_cf = src_cfv.custom_field
        # We have to skip the csID in the clone, because a new exclusive ID must be generated for the clone
        if src_cf.name != "csID" then
          if (src_cfv.value != nil) then
            dst_cfv = i.custom_field_values.select{|a| a.custom_field_id == src_cf.id }.first
            dst_cfv.value = src_cfv.value
            end
          end
        end
        i.author = User.current
        i.csys.update_cschapter_no_bd
        i.save
        for src_r in @issue.relations
          dst_r = nil
          if src_r.issue_to != @issue then
            dst_r = i.relations_from.new
            dst_r.issue_to = src_r.issue_to
          else
            dst_r = i.relations_to.new
            dst_r.issue_from = src_r.issue_from
          end
          dst_r.relation_type = src_r.relation_type
          dst_r.delay = src_r.delay
          dst_r.errors.clear
          if (dst_r.save) then
            #print(dst_r.to_s+" ... ok\n")
          else
            #print(dst_r.to_s+" ... nok\n")
            dst_r.errors.full_messages.each  do |message|
              print("--> " + message + "\n")
            end
          endcop
        end
=begin
        # Add a "copied_to" relationship
        cp_r = @issue.relations_from.new
        cp_r.issue_to = i
        cp_r.relation_type = "copied_to"
        cp_r.errors.clear
        if (cp_r.save) then
          #print(dst_r.to_s+" ... ok\n")
        else
          #print(dst_r.to_s+" ... nok\n")
          cp_r.errors.full_messages.each  do |message|
            print("--> " + message + "\n")
        end
=end
      end
      # Force the identifier creation
      puts i.csys.identifier+" created!"
      flash.now[:notice] = 'Clone executed.  Check your new cloned item following the copied_to link'
      redirect_to(issue_path(i))
    end
  end

  def find_this_project
    # @project variable must be set before calling the authorize filter
    if (params[:issue_id]) then
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    else
      if(params[:id]) then
        @project = Project.find(params[:id])
      else
        @project = Project.first
      end
    end
    #print("Project: "+@project.to_s+"\n")
  end

end
