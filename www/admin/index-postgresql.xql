<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_folder_contents_paginate">      
      <querytext>

  select
    r.item_id, v.title, last_modified,
	o.creation_user as latest_creation_user,
	acs_object__name(o.creation_user) as latest_creation_user_name
  from 
    cr_items i
        LEFT OUTER JOIN
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id, 
    cr_resolved_items r, acs_objects o
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
   [template::list::orderby_clause -name folder_items -orderby]

      </querytext>
</fullquery>





<fullquery name="get_folder_contents">      
      <querytext>

  select
	r.item_id, 
	r.item_id as id, 

	v.revision_id as latest_revision_id, 
    	v.content_length,
	v.content_length as latest_length,
	v.publish_date as latest_publish_date,
	ro.creation_user as latest_creation_user,
	acs_object__name(ro.creation_user) as latest_creation_user_name,

	u.revision_id as live_revision_id, 
	u.publish_date as live_publish_date,
	u.content_length as live_length,

	r.resolved_id, 
	r.is_symlink,
	r.name, 

	i.parent_id, 
	i.content_type, 
	i.publish_status, 
	t.pretty_name as pretty_content_type, 
	o.last_modified, 
	coalesce(trim(
	    case 
		when i.content_type = 'content_symlink' then r.label
		when i.content_type = 'content_folder' then f.label
		else coalesce(v.title, i.name) 
		end
	),'-') as title
  from 
    cr_items i
        LEFT OUTER JOIN
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id, 
    cr_resolved_items r, acs_objects o, acs_object_types t, acs_objects ro
  where
	r.parent_id = $parent_var
	$modified_only_where
	and r.resolved_id = i.item_id
	and i.item_id = o.object_id
	and v.revision_id = ro.object_id
	and i.content_type = t.object_type
	[template::list::page_where_clause -and -name folder_items -key r.item_id]
	[template::list::orderby_clause -name folder_items -orderby]

      </querytext>
</fullquery>


<fullquery name="get_resolved_id">      
      <querytext>
      
    select content_symlink__resolve( :folder_id ) 
  
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
    i.item_id = :original_folder_id

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
      f.folder_id = :folder_id
  
      </querytext>
</fullquery>

 
</queryset>
