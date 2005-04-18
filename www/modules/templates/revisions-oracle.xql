<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_revisions">      
      <querytext>
      
  select
    revision_id,
    to_char(o.creation_date, 'MM/DD/YY HH:MI AM') modified,
    round(r.content_length / 1000, 2) || ' KB' as file_size,
    decode(NVL(p.person_id, 0),
        0, '-',
        substr(p.first_names, 1, 1) || substr(p.last_name, 1, 1)) modified_by,
    nvl(j.msg, '-') msg
  from 
    cr_revisions r, acs_objects o, persons p, journal_entries j
  where
    item_id = :template_id
  and
    o.object_id = r.revision_id
  and
    o.creation_user = p.person_id (+)
  and
    o.object_id = j.journal_id (+)
  order by
    o.creation_date desc

      </querytext>
</fullquery>


</queryset>
