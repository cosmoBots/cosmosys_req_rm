require_dependency 'issue'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Deliverable
module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:prepend, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      #before_save :check_identifier
      before_validation :bypass_identifier, :bypass_chapter
      #before_save :check_identifier
      after_save :check_chapter
      #validates :parent, presence: true, if: :is_req?
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    @@cfdoccount = IssueCustomField.find_by_name('RqIdCounter')    
    @@cfdocprefix = IssueCustomField.find_by_name('RqPrefix')  
    @@cfisschapter = IssueCustomField.find_by_name('RqChapter')  
    @@rqdoctrck = Tracker.find_by_name('ReqDoc')
    @@rqtrck = Tracker.find_by_name('Req')
 
    def is_req?
      (self.tracker == @@rqtrck)
    end
    
    def validate_issue
      can_continue = true
      if @parent_issue == nil then
        if self.parent == nil then
          if (self.tracker == @@rqtrck) then
            errors.add :parent_issue_id, :blank
            can_continue = false
          end
        end
      end
      if can_continue then
        check_identifier
      end
      super
    end
    
    def future_document
      if self.tracker == @@rqdoctrck then
        ret = self 
      else
        # not do found yet
        ret = @parent_issue
        if ret != nil then
          ret = ret.document
        end
      end
      return ret
    end

    def document
      ret = nil
      if self.tracker == @@rqdoctrck then
        ret = self 
      else
        # not do found yet
        ret = self.parent
        if ret != nil then
          ret = ret.document
        end
      end
      return ret
    end

    def bypass_identifier
      if self.subject == "" or self.subject == nil then
        self.subject = "INVALID_ID"
      end
    end
    def bypass_chapter
      if @@cfisschapter != nil then
        cfisschapter = self.custom_values.find_by_custom_field_id(@@cfisschapter.id)
        if cfisschapter == nil then
          cfisschapter = CustomValue.new
          cfisschapter.custom_field = @@cfisschapter
          cfisschapter.customized = self
          cfisschapter.value = "INVALID_CHAPTER"
        end
      end
    end
    
    def check_identifier
      # AUTO SUBJECT
      if self.subject == "" or self.subject == nil or self.subject=="INVALID_ID" then
        self.subject = nil
        thisdocument = self.future_document
        if thisdocument != nil then
          if thisdocument != self then
            self.subject = thisdocument.obtain_new_rqid()
          end
        end
      end
      return self.subject != nil
    end

    def obtain_new_rqid
      ret = nil
      if self.tracker == @@rqdoctrck then
        if @@cfdocprefix != nil then
          cfdocprefix = self.custom_values.find_by_custom_field_id(@@cfdocprefix.id)
          if cfdocprefix != nil then
            if @@cfdoccount != nil then
              cfdoccount = self.custom_values.find_by_custom_field_id(@@cfdoccount.id)
              if (cfdoccount != nil) then
                print cfdoccount.value
                print cfdoccount.value.class
                
                counter = cfdoccount.value.to_i
                if counter == nil or counter < 1 then
                  counter = 1
                end
                foundid = nil
                
                while (foundid == nil) do
                  tmp = cfdocprefix.value+"-"+format('%04d', counter)
                  if self.project.issues.find_by_subject(tmp) == nil then
                    foundid = tmp
                    cfdoccount.value = counter + 1
                    cfdoccount.save
                  else
                    counter += 1
                  end
                end




                ret = foundid
              end
            end
          end
        end
      end
      return ret
    end    
    
    def check_chapter
      # AUTO CHAPTER
      if @@cfisschapter != nil then
        cfisschapter = self.custom_values.find_by_custom_field_id(@@cfisschapter.id)
        if cfisschapter == nil then
          cfisschapter = CustomValue.new
          cfisschapter.custom_field = @@cfisschapter
          cfisschapter.customized = self
          cfisschapter.value = nil
        end
        if cfisschapter.value == "" or cfisschapter.value == nil or cfisschapter.value == "INVALID_CHAPTER" then
          if self.parent != nil then
            cfparentiffchapter = self.parent.custom_values.find_by_custom_field_id(@@cfisschapter.id)
            if cfparentiffchapter == nil then
              self.parent.save
            end
            cfisschapter.value = cfparentiffchapter.value+"z."
            cfisschapter.save
            return true
          else
            return false
          end
        else
          return true
        end
      else
        return false
      end
    end
  end    
end
# Add module to Issue
Issue.send(:include, IssuePatch)


