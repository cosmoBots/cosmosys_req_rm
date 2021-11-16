require_dependency 'cosmosys_tracker'

module CosmosysTrackerPatch
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
          'copied_to' => false
        },
        :issue_color => {
          'normal' => 'black',
          'invalid' => 'red',
          'own' => 'blue',
        },
        :issue_shape => 'record',
        :chapter_shape => 'note'
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
          :chapter_shape => 'note'
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
            :chapter_shape => 'note'
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
              :chapter_shape => 'note'
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
                  :chapter_shape => 'note'
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
# Add module to Issue
CosmosysTracker.send(:prepend, CosmosysTrackerPatch)
