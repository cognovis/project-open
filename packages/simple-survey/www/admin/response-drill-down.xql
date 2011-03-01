<?xml version="1.0"?>
<queryset>

<fullquery name="get_question_text">      
      <querytext>
      
select survey_id, question_text
from survsimp_questions
where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="get_response_text">      
      <querytext>
      
select label as response_text
from survsimp_question_choices
where choice_id = :choice_id
      </querytext>
</fullquery>

 
<fullquery name="survey_name">      
      <querytext>
      select name from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="all_users_for_response">      
      <querytext>
      
select
  first_names || ' ' || last_name as responder_name,
  person_id,
  creation_date
from
  acs_objects,
  survsimp_responses sr,
  persons u,
  survsimp_question_responses qr
where
  qr.response_id = sr.response_id
  and qr.response_id = object_id
  and creation_user = person_id
  and qr.question_id = :question_id
  and qr.choice_id = :choice_id
      </querytext>
</fullquery>

 
</queryset>
