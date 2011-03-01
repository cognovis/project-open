<?xml version="1.0"?>

<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="select_folders">
        <querytext>
            select file_storage.get_package_id(fs_objects.object_id) as package_id,
                   decode(fs_objects.type, 'url', (select site_node.url(site_nodes.node_id)
                                                   from site_nodes
                                                   where site_nodes.object_id = file_storage.get_package_id(fs_objects.parent_id)),
                                           (select site_node.url(site_nodes.node_id)
                                            from site_nodes
                                            where site_nodes.object_id = file_storage.get_package_id(fs_objects.object_id))) as url,
                   fs_objects.object_id,
                   fs_objects.name,
		   fs_objects.file_upload_name,
                   fs_objects.live_revision,
                   fs_objects.type,
                   fs_objects.content_size
            from fs_objects
            where fs_objects.object_id in ([join $list_of_folder_ids ", "])
            and 't' = acs_permission.permission_p(fs_objects.object_id, :user_id, 'read')
            order by fs_objects.sort_key,
                     fs_objects.name
        </querytext>
    </fullquery>

    <fullquery name="select_folder_contents">
        <querytext>
            select file_storage.get_package_id(fs_objects.object_id) as package_id,
                   decode(fs_objects.type, 'url', (select site_node.url(site_nodes.node_id)
                                                   from site_nodes
                                                   where site_nodes.object_id = file_storage.get_package_id(fs_objects.parent_id)),
                                           (select site_node.url(site_nodes.node_id)
                                            from site_nodes
                                            where site_nodes.object_id = file_storage.get_package_id(fs_objects.object_id))) as url,
                   fs_objects.object_id,
                   fs_objects.name,
		   fs_objects.file_upload_name,
                   fs_objects.live_revision,
                   fs_objects.type,
                   fs_objects.content_size
            from fs_objects
            where fs_objects.parent_id in ([join $list_of_folder_ids ", "])
            and 't' = acs_permission.permission_p(fs_objects.object_id, :user_id, 'read')
            order by fs_objects.parent_id,
                     fs_objects.sort_key,
                     fs_objects.name
        </querytext>
    </fullquery>

</queryset>







