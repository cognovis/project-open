<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_folder">      
      <querytext>
      
  select
    r.item_id, '' as context,
    case when o.object_type = 'content_symlink' then r.label 
         when o.object_type = 'content_folder'  then f.label
         else coalesce(v.title, i.name) end as title,
    case when r.item_id = :index_page_id then 't' 
                                         else 'f' end as is_index_page,
    coalesce(round(v.content_length::numeric / 1000.0, 2)::float8::text, '-') as file_size
  from 
    cr_items i 
        LEFT OUTER JOIN 
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN 
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id,
    cr_resolved_items r, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  order by
    is_index_page desc $orderby_clause
  
      </querytext>
</fullquery>


<partialquery name="display_data_partial">      
      <querytext>

  select
    case when i.content_type = 'content_folder' then 't' else'f' end as is_folder,
    case when i.content_type = 'content_template' then 't' else 'f' end as is_template,
    r.item_id, r.resolved_id, r.is_symlink, r.name,
    coalesce(trim(
      case when o.object_type = 'content_symlink' then r.label
           when o.object_type = 'content_folder' then f.label
	   else coalesce(v.title, i.name) end),'-') as title,
    case when i.publish_status = 'live' then to_char(u.publish_date, 'MM/DD/YYYY') else '-' end as publish_date,
    o.object_type, t.pretty_name as content_type,
    to_char(o.last_modified, 'MM/DD/YYYY HH24:MI') as last_modified_date,
    case when r.item_id = :index_page_id then 't' else 'f' end as is_index_page,
    coalesce(round(v.content_length::numeric / 1000.0, 2)::float8::text, '-') as file_size
  from 
    cr_items i
        LEFT OUTER JOIN
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id, 
    cr_resolved_items r, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  and
    -- paginator sql
    r.item_id in (CURRENT_PAGE_SET)
  order by
    is_index_page desc $orderby_clause
  
      </querytext>
</partialquery>

<fullquery name="get_resolved_id">      
      <querytext>
      
    select content_symlink__resolve( :id ) 
  
      </querytext>
</fullquery>

 
<fullquery name="get_index_page_id">      
      <querytext>
      
  select content_folder__get_index_page($parent_var) 

      </querytext>
</fullquery>

 
<fullquery name="get_symlinks">      
      <querytext>
      
  select
    i.item_id as id,
    content_item__get_path(i.item_id, null) as path
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
      parent_id, coalesce(label, name) as label, description
    from
      cr_items i, cr_folders f
    where
      i.item_id = f.folder_id
    and
      f.folder_id = :id
  
      </querytext>
</fullquery>

 
</queryset>
