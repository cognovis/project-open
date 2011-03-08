<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_survey_properties">      
      <querytext>
      select name as survey_name, description, type
from survsimp_surveys
where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="user_name_from_id">      
      <querytext>
      select first_names, last_name from persons where person_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_survey_response_dates_for_users">      
      <querytext>
      select response_id, creation_date 
from survsimp_responses, acs_objects
where response_id = object_id
and creation_user = :user_id
and survey_id = :survey_id
order by creation_date desc
      </querytext>
</fullquery>

 
<fullquery name="get_survey_scores">      
      <querytext>
      select variable_name, sum(score) as sum_score
	      from survsimp_choice_scores, survsimp_question_responses, survsimp_variables
	      where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
	      and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
	      and survsimp_question_responses.response_id = :response_id
	      group by variable_name
      </querytext>
</fullquery>

 
</queryset>
