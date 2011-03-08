<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="all_responses_to_question">      
      <querytext>
      
select
  $column_name as response,
  person.name(o.creation_user) as respondent_name,
  o.creation_date as submission_date,
  o.creation_ip as ip_address
from
  survsimp_responses r,
  survsimp_question_responses qr,
  acs_objects o
where
  qr.response_id = r.response_id
  and qr.question_id = :question_id
  and o.object_id = qr.response_id
  order by submission_date

      </querytext>
</fullquery>

 
</queryset>
