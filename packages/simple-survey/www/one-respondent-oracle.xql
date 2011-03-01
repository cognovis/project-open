<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="response_ids_select">      
      <querytext>
      
    select response_id, creation_date, to_char(creation_date, 'DD MONTH YYYY') as pretty_submission_date
    from survsimp_responses, acs_objects
    where survey_id = :survey_id
    and response_id = object_id
    and creation_user = :user_id
    order by creation_date desc

      </querytext>
</fullquery>

 
</queryset>
