<?xml version="1.0"?>
<queryset>

<fullquery name="survey_exists">      
      <querytext>
      
	    select 1 from survsimp_surveys where survey_id = :survey_id
	
      </querytext>
</fullquery>

 
<fullquery name="survey_info">      
      <querytext>
      select name, description, single_response_p, single_editable_p, display_type
    from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="responses_count">      
      <querytext>
      
    select count(response_id)
    from survsimp_responses, acs_objects
    where response_id = object_id
    and creation_user = :user_id
    and survey_id = :survey_id

      </querytext>
</fullquery>

 
<fullquery name="question_ids_select">      
      <querytext>
      
    select question_id
    from survsimp_questions  
    where survey_id = :survey_id
    and active_p = 't'
    order by sort_key

      </querytext>
</fullquery>

 
</queryset>
