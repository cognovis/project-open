# /www/intranet/member-add-2.tcl

ad_page_contract {
    Purpose: Confirms adding of person to group

    @param user_id_from_search user_id to add
    @param group_id group to which to add
    @param role role in which to add
    @param return_url Return URL
    @param also_add_to_group_id Additional groups to which to add

    @author mbryzek@arsdigita.com
    @creation-date 4/16/2000

    @cvs-id member-add-2.tcl,v 3.5.2.8 2000/10/27 00:03:00 tony Exp
} {
    action
    user_id_from_search:integer,optional
    user_id_to_invite:array,optional
    user_refuse_from_project:array,optional
    user_add_to_project:array,optional
    group_id:integer
    role
    return_url
    { notify_asignee "0" }
    { also_add_to_group_id:integer "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_member_p [ad_user_group_member $group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_admin_p [expr $user_is_admin_p + $user_is_group_admin_p]

ns_log Notice "member-add-2: notify_asignee=$notify_asignee"

if {!$user_admin_p} {
    set err_msg "You are not an administator of this group.<br>\
    The system administator will be notified."
    ad_return_error "Insufficient Permissions" $err_msg
}

switch $action {
    "Invite" {
	set user_list [array names user_id_to_invite]
	set list_url ""
	set return_url "invitations/invite.tcl?[export_url_vars user_list group_id return_url]"
    }
    "Refuse" {
	set refused_id [db_string status_select "
            select category_id
            from categories
            where category like 'Refused'
            and category_type like 'Intranet Application Status'"]
	foreach user_ind [array names user_refuse_from_project] {
	    db_dml refuse_user \
		"update im_freelance_applications
                 set status_id = :refused_id
                 where user_id = :user_ind
                 and project_id = :group_id"
	}
    }
    "Add" {
	if { [info exist user_add_to_project] } {
	    set user_list [array names user_add_to_project]
	    foreach user_ids $user_list {
		db_transaction {
		    # don't allow for duplicate roles between user and group,
		    # so just delte any previous relationships.
		    #
		    db_dml user_group_delete \
			"delete from user_group_map
                         where group_id = :group_id
                         and user_id = :user_ids"

		    db_dml user_group_insert \
			"insert into user_group_map values
                        (:group_id, :user_ids, :role, sysdate, 1, '0.0.0.0')"
		    set accepted_id [db_string status_select "
                        select category_id
                        from categories
                        where category like 'Accepted'
                        and category_type like 'Intranet Application Status'"]
		    db_dml refuse_user \
                       "update im_freelance_applications
                       set status_id = :accepted_id
                       where user_id = :user_ids
                       and project_id = :group_id"
		}
	    }
	}
	if { [info exist user_id_from_search] } {
	    db_transaction {
		# don't allow for duplicate roles between user and group,
		# so just delte any previous relationships.
		#
		db_dml user_group_delete \
		    "delete from user_group_map 
                     where group_id = :group_id 
	             and user_id = :user_id_from_search"
		
		db_dml user_group_insert \
		    "insert into user_group_map values
	            (:group_id, :user_id_from_search, :role, sysdate, 1, '0.0.0.0')"
	    } 
	    
	    # Send out an email alert
	    if {"" != $notify_asignee && ![string equal "0" $notify_asignee]} {
		set url "[ad_parameter SystemUrl]intranet/projects/view?group_id=$group_id"
		set sql "select group_name from user_groups where group_id=:group_id"
		set project_name [db_string project_name $sql]
		set subject "You have been added to project \"$project_name\""
		set message "Please click on the link above to access the project pages."
		
		im_send_alert $user_id_from_search "hourly" $url $subject $message
	    }
	}
    }
}


ad_returnredirect $return_url

    
    


if { $action == "Invite"} {
    set user_list [array names user_id_to_invite]
    set list_url ""
    foreach list $user_list {
	
    }
    set return_url "invitations/invite.tcl?[export_url_vars user_list group_id return_url]"
}

if { [string equal $action "Refuse"] } {
    set refused_id [db_string status_select "
      select category_id
      from categories
      where category like 'Refused'
      and category_type like 'Intranet Application Status'"]
    foreach user_ind [array names user_refuse_from_project] {
	db_dml refuse_user \
	    "update im_freelance_applications
             set status_id = :refused_id
             where user_id = :user_ind
             and project_id = :group_id"
    }
}


