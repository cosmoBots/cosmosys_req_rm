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

    def csys_req
      if self.csys_req == nil then
        CosmosysReq.create!(cosmosys_issue:self)
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
