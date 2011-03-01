<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="response_ids_select">      
      <querytext>
    select response_id, creation_date, to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') as submission_date_ansi
    from survsimp_responses, acs_objects
    where survey_id = :survey_id
    and response_id = object_id
    and creation_user = :user_id
    order by creation_date desc

      </querytext>
</fullquery>

 
</queryset>
