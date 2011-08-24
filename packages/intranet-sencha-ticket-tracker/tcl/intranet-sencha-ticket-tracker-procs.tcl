# /packages/intranet-filestorage/tcl/intranet-filestorage-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Sencha Ticket Tracker Library
    @author frank.bergmann@project-open.com
}


# Create a new content folder for the specified object
ad_proc -public im_fs_content_folder_for_object { 
    -object_id:required
    {-path ""}
} {
    Returns the folder_id of the specified path for the specified
    object. Creates necessary folders on the fly.
    @parm path Optional path within the object's FS
} {
    return [im_fs_content_folder_for_object_helper -object_id $object_id -path $path]
#    return [util_memoize [list im_fs_content_folder_for_object_helper -object_id $object_id -path $path]]
}


# Create a new content folder for the specified object
ad_proc -public im_fs_content_folder_for_object_helper { 
    -object_id:required
    {-path ""}
} {
    Returns the folder_id of the specified path for the specified
    object. Creates necessary folders on the fly.
    @parm path Optional path within the object's FS
} {
    ns_log Notice "im_fs_content_folder_for_object_helper: object_id=$object_id, path=$path"
    # Check if the folder already exists and return it
    set folder_id [db_string fs_folder "
        select  fs_folder_id
        from    im_biz_objects
        where   object_id = :object_id
    " -default ""]
    if {"" != $folder_id} { return $folder_id }

    # Prepare the variables that we need in order to create a new folder
    ns_log Notice "im_fs_content_folder_for_object_helper: Prepare to create new folder"
    set user_id [ad_maybe_redirect_for_registration]
    set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]
    db_0or1row object_info "
	select	o.object_type,
		pretty_plural as object_pretty_plural,
		acs_object__name(o.object_id) as object_name_pretty
	from	acs_objects o,
		acs_object_types ot
	where	o.object_id = :object_id and
		o.object_type = ot.object_type
    "
    if {![info exists object_pretty_plural]} {
	ns_log Error "im_fs_content_folder_for_object: didn't find object #$object_id"
	return ""
    }
    
    # Get the root folder for the fs instance
    set root_folder_id [fs::get_root_folder -package_id $package_id]
    if {"" == $root_folder_id} {
	set root_folder_id [fs::new_root_folder -package_id $package_id]
    }
    ns_log Notice "im_fs_content_folder_for_object_helper: root_folder_id=$root_folder_id"

    # Default folder name for the object: Append the object's unique ID
    # to the object's pretty name
    set object_paths [list]
    switch $object_type {
	im_project - im_ticket {
	    db_1row project_info "
	        select	p.project_nr,
	                p.project_path,
	                c.company_path
	        from	im_projects p,
	                im_companies c
	        where	p.project_id = :object_id
	                and p.company_id = c.company_id
	    "
	    set object_paths [list $company_path $project_nr]
	}
	user - person - im_employee {
	    set object_paths [list $object_id]
	}
    }
    if {"" == $object_paths} {
	# By default use a single path based on the object's name and ID
        set object_path [list $object_name_pretty - $object_id]
    }

    # The path we want to create
    set file_paths [split $path "/"]
    set file_paths [concat $object_paths $file_paths]
    set file_paths [linsert $file_paths 0 $object_pretty_plural]

    ns_log Notice "im_fs_content_folder_for_object_helper: file_paths=$file_paths"

    set path ""
    set parent_folder_id $root_folder_id
    foreach p $file_paths {
	append path "/${p}"
	ns_log Notice "im_fs_content_folder_for_object_helper: path='$path'"

	ns_log Notice "im_fs_content_folder_for_object_helper: content::item::get_id -item_path $path -root_folder_id $root_folder_id"
	set folder_id [content::item::get_id -item_path $path -root_folder_id $root_folder_id]
	ns_log Notice "im_fs_content_folder_for_object_helper: folder_id='$folder_id'"

	if {"" == $folder_id} {

	    # create the folder and grant "Admin" to employees
	    ns_log Notice "im_fs_content_folder_for_object_helper: content::folder::new -parent_id $parent_folder_id -name $p -label $p"
	    set folder_id [content::folder::new -parent_id $parent_folder_id -name $p -label $p]

	    # All the folder to contain FS files
	    content::folder::register_content_type -folder_id $folder_id -content_type "file_storage_object"

	    # Allow all employees to admin the new folder
	    permission::grant -party_id [im_profile_employees] -object_id $folder_id -privilege "admin"
	}
	ns_log Notice "im_fs_content_folder_for_object: oid=$object_id: path=$path, parent_id=$parent_folder_id => folder_id=$folder_id"
	set parent_folder_id $folder_id
    }

    # Save the new folder to the biz_object table
    db_dml project_folder_save "
	update im_biz_objects set 
		fs_folder_id = :folder_id,
		fs_folder_path = :path
	where object_id = :object_id
    "

    return $folder_id
}


ad_proc -callback im_ticket_after_update -impl im_sencha_ticket_tracker {
    -object_id
    -status_id
    -type_id
} {
    Callback to be executed after the update of any ticket.
    The call back checks if the ticket was newly assigned to a
    queue with external users.
    In this case the callback will send out email notifications
    to all members of the queue
} {
    ns_log Notice "im_ticket_after_update -impl im_sencha_ticket_tracker: Entering callback code"

    set found_p [db_0or1row ticket_info "
	select	t.*,
		p.*
	from	im_tickets t,
		im_projects p
	where	t.ticket_id = p.project_id and
		t.ticket_id = :object_id
    "]
    
    if {!$found_p} {
	ns_log Error "im_ticket_after_update -impl im_sencha_ticket_tracker -object_id=$object_id: Didn't find object, skipping"
	return ""
    }

    # Don't send mails to "Employees", "SAC" and "SACE"
    switch $ticket_queue_id {
	463 - 73363 -  73369 {
	    ns_log Notice "im_ticket_after_update -impl im_sencha_ticket_tracker: Assigned to internal group \#$ticket_queue_id, not sending messages"
	    return "" 
	}
    }

    # Don't send out the mail if the queue was assigned already before.
    # Here we check that there is no audit before. This means that we
    # won't send out a 2nd mail if the ticket was assigned to the queue
    # previously.
    set audit_sql "
	select	count(*)
	from
		(select	audit_id,
			audit_date,
			substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as ticket_queue_id
		from	im_audits
		where	audit_object_id = :object_id
		) t
	where	
		ticket_queue_id = :ticket_queue_id and
		audit_date < now() - '1 seconds'::interval
    "

    set already_assigned_p [db_string audit $audit_sql]
    if {$already_assigned_p} {
	ns_log Notice "im_ticket_after_update -impl im_sencha_ticket_tracker: The ticket was already assigned to queue '$ticket_queue_id'"
	return "" 
    }

    # Select out the name of the queue
    set queue_name [db_string queue_name "select group_name from groups where group_id = :ticket_queue_id" -default "undefined"]

    # Who is the currently connect user?
    set owner_email [db_string owner_mail "select im_email_from_user_id([im_rest_cookie_auth_user_id])"]

    # Send out notification mail to all members of the queue
    set member_sql "
	select	member_id,
		im_name_from_user_id(member_id) as member_name,
		im_email_from_user_id(member_id) as member_email
	from	group_distinct_member_map gdmm
	where	group_id = :ticket_queue_id
    "
    set member_list {}
    db_foreach members $member_sql {
	lappend member_list $member_name
    }

    set subject "SPRI: $project_name"
    set body "El grupo $queue_name ha sido asignado al ticket $project_name.
Tambien estan en este grupo:
- [join $member_list "\n- "]
"

    # Write the mail into the mail queue
    db_foreach send_email $member_sql {
	# acs_mail_lite::sendmail $member_email $owner_email $subject $body
	ns_log Notice "im_ticket_after_update -impl im_sencha_ticket_tracker: "
	ns_log Notice "im_ticket_after_update -impl im_sencha_ticket_tracker: acs_mail_lite::sendmail $member_email $owner_email $subject $body"
    }

}

