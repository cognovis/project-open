<?xml version="1.0"?>
<queryset>

<fullquery name="survey_name_from_id">      
      <querytext>
      select name from survsimp_surveys where survey_id=:survey_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_text_from_id">      
      <querytext>
      select question_text
from survsimp_questions
where question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>
