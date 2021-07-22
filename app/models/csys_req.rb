class CsysReq < ActiveRecord::Base
    belongs_to :issue

    @@reqtracker = Tracker.find_by_name('rq')
    @@req_status_maturity = {
        'rqDraft': 1,
        'rqStable': 2,
        'rqApproved': 3,
        'rqRejected': 0,
        'rqErased': 0,
        'rqZombie': 0
      }
    
    def self.dependence_validation(i)
    result = true
    if (i.tracker == @@reqtracker) then
        i.relations_to.each{|r|
        rel_issue = r.issue_from
        result = self.dependence_validation(rel_issue)
        if (result) then
            if (@@req_status_maturity[rel_issue.status.name.to_sym] < 
                @@req_status_maturity[i.status.name.to_sym]) then
            #print("\n\n**************")
            #print(i.id,": ",i.subject,": ",i.status,":",@@req_status_maturity[i.status.name].to_s)
            #print("\t-",r.relation_type,"-> ",rel_issue.subject," : ",rel_issue.status,":",@@req_status_maturity[rel_issue.status.name].to_s)
            #print("xxxxxxxxxxxx: Error.  el requisito dependiente está en estado ",i.status," mientras el requisito del que depende está en estado ",rel_issue.status)
            result = false
            end
        end
        }
    end
    #print("\n\nResult: "+result.to_s)
    return result 
    end

    def self.dependence_validation_from_id(id)
        i = Issue.find(id)
        self.dependence_validation(i)
    end    
end
