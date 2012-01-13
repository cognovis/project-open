# /packages/intranet-helpdesk/www/associate-2.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Associate the ticket_ids in "tid" with one of the specified objects.
    target_object_type specifies the type of object to associate with and
    determines which parameters are used.
    @author frank.bergmann@project-open.com
} {
    { tid ""}
    { target_object_type "" }
    { user_id "" }
    { role_id "" }
    { release_project_id "" }
    { conf_item_id "" }
    { ticket_id "" }
    { return_url "/intranet-helpdesk/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Associate_Ticket_With_$target_object_type "Associate Ticket With $target_object_type"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

# Check that the user has write permissions on all select tickets
foreach t $tid {
    # Check that t is an integer
    im_security_alert_check_integer -location "Helpdesk: Associate" -value $t

    im_ticket_permissions $current_user_id $t view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

switch $target_object_type {
    user {
	# user_id contains the user to associate with 
	# role_id contains the type of association (member or admin)

	if {"" == $role_id} { ad_return_complaint 1 [lang::message::lookup "" intranet-helpdesk.No_Role_Specified "No role specified"] }
	foreach t $tid {

	    # Write the audit log
	    im_audit -object_id $t -action "before_update"
	    im_audit -object_id $user_id -action "before_update"

	    im_biz_object_add_role $user_id $t $role_id
	    
	    # Write the audit log
	    im_audit -object_id $t -action "after_update"
	    im_audit -object_id $user_id -action "after_update"

	}
    }
    release_project {
	# release_project_id contains the project to associate

	foreach pid $tid {

	    set exists_p [db_string count "
		select	count(*)
		from	im_release_items i,
			acs_rels r
		where	i.rel_id = r.rel_id
			and r.object_id_one = :release_project_id
			and r.object_id_two = :pid
	    "]

	    if {!$exists_p} {

		    set max_sort_order [db_string max_sort_order "
		        select  coalesce(max(i.sort_order),0)
		        from    im_release_items i,
		                acs_rels r
		        where	i.rel_id = r.rel_id
		                and r.object_id_one = :release_project_id
		    " -default 0]

		    set release_status_id [im_release_mgmt_status_default]
		    set release_item_id [db_string release_project "
			select im_release_item__new (
				null,
				'im_release_item',
				:release_project_id,
				:pid,
				null,
				:current_user_id,
				'[ad_conn peeraddr]',
				:release_status_id,
	                        [expr $max_sort_order + 10]
			)
		    "]
		    
		    # Write the audit log
		    im_audit -object_id $release_item_id -action "after_create"
	    }
	}
    }
    conf_item {
	foreach t $tid {

	    # Write the audit log
	    im_audit -object_id $t -action "before_update"
	    im_audit -object_id $conf_item_id -action "before_update"

	    im_conf_item_new_project_rel \
		-project_id $t \
		-conf_item_id $conf_item_id

	    # Write the audit log
	    im_audit -object_id $t -action "after_update"
	    im_audit -object_id $conf_item_id -action "after_update"
	}
    }
    ticket {
	# release_project_id contains the project to associate
	foreach pid $tid {

	    if {$pid == $ticket_id} { ad_return_complaint 1 "You can't associate a ticket with itself." }

	    set exists_p [db_string count "
		select	count(*)
		from	im_ticket_ticket_rels ttr,
			acs_rels r
		where	ttr.rel_id = r.rel_id
			and r.object_id_one = :pid
			and r.object_id_two = :ticket_id
	    "]

	    if {!$exists_p} {
		set max_sort_order [db_string max_sort_order "
		        select  coalesce(max(ttr.sort_order),0)
		        from    im_ticket_ticket_rels ttr,
		                acs_rels r
		        where	ttr.rel_id = r.rel_id
		                and r.object_id_one = :release_project_id
		" -default 0]

		# Write the audit log
		im_audit -object_id $pid -action "after_update"
		im_audit -object_id $ticket_id -action "after_update"

		db_string add_ticket_ticket_rel "
			select im_ticket_ticket_rel__new (
				null,
				'im_ticket_ticket_rel',
				:pid,
				:ticket_id,
				null,
				:current_user_id,
				'[ad_conn peeraddr]',
	                        [expr $max_sort_order + 10]
			)
		"
		# Write the audit log
		im_audit -object_id $pid -action "after_update"
		im_audit -object_id $ticket_id -action "after_update"

	    }
	}
    }
    default {
	ad_return_complaint 1 [lang::message::lookup "" intranet-helpdesk.Unknown_target_object_type "Unknown object type %target_object_type%"]
    }
}

ad_returnredirect $return_url

