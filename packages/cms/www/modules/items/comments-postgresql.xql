<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_comments">      
      <querytext>

  select
    journal_id, action_pretty, msg, 
    case when coalesce(p.person_id, 0) = 0 
              then 'System' 
              else 
                   substr(p.first_names, 1, 1) || '. ' || p.last_name 
         end as person,
    to_char(o.creation_date, 'MM/DD/YY HH24:MI:SS') as when
  from
    journal_entries j, acs_objects o left outer join persons p on o.creation_user = p.person_id 
  where
  (   
      j.object_id = :item_id
    or
      j.object_id in (select case_id from wf_cases c 
                      where c.object_id = :item_id)
  ) and
    j.journal_id = o.object_id
  and
    msg is not null
  order by
    o.creation_date desc
  limit 10

      </querytext>
</fullquery>

 
</queryset>
