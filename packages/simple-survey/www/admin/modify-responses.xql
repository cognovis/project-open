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

 
<fullquery name="get_variable_names">      
      <querytext>
      select variable_name, survsimp_variables.variable_id as variable_id
  from survsimp_variables, survsimp_variables_surveys_map
  where survsimp_variables.variable_id = survsimp_variables_surveys_map.variable_id
  and survey_id = :survey_id
  order by variable_name
      </querytext>
</fullquery>

 
<fullquery name="get_choices">      
      <querytext>
      select choice_id, label from survsimp_question_choices where question_id = :question_id order by choice_id
      </querytext>
</fullquery>

 
<fullquery name="get_scores">      
      <querytext>
      select score, survsimp_variables.variable_id as variable_id
      from survsimp_choice_scores, survsimp_variables
      where survsimp_choice_scores.choice_id = :choice_id
      and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
      order by variable_name
      </querytext>
</fullquery>

 
</queryset>
