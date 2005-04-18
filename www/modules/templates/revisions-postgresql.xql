<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_revisions">      
      <querytext>
      
  select
    revision_id,
    to_char(o.creation_date, 'MM/DD/YY HH:MI AM') as modified,
    (round(r.content_length::numeric / 1000.0,2)::float8::text || ' KB'::text) as file_size,
    case when coalesce(p.person_id, 0) = 0 
            then '-' 
            else substr(p.first_names, 1, 1) || substr(p.last_name, 1, 1) end as modified_by,
    coalesce(j.msg, '-') as msg
  from 
    cr_revisions r, 
    acs_objects o 
      LEFT OUTER JOIN 
    journal_entries j ON o.object_id = j.journal_id 
      LEFT OUTER JOIN 
    persons p ON o.creation_user = p.person_id
  where
    item_id = :template_id
  and
    o.object_id = r.revision_id
  order by
    o.creation_date desc

      </querytext>
</fullquery>


</queryset>
