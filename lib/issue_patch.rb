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
      ret = (self.tracker == @@rqtrck)
      print "entro en is_req...\n"
      print ret
      print "padre?\n"
      print self.parent
      return ret
    end
    
    def validate_issue
      can_continue = true
      print "1*********************\n"
      if @parent_issue == nil then
      print "6*********************\n"
        if (self.tracker == @@rqtrck) then
      print "7*********************\n"
          errors.add :parent_issue_id, :blank
          can_continue = false
        end
      end
      print "2*********************\n"
      if can_continue then
      print "3*********************\n"
        check_identifier
      end
      print "4*********************\n"
      print self.subject + "\n"
      super
      print "5*********************\n"

    end
    
    def future_document
      if self.tracker == @@rqdoctrck then
        print "Este doc es un documento\n"
        ret = self 
      else
        # not do found yet
        ret = @parent_issue
        if ret != nil then
          print "retornamos el documento padre\n"
          print self.parent
          ret = ret.document
        end
      end
      return ret
    end

    def document
      ret = nil
      if self.tracker == @@rqdoctrck then
        print "Este doc es un documento\n"
        ret = self 
      else
        print "Este doc no es un documento\n"
        # not do found yet
        ret = self.parent
        if ret != nil then
          print "retornamos el documento padre\n"
          print self.parent
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
        print "vamos a crear un subject\n"
        if @@cfdoccount != nil then
          print "tenemos el custom field del contaddor\n"
          thisdocument = self.future_document
          if thisdocument != nil then
            print "Tenemos un documento\n"
            cfdoccount = thisdocument.custom_values.find_by_custom_field_id(@@cfdoccount.id)
            if cfdoccount != nil then
              print "vamos a buscar un prefijo\n"
              if @@cfdocprefix != nil then
                cfdocprefix = thisdocument.custom_values.find_by_custom_field_id(@@cfdocprefix.id)
                print "tenemos un prefijo\n"
                if cfdocprefix != nil then
                  self.subject = cfdocprefix.value+"-"+format('%04d', cfdoccount.value)
                  print "el subject me queda "+self.subject+"\n"
                  cfdoccount.value = (cfdoccount.value.to_i+1)
                  cfdoccount.save
                  print "guardado quedo\n"
                end
              end
            end
            return true 
          else
          end
        end
      end
      if self.subject=="INVALID_ID" then
        self.subject = nil
      end
      return false 
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


