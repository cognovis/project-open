#intranet-xowki/lib/page.tcl

ad_page_contract {
    
}


set user_id [ad_conn user_id]

set project_member_p [im_biz_object_member_p $user_id $project_id ]

if {$project_member_p} {
    
    # Get the object_id/package_id of the xowiki instance
    db_1row select_object_id {
	SELECT object_id AS xowiki_object_id FROM site_nodes WHERE name = :project_id;
    }
    

    # Check and grant permissions for the project folder

    im_project_permissions $user_id $project_id project_view_p project_read_p project_write_p project_admin_p
    
    set read_p [permission::permission_p -party_id $user_id -object_id $xowiki_object_id -privilege "read"]
    set admin_p [permission::permission_p -party_id $user_id -object_id $xowiki_object_id -privilege "admin"]
    set write_p [permission::permission_p -party_id $user_id -object_id $xowiki_object_id -privilege "write"]
    set delete_p [permission::permission_p -party_id $user_id -object_id $xowiki_object_id -privilege "delete"]
    
    if {!$read_p && $project_read_p} {
	ns_log Notice "GRANT READ PERMISSION"
	permission::grant -party_id $user_id -object_id $xowiki_object_id -privilege read
    }
    
    if {!$write_p && $project_write_p} {
	ns_log Notice "GRANT WRITE RELATED PERMISSIONS"
	permission::grant -party_id $user_id -object_id $xowiki_object_id -privilege create
	permission::grant -party_id $user_id -object_id $xowiki_object_id -privilege write
	permission::grant -party_id $user_id -object_id $xowiki_object_id -privilege delete
    }
    
    if {!$admin_p && $project_admin_p} {
	ns_log Notice "GRANT ADMIN PERMISSION"
	permission::grant -party_id $user_id -object_id $xowiki_object_id -privilege admin
    }
}

