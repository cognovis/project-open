<?xml version="1.0"?>
<queryset>

<fullquery name="survey_properites">      
      <querytext>
      select name as survey_name, description, description_html_p as desc_html
from survsimp_surveys
where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
