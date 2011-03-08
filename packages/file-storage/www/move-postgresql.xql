<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">

<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2004-05-09 -->
<!-- @cvs-id $Id: move-postgresql.xql,v 1.8 2008/12/09 09:02:31 gustafn Exp $ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="get_move_objects">
    <querytext>
      select fs.object_id, fs.name, fs.type, fs.parent_id,
      acs_permission__permission_p(fs.object_id, :user_id, 'delete') as move_p
      from fs_objects fs
      where fs.object_id in ([template::util::tcl_to_sql_list $object_id])
	order by move_p
    </querytext>
  </fullquery>

  <fullquery name="move_item">
    <querytext>
      select content_item__move(
           :object_id,
           :folder_id
      )
    </querytext>
  </fullquery>

  <fullquery name="get_folder_tree">
    <querytext>
      select
      cf.folder_id, ci1.parent_id, cf.label, tree_level(ci1.tree_sortkey) as level_num
      from cr_folders cf, cr_items ci1, cr_items ci2
      where
      ci1.tree_sortkey between ci2.tree_sortkey and
                               tree_right(ci2.tree_sortkey)
      and ci2.item_id=:root_folder_id
      and ci1.item_id=cf.folder_id
      and exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = cf.folder_id
                     and m.party_id = :user_id
                     and m.privilege = 'write')
      order by ci1.tree_sortkey, cf.label
    </querytext>
  </fullquery>

   <fullquery name="copy_item"> 	 
     <querytext> 	 
       select file_storage__copy_file( 	 
            :object_id, 	 
            :folder_id, 	 
            :user_id, 	 
            :peer_addr 	 
       ) 	 
     </querytext> 	 
   </fullquery> 	 
  	 
   <fullquery name="copy_folder"> 	 
     <querytext> 	 
       select content_folder__copy ( 	 
            :object_id, 	 
            :folder_id, 	 
            :user_id, 	 
            :peer_addr 	 
       ) 	 
     </querytext> 	 
   </fullquery>
  
</queryset>
