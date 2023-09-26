require_dependency 'cosmosys_issue'

# Patches Redmine's Issues dynamically.
module CosmosysIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      
      has_one :csys_req

    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods

    def req
      if self.csys_req == nil then
        CsysReq.create!(cosmosys_issue:self)
      end      
      self.csys_req
    end

    def attributes
        #super.merge({'identifier' => identifier})
    end

  end    
end
# Add module to Issue
CosmosysIssue.send(:include, CosmosysIssuePatch)

module CosmosysIssueOverwritePatch
  def is_valid?
    self.req.is_valid?
  end
  
  def is_chapter?
    if self.issue.tracker.name == "rq" then
      cftype = IssueCustomField.find_by_name('rqType')
      rqtypevalues = self.issue.custom_values.where(custom_field_id: cftype.id)
      if (rqtypevalues.size == 0) then
        ret = self.issue.children.size > 0
      else
        ret = rqtypevalues.first.value == 'Info'
      end
      return ret
    else
      super
    end
  end

  def shall_show_dependences?
    if self.issue.tracker.name == "rq" then
      not is_chapter?
    else
      super
    end
  end

  def shall_show_id
    if self.issue.tracker.name == "prSys" or 
      self.issue.tracker.name === "prParam" or 
      self.issue.tracker.name == "prMode" or 
      self.issue.tracker.name == "prCmd" or 
      self.issue.tracker.name == "prValue" or 
      self.issue.tracker.name == "prValFloat" or 
      self.issue.tracker.name == "prValText" then 
      return true
    else
        return not(self.is_chapter?)
    end
  end

  def shall_draw
    if self.issue.tracker.name == "rq" then
      return not(self.issue.status.is_closed)
    else
      return true
    end
  end

  def get_fill_color
    i = self.issue
    if i.tracker.name == "prSys"
      colorstr = "white"
    else
      if self.issue.tracker.name === "prParam" then
        colorstr = "skyblue2"
      else
        if self.issue.tracker.name == "prValue" or 
          self.issue.tracker.name == "prValFloat" or 
          self.issue.tracker.name == "prValText" then 
          colorstr = "lightcyan"
        else
          if self.issue.tracker.name == "prMode" then
            colorstr = "moccasin"
          else
            if self.issue.tracker.name == "prCmd" then
              colorstr = "darkseagreen1"
            else
              colorstr = self.inner_get_fill_color
            end
          end
        end
      end
    end
    return colorstr
  end

  def get_valuestr(cfname)
    cftype = IssueCustomField.find_by_name(cfname)
    if cftype != nil then
      cfvalues = self.issue.custom_values.where(custom_field_id: cftype.id)
      if cfvalues.size > 0 then
        ret = cfvalues.first.to_s
      else
        ret = "?"
      end
    else
      ret = "?"
    end
    return ret
  end

  def get_ancestor_based_label(baseproj,boundary_node=false)
    i = self.issue
    prependstr = ""
    if (baseproj != i.project) then
      prependstr = "+"
    else
      if (boundary_node) then
        prependstr = "*"
      end
    end
    if i.tracker.name == "prValFloat" then
      if i.parent != nil then
        minval = get_valuestr("prMin")
        defval = get_valuestr("prDefault")
        maxval = get_valuestr("prMax")
        ret = "{{ "+prependstr+i.parent.subject+"|"+self.class.word_wrap(prependstr+i.subject, line_width: 12) + "}|{"+minval+"|"+defval+"|"+maxval+"}}"
      else
        ret = "{"+prependstr+"<?>|"+self.class.word_wrap(prependstr+i.subject, line_width: 12) + "}"
      end
    else
      if i.parent != nil then
        ret = "{ "+prependstr+i.parent.subject+"|"+self.class.word_wrap(prependstr+i.subject, line_width: 12) + "}"
      else
        ret = "{"+prependstr+"<?>|"+self.class.word_wrap(prependstr+i.subject, line_width: 12) + "}"
      end
      end        
    return ret
  end

  def get_ancestor_based_norecord_label(baseproj,boundary_node=false)
    i = self.issue
    prependstr = ""
    prependstr = ""
    if (baseproj != i.project) then
      prependstr = "+"
    else
      if (boundary_node) then
        prependstr = "*"
      end
    end
    if i.parent != nil then
      ret = prependstr+i.parent.subject+"|"+self.class.word_wrap(prependstr+i.subject, line_width: 12)
    else
      ret = prependstr+"<?>:"+self.class.word_wrap(prependstr+i.subject, line_width: 12)
    end
    if i.tracker.name == "prValFloat" then
      ret += ":[min|def|max]"
    end
    return ret    
  end
  
  def get_label_issue(baseproj,boundary_node=false)
    i = self.issue
    trname = i.tracker.name
    if trname == "prParam" or trname == "prSys" then
      ret = get_ancestor_based_label(baseproj,boundary_node)
    else
      if trname == "prValue" or trname == "prValFloat" or trname == "prValText" then 
        ret = get_ancestor_based_label(baseproj,boundary_node)
      else
        if trname == "prMode" then
          ret = get_ancestor_based_label(baseproj,boundary_node)
        else
          if trname == "prCmd" then
            ret = get_ancestor_based_label(baseproj,boundary_node)
          else
            ret = inner_get_label_issue(baseproj,boundary_node)
          end
        end
      end
    end
    return ret
  end

  def get_documents_table
    rqrefdocfield = IssueCustomField.find_by_name('rqRefDocs')
    rqrefdoc = self.issue.custom_field_values.select{|a| a.custom_field_id == rqrefdocfield.id }.first
    if (rqrefdoc != nil) then
      source = rqrefdoc.value
      if source == nil then
        ""
      else
        header = "|Ref|Subject|Comments|\n"
        header += "|---|---|---|\n"
        retdest = ""
        refchapterdone = false
        refchapter = nil
        retdest = ""
        for line in source.lines do
          dest = ""
          line = line.strip()
          cells = line.split('|')
          if cells.size > 1 then
            if not refchapterdone
              refchapterdone = true
              refchapter = self.issue.project.issues.find_by_subject("References")
              if (refchapter == nil) then
                rqtypefield = IssueCustomField.find_by_name('rqType')
                rqlevelfield = IssueCustomField.find_by_name('rqLevel')
                rqcompliancefield = IssueCustomField.find_by_name('rqComplanceState')
                refchapter = self.issue.project.issues.new
                refchapter.tracker = Tracker.find_by_name("rq")
                refchapter.subject = "References"
                rqtype =  refchapter.custom_field_values.select{|a| a.custom_field_id == rqtypefield.id }.first
                rqlevel =  refchapter.custom_field_values.select{|a| a.custom_field_id == rqlevelfield.id }.first
                rqtype.value = "Info"
                rqlevel.value = "None"
                thiscv = refchapter.custom_field_values.select{|a| a.custom_field_id == rqcompliancefield.id }.first
                thiscv.value=rqcompliancefield.default_value
                refchapter.author = User.current
                refchapter.save
              end
            end
            ref = "| " + cells[0] + " | - unknown reference - | "
            if refchapter.id != nil then
              ch = refchapter.children.find_by_subject(cells[0])
              if (ch != nil) then
                ref = "| [" + ch.subject + "](/issues/" + ch.id.to_s + ") | " + ch.description + " | "
              end
            end
            dest += ref
            for i in 1..cells.size-1 do
              dest += cells[i] + " |"
            end
          end
          retdest += dest + "\n"
        end
        if retdest != "" then
          retdest = header + retdest
        end
        retdest
      end
    else
      ""
    end
  end

  def create_a_chapter(chaptername, status = nil)
    rqtypefield = IssueCustomField.find_by_name('rqType')
    rqlevelfield = IssueCustomField.find_by_name('rqLevel')
    rqcompliancefield = IssueCustomField.find_by_name('rqComplanceState')
    refchapter = self.issue.project.issues.new
    refchapter.tracker = Tracker.find_by_name("rq")
    if status != nil then
      refchapter.status = status
    end
    refchapter.subject = chaptername
    rqtype =  refchapter.custom_field_values.select{|a| a.custom_field_id == rqtypefield.id }.first
    rqlevel =  refchapter.custom_field_values.select{|a| a.custom_field_id == rqlevelfield.id }.first
    rqtype.value = "Info"
    rqlevel.value = "None"
    thiscv = refchapter.custom_field_values.select{|a| a.custom_field_id == rqcompliancefield.id }.first
    thiscv.value=rqcompliancefield.default_value
    refchapter.author = User.current
    refchapter.save
    refchapter.project.reenumerate_children(true)
    return refchapter
  end


  def get_compdocs_table
    rqrefdocfield = IssueCustomField.find_by_name('rqComplianceDocs')
    rqrefdoc = self.issue.custom_field_values.select{|a| a.custom_field_id == rqrefdocfield.id }.first
    if (rqrefdoc != nil) then
      source = rqrefdoc.value
      if source == nil then
        ""
      else
        header = "|Ref|Subject|Comments|\n"
        header += "|---|---|---|\n"
        retdest = ""
        refchapterdone = false
        refchapter = nil
        retdest = ""
        for line in source.lines do
          dest = ""
          line = line.strip()
          cells = line.split('|')
          if cells.size > 1 then
            if not refchapterdone
              refchapterdone = true
              refchapter = self.issue.project.issues.find_by_subject("Compliance Documents")
              if (refchapter == nil) then
                refchapter = create_a_chapter("Compliance Documents")
              end
            end
            ref = "| " + cells[0] + " | - unknown reference - | "
            if refchapter.id != nil then
              ch = refchapter.children.find_by_subject(cells[0])
              if (ch != nil) then
                ref = "| [" + ch.subject + "](/issues/" + ch.id.to_s + ") | " + ch.description + " | "
              end
            end
            dest += ref
            for i in 1..cells.size-1 do
              dest += cells[i] + " |"
            end
          end
          retdest += dest + "\n"
        end
        if retdest != "" then
          retdest = header + retdest
        end
        puts(retdest)
        retdest
      end
    else
      ""
    end
  end



  def csys_cfields_to_sync_with_copy
    ret = super
    if self.issue.tracker == Tracker.find_by_name("rq")
      cf = CustomField.find_by_name("rqType")
      ret << cf 
      cf = CustomField.find_by_name("rqLevel")
      ret << cf 
      cf = CustomField.find_by_name("rqVar")
      ret << cf 
      cf = CustomField.find_by_name("rqValue")
      ret << cf 
      cf = CustomField.find_by_name("rqVerif")
      ret << cf 
      cf = CustomField.find_by_name("rqVerifDescr")
      ret << cf 
      cf = CustomField.find_by_name("rqRationale")
      ret << cf 
    end
    return ret
  end

  def save_post_process
  end

  def can_be_rq_closed?
    puts("BEING can_be_rq_closed " + self.issue.subject)
    # We can not rq_close which is already closed
    if not self.issue.status.is_closed then
      # And we can not rq_close which is not a requirement
      if self.issue.tracker == Tracker.find_by_name("rq") then
        # Now let's examine the issue relations        
        i = self.issue
        # We can not close anything which has children
        if (i.children.size > 0) then
          puts("END can_be_rq_closed c:"+i.children.size.to_s+" = 0 ")
          return false
        end
        # We can not close anything which is blocking or being precedent to another requirement
        # Same with requirement copies, which need the master being "alive".  Other relations like the 'relates' ones, are irrelevant.
        i.relations_from.each{|r|
          if (r.relation_type == 'blocks' or r.relation_type == 'precedes' or r.relation_type = 'copied_to') then
            puts("END can_be_rq_closed r 0 " + r.relation_type + " " + r.attributes.to_s)
            return false
          end
        }
        # If there were relations, they are not blocking (relates)
        # so we can conclude the issue can be rq_erased
        puts("END can_be_rq_closed 1")
        return true
      end
    end
    return false
    puts("END can_be_rq_closed")
  end
  
  # This process handles the closing and opening actions of requirements

  def save_pre_process
    puts("BEGIN save_pre_process",self.issue.to_s)
    # First check we only work on requirements
    if self.issue.tracker == Tracker.find_by_name("rq") then
      # Checking if opening or closing
      puts("******** "+self.issue.status.to_s)
      if self.issue.status.is_closed then
        # We are closing, but were already closed?
        # In case we are creating this issue for the first time, we can simply skip 
        # relationships
        if (self.issue.id != nil) then
          oldreq = Issue.find(self.issue.id)
          oldreq.reload
          puts("******** "+oldreq.status.to_s)
          if not(oldreq.status.is_closed) then
            # No, we were not closed, so going closing
            puts("Going closing")
            # The closed requirements (rqErased, rqZombie) have to go to the chapter named "Deleted requirements"
            if (self.issue.subject != "Deleted requirements") then
              refchapter = self.issue.project.issues.find_by_subject("Deleted requirements")
              # If there is no such chapter, we create it
              if (refchapter == nil) then
                puts("BEGIN Creating a chapter")
                # This can not be done yet, because we first need an action to recover the erased requirements
                # refchapter = create_a_chapter("Deleted requirements",IssueStatus.find_by_name("rqErased"))
                # so we still need to create these chapters as rqDraft
                refchapter = create_a_chapter("Deleted requirements")
                puts("END Creating a chapter")
              else
                puts("Deleted requirements chapter found")
              end
              puts("BEGIN relations")
              # Let's see if the current issue is the deleted requirement, or if the issue is already in the deleted requirmements section
              # in those cases we will not actuate (requirements were already there)
              if (self.issue != refchapter and self.issue.parent != refchapter) then
                # Let's prepare the dictionary for storing the things to recover in the future
                relations_vector = []
                if (self.issue.parent != nil) then
                  # If it has a parent, we'll store its has in the vector
                  relations_vector << {parent: self.issue.parent_id.to_s, csID:self.issue.parent.csys.identifier}
                end
                # Now we can assign the deleted requirements chapter as its parent
                self.issue.parent = refchapter

                # Now we will backup the relations before destroying them
                self.issue.relations.each {|ir|
                  # We'll save the csID of the counterpart issue
                  if ir.issue_from != self then
                    otherissuecsid = ir.issue_from.csys.identifier
                  else
                    otherissuecsid = ir.issue_to.csys.identifier
                  end
                  # We'll store then a hash containing the counterpart csID and the serialization of the issue relation object
                  irdict = { csID: otherissuecsid, ir: ir.attributes }
                  # And push the hash to the relations vector
                  relations_vector << irdict
                }
                # Then we serialize the relations vector in the custom field
                self.relations_on_close = relations_vector.to_s
                self.save
                # And then we can remove the relations
                self.issue.relations.each {|ir|
                  ir.destroy
                }
                puts("END relations")
              end
              puts("END closing")
            end
          end
        end
      puts("END is_closed")
      else
        puts("BEGIN is opened")
        if (self.issue.id != nil) then
          # So we are opening a closed issue, let's see if it was already opened
          oldreq = Issue.find(self.issue.id)
          oldreq.reload
          if (oldreq.status.is_closed) then
            # It was not open, let's open it
            puts("Going opening!")
            # Let's see if there are some stored relations
            parent_relation_found = false
            if (self.relations_on_close != nil and self.relations_on_close != "") then
              # So, let's eval the relations string
              relations = eval(self.relations_on_close)
              # Now we have a vector of hashes
              relations.each{|r|
                # Process the current hash
                if (r.has_key?(:parent)) then
                  # This relationship is of "parent-child" type, let's locate the parent requirement using its csID
                  thisparent = self.issue.project.csys.find_issue_by_identifier(r[:csID],true)
                  if (thisparent != nil) then
                    # We will not restore the parent relation unless it is a requirement
                    if thisparent.tracker == self.issue.tracker then
                      # It exists, just simply add to it
                      self.issue.parent = thisparent
                      parent_relation_found = true
                    end
                  end
                else
                  if (r.has_key?(:csID)) then
                    otherissue = self.issue.project.csys.find_issue_by_identifier(r[:csID],true)
                    if (r.has_key?(:ir)) then
                      irhash = r[:ir]
                      ir = IssueRelation.new(irhash)
                      if (self.issue == ir.issue_from) then
                        ir.issue_to = otherissue
                      else
                        ir.issue_from = otherissue
                      end
                      ir.save
                    else
                      puts("Warning, the relation is incomplete!!!")
                    end
                  end
                end
              }
            end
            if not(parent_relation_found) then
              # The parent is not present, we will move the requirement to the undeleted requirements section
              refchapter = self.issue.project.issues.find_by_subject("Undeleted requirements")
              if (refchapter == nil) then
                # As the chapter does not exist, let's create it
                refchapter = create_a_chapter("Undeleted requirements")
              end
              # And now let's move the requirement to that section the 
              self.issue.parent = refchapter
            end
            # If the parent is closed, we shall open it!
            if (self.issue.parent.status.is_closed) then
              # We'll restore its parent to the same status of this issue
              self.issue.parent.status = self.issue.status
              # Let's trigger the parent recovery process by saving it now
              puts("BEGIN call saving parent")
              self.issue.parent.save
              puts("END call saving parent")
            end
          end
        end
        puts("END is opened")
      end
    end
    puts("END save_pre_process")
  end


end
CosmosysIssue.send(:prepend, CosmosysIssueOverwritePatch)
