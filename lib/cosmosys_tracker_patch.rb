require_dependency 'cosmosys_tracker'

module CosmosysTrackerPatch
  def paint_pref
    if self.tracker.name == "rq" then
      return {
        :relation_color => {
          'blocks' => 'blue',
          'precedes' => 'grey',
          'relates' => 'green',
          'copied_to' => 'orange'
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
      super
    end
  end
end
# Add module to Issue
CosmosysTracker.send(:prepend, CosmosysTrackerPatch)
