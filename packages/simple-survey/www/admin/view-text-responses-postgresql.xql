<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="all_responses_to_question">      
      <querytext>
      
select
  $column_name as response,
  person__name(acs_object__get_attribute(r.response_id,'creation_user')::text::integer) as respondent_name,
  acs_object__get_attribute(r.response_id,'creation_date') as submission_date,
  acs_object__get_attribute(r.response_id,'creation_ip') as ip_address
from
  survsimp_responses r,
  survsimp_question_responses qr
where
  qr.response_id = r.response_id
  and qr.question_id = :question_id
  order by submission_date

      </querytext>
</fullquery>

 
</queryset>
