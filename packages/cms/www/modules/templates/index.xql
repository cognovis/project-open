<?xml version="1.0"?>

<queryset>

<fullquery name="get_type">      
      <querytext>

        select content_type from cr_items where item_id = :id
 
      </querytext>
</fullquery>

<fullquery name="get_parent">      
      <querytext>

  select
    f.folder_id, f.label, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') as modified
  from
    cr_folders f, cr_items i, acs_objects o
  where
    i.item_id = (select parent_id from cr_items where item_id = :id)
  and
    i.item_id = f.folder_id
  and
    i.item_id = o.object_id
 
      </querytext>
</fullquery>

<fullquery name="get_folders">      
      <querytext>

  select
    f.folder_id, f.label, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') as modified
  from
    cr_folders f, cr_items i, acs_objects o
  where
    i.parent_id = :id
  and
    i.item_id = f.folder_id
  and
    i.item_id = o.object_id
  order by
    upper(f.label), upper(i.name) 

      </querytext>
</fullquery>

</queryset>
