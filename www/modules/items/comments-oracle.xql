<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_comments">      
      <querytext>
      
  select
    journal_id, action_pretty, msg, 
    decode(NVL(p.person_id, 0),
        0, 'System',
        substr(p.first_names, 1, 1) || '. ' || p.last_name) person,
    to_char(o.creation_date, 'MM/DD/YY HH24:MI:SS') when
  from
    journal_entries j, acs_objects o, persons p
  where
  (   
      j.object_id = :item_id
    or
      j.object_id in (select case_id from wf_cases c 
                      where c.object_id = :item_id)
  ) and
    j.journal_id = o.object_id
  and
    o.creation_user = p.person_id (+)
  and
    msg is not null
  and
    rownum < 11
  order by
    o.creation_date desc
  

      </querytext>
</fullquery>

 
</queryset>
