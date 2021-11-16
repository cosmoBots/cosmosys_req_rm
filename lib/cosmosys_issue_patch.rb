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
      self.issue.tracker.name == "prMode" then
      return true
    else
      if self.issue.tracker.name == "prValue" or 
        self.issue.tracker.name == "prValFloat" or 
        self.issue.tracker.name == "prValText" then 
        return false
      else
        return not(self.is_chapter?)
      end
    end
  end

  def get_fill_color
    i = self.issue
    if i.tracker.name == "prSys"
      colorstr = "white"
    else
      if self.issue.tracker.name === "prParam" then
        colorstr = "aquamarine"
      else
        if self.issue.tracker.name == "prValue" or 
          self.issue.tracker.name == "prValFloat" or 
          self.issue.tracker.name == "prValText" then 
          colorstr = "lightblue"
        else
          if self.issue.tracker.name == "prMode" then
            colorstr = "orange"
          else
            colorstr = self.inner_get_fill_color
          end
        end
      end
    end
    return colorstr
  end


  def get_label_noid
    self.class.word_wrap(self.issue.subject, line_width: 12)
  end

=begin
  def get_label_issue
    "{ "+self.get_identifier+"|"+self.class.word_wrap(self.issue.subject, line_width: 12) + "}"
  end
=end
end
CosmosysIssue.send(:prepend, CosmosysIssueOverwritePatch)
