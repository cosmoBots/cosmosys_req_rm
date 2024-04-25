class CsysReq < ActiveRecord::Base
    belongs_to :cosmosys_issue

    @@reqtracker = Tracker.find_by_name('rq')
    @@req_status_maturity = {
        'rqDraft': 1,
        'rqStable': 2,
        'rqApproved': 3,
        'rqRejected': 0,
        'rqErased': 0,
        'rqZombie': 0
      }

    def is_valid?
        result = true
        i = self.cosmosys_issue.issue
        if (i.tracker == @@reqtracker) then
            ischapter = self.cosmosys_issue.is_chapter?
            i.relations_to.each{|r|
                if result then
                    if r.relation_type == 'blocks' then
                        if ischapter then
                            result = false
                        else
                            rel_issue = r.issue_from
                            result = rel_issue.csys.is_valid?
                            if (result) then
                                mat_rel = @@req_status_maturity[rel_issue.status.name.to_sym]
                                if mat_rel == nil then
                                    mat_rel = 0
                                end
                                mat = @@req_status_maturity[i.status.name.to_sym]
                                if mat == nil then
                                    mat = 0
                                end
                                if ( mat_rel < mat) then
                                #print("\n\n**************")
                                #print(i.id,": ",i.subject,": ",i.status,"/\n",@@req_status_maturity[i.status.name].to_s)
                                #print("\t-",r.relation_type,"-> ",rel_issue.subject," : ",rel_issue.status,"/\n",@@req_status_maturity[rel_issue.status.name].to_s)
                                #print("xxxxxxxxxxxx: Error.  el requisito dependiente está en estado ",i.status," mientras el requisito del que depende está en estado ",rel_issue.status)
                                result = false
                                end
                            end
                        end
                    end
                end
            }
            return result
        else
            return true
        end
        #print("\n\nResult: "+result.to_s)
    end
end
