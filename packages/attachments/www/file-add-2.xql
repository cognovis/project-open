<?xml version="1.0"?>
<queryset>

<fullquery name="duplicate_check">      
      <querytext>
      
    	select count(*)
   	from   cr_items
	where  name = :filename
    	and    parent_id = :folder_id

      </querytext>

</fullquery>

  <fullquery name="get_fs_package_id">
    <querytext>
      select package_id 
      from fs_root_folders 
      where folder_id=:root_folder
    </querytext>
  </fullquery>

</queryset>
