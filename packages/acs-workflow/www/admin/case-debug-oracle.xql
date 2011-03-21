<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="case_info">      
      <querytext>
      
    select case_id, acs_object.name(object_id) as object_name, state as state from wf_cases where case_id = :case_id

      </querytext>
</fullquery>

 
<fullquery name="attributes">      
      <querytext>
      
    select a.attribute_name as name, acs_object.get_attribute(c.case_id, a.attribute_name) as value
    from   acs_attributes a, wf_cases c
    where  a.object_type = c.workflow_key
    and    c.case_id = :case_id

      </querytext>
</fullquery>

 
<fullquery name="dead_tokens">      
      <querytext>
      
    select token_id, place_key, case_id, state, locked_task_id,
           to_char(produced_date, 'YYYY-MM-DD HH24:MI:SS') as produced_date_pretty,
           to_char(locked_date, 'YYYY-MM-DD HH24:MI:SS') as locked_date_pretty,
           to_char(consumed_date, 'YYYY-MM-DD HH24:MI:SS') as consumed_date_pretty,
           to_char(canceled_date, 'YYYY-MM-DD HH24:MI:SS') as canceled_date_pretty
    from   wf_tokens
    where  case_id = :case_id
    and    state in ('consumed', 'canceled')

      </querytext>
</fullquery>

 
</queryset>
