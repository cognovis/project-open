<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="oacs_dav::conn_setup.get_item_id">
    <querytext>
      select content_item__get_id(:item_name,:parent_id,'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::children_have_permission_p.child_perms">
    <querytext>
            select count(*)
            from cr_items c1, cr_items c2
            where c2.item_id = :item_id
            and c1.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)
            and not  exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = cr_items.item_id
                     and m.party_id = :user_id
                     and m.privilege = :privilege)
    </querytext>
  </fullquery>
 
  <fullquery
    name="oacs_dav::impl::content_folder::propfind.get_properties">
    <querytext>
      select
      coalesce (cr.content_length,0) as content_length,
      coalesce(cr.mime_type,'*/*') as mime_type,
      to_char(timezone('GMT',o.creation_date) :: timestamptz ,'YYYY-MM-DD"T"HH:MM:SS.MS"Z"') as creation_date,
      to_char(timezone('GMT',o.last_modified) :: timestamptz ,'Dy, DD Mon YYYY HH:MM:SS TZ') as last_modified,
      ci1.item_id,
        case when ci1.item_id=ci2.item_id then '' else ci1.name end as name,
        content_item__get_path(ci1.item_id,:folder_id) as item_uri,
        case when o.object_type='content_folder' then 1 else 0 end
        as collection_p
      from
        cr_items ci1,
        cr_revisions cr,
        cr_items ci2,
        acs_objects o
      where
        ci1.live_revision = cr.revision_id and
        ci1.tree_sortkey between ci2.tree_sortkey and tree_right(ci2.tree_sortkey) and
        ci2.item_id=:folder_id and
        ci1.item_id = o.object_id and
        (tree_level(ci1.tree_sortkey) - tree_level(ci2.tree_sortkey)) <= :depth :: integer and
        exists (select 1
                  from acs_object_party_privilege_map m
                  where m.object_id = ci1.item_id
                  and m.party_id = :user_id
                  and m.privilege = 'read')
      union
      select 0 as content_length,
        '*/*' as mime_type,
        to_char(timezone('GMT',o.creation_date) :: timestamptz ,'YYYY-MM-DD"T"HH:MM:SS.MS"Z"') as creation_date,
        to_char(timezone('GMT',o.last_modified) :: timestamptz ,'Dy, DD Mon YYYY HH:MM:SS TZ') as last_modified,
        ci1.item_id,
        case when ci1.item_id=ci2.item_id then '' else ci1.name end as name,
        content_item__get_path(ci1.item_id,:folder_id) as item_uri,
        case when o.object_type='content_folder' then 1 else 0 end
        as collection_p
      from
        cr_items ci1,
        cr_items ci2,
        acs_objects o
      where
        ci1.tree_sortkey between ci2.tree_sortkey and tree_right(ci2.tree_sortkey) and
        ci2.item_id=:folder_id and
        ci1.item_id = o.object_id and
        (tree_level(ci1.tree_sortkey) - tree_level(ci2.tree_sortkey)) <= :depth :: integer and
        exists (select 1
                  from acs_object_party_privilege_map m
                  where m.object_id = ci1.item_id
                  and m.party_id = :user_id
                  and m.privilege = 'read') and
        not exists (select 1
                  from cr_revisions cr
                  where cr.revision_id = ci1.live_revision)
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_revision::propfind.get_properties">
    <querytext>
      select
	ci.item_id,
	ci.name,
	content_item__get_path(ci.item_id,:folder_id) as item_uri,
	coalesce(cr.mime_type,'*/*') as mime_type,
	coalesce(cr.content_length,0) as content_length,
	to_char(timezone('GMT',o.creation_date) :: timestamptz ,'YYYY-MM-DD"T"HH:MM:SS.MS"Z"') as creation_date,
	to_char(timezone('GMT',o.last_modified) :: timestamptz ,'Dy, DD Mon YYYY HH:MM:SS TZ') as last_modified
      from cr_items ci,
      acs_objects o,
      cr_revisions cr
      where 
      ci.item_id=:item_id
      and ci.item_id = o.object_id
      and cr.revision_id=ci.live_revision
      and exists (select 1
                  from acs_object_party_privilege_map m
                  where m.object_id = ci.item_id
                  and m.party_id = :user_id
                  and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::mkcol.create_folder">
    <querytext>
      select content_folder__new(
          :new_folder_name,
          :label,
          :description,
          :parent_id,
          :parent_id,
          NULL,
          current_timestamp,
          :user_id,
          :peer_addr
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.copy_folder">
    <querytext>
      select content_folder__copy (
      :copy_folder_id,
      :new_parent_folder_id,
      :user_id,
      :peer_addr,
      :new_name
      )
    </querytext>
  </fullquery>

    <fullquery name="oacs_dav::impl::content_folder::copy.update_child_revisions">
      <querytext>
	update cr_items 
	set live_revision = latest_revision
	where exists (
		select 1 
		from
		(select ci1.item_id as child_item_id 
                from cr_items ci1, cr_items ci2
		where ci2.item_id=:new_folder_id
	        and ci1.tree_sortkey 
	        between ci2.tree_sortkey and tree_right(ci2.tree_sortkey)
                ) children 
                where item_id=children.child_item_id 
                      )
      </querytext>
    </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.move_folder">
    <querytext>
      select content_folder__move (
      :move_folder_id,
      :new_parent_folder_id,
      :new_name
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.rename_folder">
    <querytext>
      select content_folder__edit_name (
      :move_folder_id,
      :new_name,
      :new_name,
      NULL
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.move_item">
    <querytext>
      select content_item__move (
      :item_id,
      :new_parent_folder_id,
      :new_name
      )
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_revision::move.rename_item">
    <querytext>
      select content_item__edit_name (
      :item_id,
      :new_name
      )
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.copy_item">
    <querytext>
      select content_item__copy (
      :copy_item_id,
      :new_parent_folder_id,
      :user_id,
      :peer_addr,
      :new_name
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::copy.delete_for_copy">
    <querytext>
      select content_item__delete(:dest_item_id)
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::move.delete_for_move">
    <querytext>
      select content_item__delete(:dest_item_id)
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::delete.delete_item">
    <querytext>
      select content_item__delete (
      :item_id
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::delete.delete_folder">
    <querytext>
      select content_folder__delete (
      :item_id,
      't'
      )
    </querytext>
  </fullquery>


  <fullquery name="oacs_dav::item_parent_folder_id.get_parent_folder_id">
    <querytext>
      select content_item__get_id(:parent_name,:root_folder_id,'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.get_dest_id">
    <querytext>
	select content_item__get_id(:new_name,:new_parent_folder_id,'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.get_dest_id">
    <querytext>
	select content_item__get_id(:new_name,:new_parent_folder_id,'f')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::move.delete_for_move">
    <querytext>
      select content_folder__delete(:dest_item_id,'t');
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::copy.delete_for_copy">
    <querytext>
      select content_folder__delete(:dest_item_id,'t');
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.get_dest_id">
    <querytext>
	select content_item__get_id(:new_name,:new_parent_folder_id,'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.get_dest_id">
    <querytext>
	select content_item__get_id(:new_name,:new_parent_folder_id,'f')
    </querytext>
  </fullquery>

</queryset>

