<?xml version="1.0"?>
<queryset>

<fullquery name="survey_active_toggle">      
      <querytext>
      update survsimp_surveys 
    set enabled_p = :enabled_p 
    where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
