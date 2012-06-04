<?xml version="1.0"?>
<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
  <fullquery name="oacs_dav::conn_setup.get_item_id">
    <querytext>
	begin
	      :1 := content_item.get_id(
        	      item_path => :item_name,
	              root_folder_id => :parent_id,
        	      resolve_index => 'f');
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::children_have_permission_p.child_perms">
    <querytext>
            select count(*)
            from (select item_id 
                  from cr_items
	          connect by prior item_id = parent_id
	          start with item_id = :item_id)
            where not  exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = cr_items.item_id
                     and m.party_id = :user_id
                     and m.privilege = :privilege)
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::propfind.get_properties">
    <querytext>
      select nvl (cr.content_length,0) as content_length,
	nvl (cr.mime_type,'*/*') as mime_type,
	to_char(o.creation_date, 'YYYY-MM-DD"T"HH:MI:SS."000"') as creation_date,
	to_char(o.last_modified, 'Dy, Dd Mon YYYY HH:MI:SS "${os_time_zone}"') as last_modified,
	ci1.item_id,
	case when ci1.item_id=:folder_id then '' else ci1.name end as name,
	content_item.get_path(ci1.item_id,:folder_id) as item_uri,
	case when o.object_type='content_folder' then 1 else 0 end
	as collection_p
      from (
		select * from cr_items
		where (parent_id=:folder_id
		or item_id=:folder_id)
		and level <= :depth + 1
		connect by prior item_id=parent_id
		start with item_id=:folder_id
	) ci1,
      cr_revisions cr, 
      acs_objects o
     where 
      ci1.item_id=o.object_id 
     and ci1.live_revision = cr.revision_id(+)
     and exists (select 1
                  from acs_object_party_privilege_map m
                  where m.object_id = ci1.item_id
                  and m.party_id = :user_id
                  and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_revision::propfind.get_properties">
    <querytext>
      select
	ci.item_id,
	ci.name,
	content_item.get_path(ci.item_id,:folder_id) as item_uri,
	nvl(cr.mime_type,'*/*') as mime_type,
	nvl(cr.content_length,0) as content_length,
	to_char(o.creation_date, 'YYYY-MM-DD"T"HH:MI:SS."000"') as creation_date,
	to_char(o.last_modified, 'Dy, Dd Mon YYYY HH:MI:SS "${os_time_zone}"') as last_modified

      from cr_items ci,
      acs_objects o,
      cr_revisions cr
      where 
      ci.item_id=:item_id
      and ci.item_id = o.object_id
      and cr.revision_id=ci.live_revision
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::mkcol.create_folder">
    <querytext>
	begin
	      :1 := content_folder.new(
              name => :new_folder_name,
              label => :label,
              description => :description,
              parent_id => :parent_id,
              context_id => :parent_id,
              folder_id => NULL,
              creation_date => sysdate,
              creation_user => :user_id,
              creation_ip => :peer_addr
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.copy_folder">
    <querytext>
	begin
	      content_folder.copy (
	              folder_id => :copy_folder_id,
	              target_folder_id => :new_parent_folder_id,
	              creation_user => :user_id,
	              creation_ip => :peer_addr,
	              name => :new_name
	      );
	end;
    </querytext>
  </fullquery>

    <fullquery name="oacs_dav::impl::content_folder::copy.update_child_revisions">
      <querytext>
	update cr_items 
	set live_revision=latest_revision
	where exists (
		select 1 
		from
		(select ci1.item_id as child_item_id 
                from cr_items ci1
	        connect by prior item_id = parent_id
                start with item_id = :folder_id
                ) children 
                where item_id=children.child_item_id 
                      )
      </querytext>
    </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.move_folder">
    <querytext>
	begin
	      :1 := content_folder.move (
	              folder_id => :move_folder_id,
	              target_folder_id => :new_parent_folder_id,
	              name => :new_name
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.rename_folder">
    <querytext>
	begin
	      content_folder.edit_name (
	              folder_id => :move_folder_id,
	              name => :new_name,
	              label => :new_name,
	              description => NULL
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.move_item">
    <querytext>
	begin
	      content_item.move (
	              item_id => :item_id,
	              target_folder_id => :new_parent_folder_id,
	              name => :new_name
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_revision::move.rename_item">
    <querytext>
	begin
	      content_item.edit_name (
	              item_id => :item_id,
	              name => :new_name
	      );
	end;
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.copy_item">
    <querytext>
	begin
      		:1 := content_item.copy2 (
	              item_id => :copy_item_id,
	              target_folder_id => :new_parent_folder_id,
	              creation_user => :user_id,
	              creation_ip => :peer_addr,
	              name => :new_name
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.delete_for_move">
    <querytext>
	begin
      		content_item.del(
	              item_id => :dest_item_id
	      	);
	end;
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.delete_for_copy">
    <querytext>
	begin
		content_item.del(
	            item_id => :dest_item_id
        	);
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::delete.delete_item">
    <querytext>
	begin
		content_item.del (
                	item_id => :item_id
	      );
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::delete.delete_folder">
    <querytext>
	begin
		content_folder.del (
	              folder_id => :item_id,
        	      cascade_p => 't'
	      );
	end;
    </querytext>
  </fullquery>


  <fullquery name="oacs_dav::item_parent_folder_id.get_parent_folder_id">
    <querytext>
	begin
	      :1 := content_item.get_id(
	              item_path => :parent_name,
	              root_folder_id => :root_folder_id,
	              resolve_index => 'f');
	end;
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.get_dest_id">
    <querytext>
	select content_item.get_id(:new_name,:new_parent_folder_id,'f') from dual
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.get_dest_id">
    <querytext>
	select content_item.get_id(:new_name,:new_parent_folder_id,'f') from dual
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::move.delete_for_move">
    <querytext>
	begin
      		content_folder.del(
	              folder_id => :dest_item_id,
	              cascade_p => 't');
	end;
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::copy.delete_for_copy">
    <querytext>
	begin
	      content_folder.del(
	              folder_id => :dest_item_id,
	              cascade_p => 't');
	end;
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.get_dest_id">
    <querytext>
	select content_item.get_id(:new_name,:new_parent_folder_id,'f') from dual
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.get_dest_id">
    <querytext>
	select content_item.get_id(:new_name,:new_parent_folder_id,'f') from dual
    </querytext>
  </fullquery>

</queryset>
