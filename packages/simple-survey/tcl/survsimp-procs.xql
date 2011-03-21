<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_question_properties">      
      <querytext>
      
select
  survey_id,
  sort_key,
  question_text,
  abstract_data_type,
  required_p,
  active_p,
  presentation_type,
  presentation_options,
  presentation_alignment,
  creation_user,
  creation_date
from
  survsimp_questions, acs_objects
where
  object_id = question_id
  and question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_choices">      
      <querytext>
      select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order
      </querytext>
</fullquery>

 
<fullquery name="sursimp_question_choices_2">      
      <querytext>
      select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order
      </querytext>
</fullquery>

 
<fullquery name="sursimp_question_choices_3">      
      <querytext>
      select * from survsimp_question_choices
where question_id = :question_id
order by sort_order
      </querytext>
</fullquery>

 
<fullquery name="survsimp_label_list">      
      <querytext>
      select label
	    from survsimp_question_choices, survsimp_question_responses
	    where survsimp_question_responses.question_id = :question_id
	    and survsimp_question_responses.response_id = :response_id
	    and survsimp_question_choices.choice_id = survsimp_question_responses.choice_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_creator_p">      
      <querytext>
      
    select creation_user
    from   survsimp_surveys
    where  survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_responses_new">      
      <querytext>
      select survey_id, name, description, u.user_id, first_names || ' ' || last_name as creator_name, creation_date
from survsimp_surveys s, $users_table u
where s.creation_user = u.user_id
and creation_date> :since_when
order by creation_date desc
      </querytext>
</fullquery>

 
<fullquery name="survsimp_id_from_shortname">      
      <querytext>
      select survey_id from survsimp_surveys where lower(short_name) = lower(:short_name)
      </querytext>
</fullquery>

 
<fullquery name="get_response_id">      
      <querytext>
      
        select response_id
        from acs_objects, survsimp_responses
        where object_id = response_id
        and creation_user = :user_id
        and survey_id = :survey_id
        and creation_date = (select max(creation_date)
                             from survsimp_responses, acs_objects
                             where object_id = response_id
                             and creation_user = :user_id
                             and survey_id = :survey_id)                          
    
      </querytext>
</fullquery>

 
<fullquery name="get_score">      
      <querytext>
      
            select 
            sum(score) 
            from survsimp_choice_scores,
            survsimp_question_responses, survsimp_variables
            where
            survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
            and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
            and survsimp_question_responses.response_id = :response_id 
      </querytext>
</fullquery>

 
</queryset>
