<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_id">      
      <querytext>


        select 
        content_item.get_id(:path, content_template.get_root_folder) 
        from dual

      </querytext>
</fullquery>

 
<fullquery name="get_root_folder_id">      
      <querytext>

        select content_template.get_root_folder from dual

      </querytext>
</fullquery>

<fullquery name="get_path">      
      <querytext>

        select content_item.get_path(:id) from dual

      </querytext>
</fullquery>

<fullquery name="get_items">      
      <querytext>

  select
    t.template_id, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') modified,
    nvl(round(r.content_length / 1000, 2), 0) || ' KB' as file_size
  from
    cr_templates t, cr_items i, acs_objects o, cr_revisions r
  where
    i.parent_id = :id
  and
    i.item_id = t.template_id
  and
    i.item_id = o.object_id
  and
    i.latest_revision = r.revision_id (+)
  order by
    upper(i.name)
 
      </querytext>
</fullquery>


</queryset>
