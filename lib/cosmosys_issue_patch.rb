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

  def shall_show_id
    if self.issue.tracker.name == "prSys" or 
      self.issue.tracker.name === "prParam" or 
      self.issue.tracker.name == "prMode" or 
      self.issue.tracker.name == "prValue" or 
      self.issue.tracker.name == "prValFloat" or 
      self.issue.tracker.name == "prValText" then 
      return true
    else
        return not(self.is_chapter?)
    end
  end

  def get_fill_color
    i = self.issue
    if i.tracker.name == "prSys"
      colorstr = "white"
    else
      if self.issue.tracker.name === "prParam" then
        colorstr = "darkseagreen1"
      else
        if self.issue.tracker.name == "prValue" or 
          self.issue.tracker.name == "prValFloat" or 
          self.issue.tracker.name == "prValText" then 
          colorstr = "lightcyan"
        else
          if self.issue.tracker.name == "prMode" then
            colorstr = "moccasin"
          else
            colorstr = self.inner_get_fill_color
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
        ret = "{ "+prependstr+i.parent.subject+"/\n"+self.class.word_wrap(prependstr+i.subject, line_width: 12) + "|{"+minval+"|"+defval+"|"+maxval+"}}"
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
      ret = prependstr+i.parent.subject+"/\n"+self.class.word_wrap(prependstr+i.subject, line_width: 12)
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
          ret = inner_get_label_issue(baseproj,boundary_node)
        end
      end
    end
    return ret
  end

end
CosmosysIssue.send(:prepend, CosmosysIssueOverwritePatch)
