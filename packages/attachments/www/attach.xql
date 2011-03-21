<?xml version="1.0"?>

<queryset>
    <fullquery name="select_folder_contents">
        <querytext>
            select  fs_objects.object_id,
                         fs_objects.title,
                         fs_objects.name,
                         fs_objects.live_revision,
                         fs_objects.type,
                         to_char(fs_objects.last_modified, 'Month DD YYYY HH24:MI') as last_modified,
                         fs_objects.content_size,
                         fs_objects.url,
                         fs_objects.key,
                         fs_objects.sort_key,
			 fs_objects.file_upload_name, 
                         '0' as new_p
                  from fs_objects
                  where fs_objects.parent_id = :folder_id
	          order by sort_key, name
        </querytext>
    </fullquery>
</queryset>