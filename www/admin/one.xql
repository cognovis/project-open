<?xml version="1.0"?>
<queryset>

<fullquery name="sursimp_survey_questions">      
      <querytext>
      select question_id, sort_key, active_p, required_p
from survsimp_questions
where survey_id = :survey_id  
order by sort_key
      </querytext>
</fullquery>

 
</queryset>
