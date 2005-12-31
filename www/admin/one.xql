<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_properties">      
      <querytext>
select name as survey_name, 
short_name, description as survey_description, 
first_names || ' ' || last_name as creator_name, creation_user, 
creation_date, (case when enabled_p = 't' then 'Enabled' when enabled_p = 'f' then 'Disabled' end) as survey_status, enabled_p,
(case when single_response_p = 't' then 'One' when single_response_p = 'f' then 'Multiple' end) as survey_response_limit,
(case when single_editable_p = 't' then 'Editable' when single_editable_p = 'f' then 'Non-editable' end) as survey_editable_single, type,display_type
from survsimp_surveys, acs_objects, persons
where object_id = survey_id
and person_id = creation_user
and survey_id = :survey_id
and package_id= :package_id
      </querytext>
</fullquery>

 
<fullquery name="sursimp_survey_questions">      
      <querytext>
      select question_id, sort_key, active_p, required_p
from survsimp_questions
where survey_id = :survey_id  
order by sort_key
      </querytext>
</fullquery>

 
</queryset>
