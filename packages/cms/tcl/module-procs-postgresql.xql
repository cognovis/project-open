<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cm::modules::users::getSortedPaths.users_get_paths">      
      <querytext>

          select 
            o.object_id as item_id,
            o.object_type || ': ' || acs_object__name(o.object_id) as item_path,
            o.object_type as item_type
          from
            acs_objects o, parties p
          where
            o.object_id = p.party_id
          and
            o.object_id in ($sql_id_list)
          order by
            item_path

     </querytext>
</fullquery>


<fullquery name="cm::modules::sitemap::getSortedPaths.sitemap_get_name">      
      <querytext>

       select 
         item_id, 
         content_item__get_path(item_id, :sorted_paths_root_id) as item_path,
         content_type as item_type
       from 
         cr_items
       where
         item_id in ($sql_id_list)
       order by item_path
       

      </querytext>
</fullquery>

<fullquery name="cm::modules::categories::getSortedPaths.get_paths">      
      <querytext>
           
          select 
            keyword_id as item_id,
            content_keyword__get_path(keyword_id) as item_path,
            'content_keyword' as item_type
          from
            cr_keywords
          where 
            keyword_id in ($sql_id_list)

      </querytext>
</fullquery>

<fullquery name="cm::modules::getChildFolders.module_get_result">      
      <querytext>
      
        select
	  :mount_point as mount_point,
	  r.name, 
          r.item_id,
          '' as children,
	  coalesce((select 't'::text  where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = r.resolved_id
		 and f_child.folder_id = r_child.resolved_id)), 'f') as expandable,
	  r.is_symlink as symlink, 
          0 as update_time
	from
	  cr_folders f, cr_resolved_items r
	where
	  r.parent_id = :id
	and
	  r.resolved_id = f.folder_id
	order by
	  name
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::templates::getRootFolderID.template_get_root_id">      
      <querytext>
      
            select content_template__get_root_folder() 
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::sitemap::getRootFolderID.sitemap_get_root_id">      
      <querytext>
      
            select content_item__get_root_folder(null) 
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::types::getTypesTree.types_get_result">      
      <querytext>

          select
            lpad(' ', tree_level(t.tree_sortkey), '-') || t.pretty_name as label,
            t.object_type as value
          from
            acs_object_types t, acs_object_types t2
          where t2.object_type = 'content_revision'
            and t.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
        
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::types::getChildFolders.get_result">      
      <querytext>

                select
                     :module_name as mount_point,
                     t.pretty_name, 
                     t.object_type,
                     '' as children,
                     coalesce(
                      (select 't'::text
                        where exists (select 1 from acs_object_types
                          where supertype = t.object_type)),
                      'f'
                     ) as expandable,
                     'f' as symlink, 
                     0 as update_time
                   from 
                     acs_object_types t
                   where 
                     supertype = :id
                   order by 
                     t.pretty_name
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::categories::getChildFolders.category_get_children">      
      <querytext>

                  select 
                     :module_name as mount_point,
                     content_keyword__get_heading(keyword_id) as name, 
                     keyword_id, 
                     '' as children,
                     coalesce( (select 't'::text
                             where exists (
                               select 1 from cr_keywords k2
                                 where k2.parent_id = k.keyword_id
                                   and content_keyword__is_leaf(k2.keyword_id) = 'f')),
                           'f') as expandable,
                     'f' as symlink,
                     0 as update_time           
                   from 
                     cr_keywords k
                   where 
                     $where_clause
                   and
                     content_keyword__is_leaf(keyword_id) = 'f'
                   order by 
                     name
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::users::getChildFolders.users_get_result">      
      <querytext>

                 select
                     :module_name as mount_point,
                     g.group_name as name, 
                     g.group_id, '' as children,
                     coalesce(
                      (select 't'::text  
                        where exists (
                          select 1 from group_component_map m2
                          where m2.group_id = g.group_id)),
                      'f'::text 
                     ) as expandable,
                     'f' as symlink,
                     0 as update_time
                   from 
                     groups g $map_table
                   where 
                     $where_clause
                   order by 
                     name
      </querytext>
</fullquery>

 
</queryset>
