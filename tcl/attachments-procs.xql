<?xml version="1.0"?>
<queryset>

    <fullquery name="attachments::root_folder_p.root_folder_p_select">
        <querytext>
            select 1
            from attachments_fs_root_folder_map
            where package_id = :package_id
        </querytext>
    </fullquery>

    <fullquery name="attachments::get_root_folder.get_root_folder_select">
        <querytext>
            select folder_id
            from attachments_fs_root_folder_map
            where package_id = :package_id
        </querytext>
    </fullquery>

    <fullquery name="attachments::map_root_folder.map_root_folder_insert">
        <querytext>
            insert
            into attachments_fs_root_folder_map 
            (package_id, folder_id)
            values
            (:package_id, :folder_id)
        </querytext>
    </fullquery>

    <fullquery name="attachments::unmap_root_folder.unmap_root_folder_delete">
        <querytext>
            delete
            from attachments_fs_root_folder_map
            where package_id = :package_id and
            folder_id = :folder_id
        </querytext>
    </fullquery>

    <fullquery name="attachments::attach.insert_attachment">
        <querytext>
            insert
            into attachments
            (object_id, item_id, approved_p)
            values
            (:object_id, :attachment_id, :approved_p)
        </querytext>
    </fullquery>

    <fullquery name="attachments::unattach.delete_attachment">
        <querytext>
            delete
            from attachments
            where object_id = :object_id
            and item_id = :attachment_id
        </querytext>
    </fullquery>

    <fullquery name="attachments::toggle_approved.select_attachment_approved_p">
        <querytext>
            select approved_p
            from attachments
            where object_id = :object_id
            and item_id = :item_id
        </querytext>
    </fullquery>

    <fullquery name="attachments::toggle_approved.toggle_approved_p">
        <querytext>
            update attachments
            set approved_p = :approved_p
            where object_id = :object_id
            and item_id = :item_id
        </querytext>
    </fullquery>

</queryset>
