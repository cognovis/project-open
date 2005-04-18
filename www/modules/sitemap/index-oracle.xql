<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_folder">      
      <querytext>
      
  select
    r.item_id, '' as context,
    decode(o.object_type, 'content_symlink', r.label,
			  'content_folder', f.label,
			  nvl(v.title, i.name)) title,
    decode(r.item_id, :index_page_id, 't', 'f') is_index_page,
    nvl(to_char(round(v.content_length / 1000, 2)), '-') file_size
  from 
    cr_resolved_items r, cr_items i, cr_folders f, cr_revisions v, 
    cr_revisions u, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  and
    i.latest_revision = v.revision_id (+)
  and
    i.live_revision = u.revision_id (+)
  and
    i.item_id = f.folder_id (+)
  order by
    is_index_page desc $orderby_clause
  
      </querytext>
</fullquery>

<partialquery name="display_data_partial">      
      <querytext>

  select
    decode(i.content_type, 'content_folder', 't', 'f') is_folder,
    decode(i.content_type, 'content_template', 't', 'f') is_template,
    r.item_id, r.resolved_id, r.is_symlink, r.name,
    NVL(trim(
      decode(o.object_type, 'content_symlink', r.label,
			  'content_folder', f.label,
			  nvl(v.title, i.name))),
      '-') title,
    decode(i.publish_status, 'live', 
      to_char(u.publish_date, 'MM/DD/YYYY'), '-') publish_date,
    o.object_type, t.pretty_name content_type,
    to_char(o.last_modified, 'MM/DD/YYYY HH24:MI') last_modified_date,
    decode(r.item_id, :index_page_id, 't', 'f') is_index_page,
    nvl(to_char(round(v.content_length / 1000, 2)), '-') file_size
  from 
    cr_resolved_items r, cr_items i, cr_folders f, cr_revisions v, 
    cr_revisions u, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  and
    i.latest_revision = v.revision_id (+)
  and
    i.live_revision = u.revision_id (+)
  and
    i.item_id = f.folder_id (+)
  and
    -- paginator sql
    r.item_id in (CURRENT_PAGE_SET)
  order by
    is_index_page desc $orderby_clause
  
      </querytext>
</partialquery>

<fullquery name="get_resolved_id">      
      <querytext>
      
    select content_symlink.resolve( :id ) from dual
  
      </querytext>
</fullquery>

 
<fullquery name="get_index_page_id">      
      <querytext>
      
  select content_folder.get_index_page($parent_var) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_symlinks">      
      <querytext>
      
  select
    i.item_id id,
    content_item.get_path(i.item_id) path
  from 
    cr_items i, cr_symlinks s
  where
    i.item_id = s.target_id
  and
    i.item_id = :original_id

      </querytext>
</fullquery>

<fullquery name="get_info">      
      <querytext>
      
    select
      parent_id, NVL(label, name) label, description
    from
      cr_items i, cr_folders f
    where
      i.item_id = f.folder_id
    and
      f.folder_id = :id
  
      </querytext>
</fullquery>
 
</queryset>
