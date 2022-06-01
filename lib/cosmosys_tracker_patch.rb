require_dependency 'cosmosys_tracker'

module CosmosysTrackerPatch

  def childrentype(i)
    if i.tracker.name == "rq" then
      cftype = IssueCustomField.find_by_name('rqType')
      rqtypevalues = i.custom_values.where(custom_field_id: cftype.id)
      rqtype=rqtypevalues.first.value
      if (rqtype == "Info") then
        # return ["rqInfo","rqComplex","rqOpt","rqMech","rqHw","rqSw"]
        return cftype.possible_values.map{|v| "rq"+v}
      else
          return []
      end
    else
      if i.tracker.name == "prSys" then
        return ["prSys","prParam","prMode","prCmd"]
      else
        if i.tracker.name == "prParam" then
          return ["prValue","prValFloat","prValText","prMode"]
        else
          if ["prValue","prValFloat","prValText","prMode","prCmd"].include?(i.tracker.name) then
            return []
          else
            # Do nothing
            i.project.trackers.map{|t| t.name}
          end              
        end
      end
    end
  end

  def nodetype(i)
    if i.tracker.name == "rq" then
      cftype = IssueCustomField.find_by_name('rqType')
      rqtypevalues = i.custom_values.where(custom_field_id: cftype.id)
      return "rq"+rqtypevalues.first.value
    else
      return self.tracker.name
    end
  end

  def paint_pref
    if self.tracker.name == "rq" then
      return {
        :relation_color => {
          'blocks' => 'blue',
          'precedes' => 'green',
          'relates' => 'grey',
          'copied_to' => 'orange'
        },
        :shall_draw_relation => {
          'blocks' => true,
          'precedes' => true,
          'relates' => true,
          'copied_to' => true
        },
        :issue_color => {
          'normal' => 'black',
          'invalid' => 'red',
          'own' => 'blue',
        },
        :issue_shape => 'record',
        :chapter_shape => 'note',
        :hierankdir => 'TB',   
        :deprankdir => 'LR'
      }
    else
      if self.tracker.name == "prSys" then
        return {
          :relation_color => {
            'blocks' => 'blue',
            'precedes' => 'grey',
            'relates' => 'grey',
            'copied_to' => 'grey'
          },
          :shall_draw_relation => {
            'blocks' => true,
            'precedes' => false,
            'relates' => false,
            'copied_to' => false
          },
          :issue_color => {
            'normal' => 'black',
            'invalid' => 'red',
            'own' => 'black',
          },
          :issue_shape => 'record',
          :chapter_shape => 'note',
          :hierankdir => 'TB',
          :deprankdir => 'RL'
        }
      else
        if self.tracker.name == "prParam" then
          return {
            :relation_color => {
              'blocks' => 'blue',
              'precedes' => 'grey',
              'relates' => 'grey',
              'copied_to' => 'grey'
            },
            :shall_draw_relation => {
              'blocks' => true,
              'precedes' => false,
              'relates' => false,
              'copied_to' => false
            },          
            :issue_color => {
              'normal' => 'black',
              'invalid' => 'red',
              'own' => 'black',
            },        
            :issue_shape => 'record',
            :chapter_shape => 'note',
            :hierankdir => 'TB',
            :deprankdir => 'RL'
          }
        else
          if self.tracker.name == "prMode" then
            return {
              :relation_color => {
                'blocks' => 'blue',
                'precedes' => 'grey',
                'relates' => 'grey',
                'copied_to' => 'grey'
                },
              :shall_draw_relation => {
                'blocks' => true,
                'precedes' => false,
                'relates' => false,
                'copied_to' => false
              },          
              :issue_color => {
                'normal' => 'black',
                'invalid' => 'red',
                'own' => 'black',
              },        
              :issue_shape => 'Mrecord',
              :chapter_shape => 'note',
              :hierankdir => 'TB',
              :deprankdir => 'RL'
            }
          else
            if self.tracker.name == "prValFloat" or 
              self.tracker.name == "prValText" or 
              self.tracker.name == "prValue" then
                return {
                  :relation_color => {
                    'blocks' => 'blue',
                    'precedes' => 'grey',
                    'relates' => 'grey',
                    'copied_to' => 'grey'
                  },
                  :shall_draw_relation => {
                    'blocks' => true,
                    'precedes' => false,
                    'relates' => false,
                    'copied_to' => false
                  },          
                  :issue_color => {
                    'normal' => 'black',
                    'invalid' => 'red',
                    'own' => 'black',
                  },        
                  :issue_shape => 'record',
                  :chapter_shape => 'note',
                  :hierankdir => 'TB',
                  :deprankdir => 'RL'
                }
            else
              if self.tracker.name == "prCmd" then
                  return {
                    :relation_color => {
                      'blocks' => 'blue',
                      'precedes' => 'grey',
                      'relates' => 'grey',
                      'copied_to' => 'grey'
                    },
                    :shall_draw_relation => {
                      'blocks' => true,
                      'precedes' => false,
                      'relates' => false,
                      'copied_to' => false
                    },          
                    :issue_color => {
                      'normal' => 'black',
                      'invalid' => 'red',
                      'own' => 'black',
                    },        
                    :issue_shape => 'Mrecord',
                    :chapter_shape => 'note',
                    :hierankdir => 'TB',
                    :deprankdir => 'RL'
                  }
              else
                super
              end
            end
          end
        end
      end
    end
  end
end
# Add module to Issue
CosmosysTracker.send(:prepend, CosmosysTrackerPatch)
