<?xml version="1.0"?>
<queryset>

<fullquery name="simpsurv_survey_properties">      
      <querytext>
      select name, description, type
from survsimp_surveys
where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
