<?xml version="1.0"?>
<queryset>

<fullquery name="one_question">      
      <querytext>
      
  select question_text, survey_id
  from survsimp_questions
  where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="abstract_data_type">      
      <querytext>
      select abstract_data_type
from survsimp_questions q
where question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>
