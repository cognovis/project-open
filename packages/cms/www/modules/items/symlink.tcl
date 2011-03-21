	# if the item is or is linked to a content_folder, then 
	#   use the sitemap module to browse the folder

        db_0or1row do_folder_check "" -column_array folder_check

	if { [info exists folder_check] } {
	    set folder_p $folder_check(folder_p)
	    set parent_id $folder_check(context_id)

	    if { [string equal $folder_p "t"] } {
		template::forward "../sitemap/index?id=$resolved_id&parent_id=$parent_id"
	    }
	}
    }
