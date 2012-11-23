# /packages/intranet-reste/www/index.tcl
#
# Copyright (C) 2009 ]project-open[
#

# ---------------------------------------------------------
# Parameters passed aside of page_contract
# from intranet-rest-procs.tcl:
#
#    [list object_type $object_type] \
#    [list format $format] \
#    [list user_id $user_id] \
#    [list object_id $object_id] \
#    [list query_hash_pairs_ $query_hash_pairs] \

if {![info exists user_id]} { set user_id 0 }
if {![info exists format]} { set format "html" }

set rest_url "[im_rest_system_url]/intranet-rest"


if {0 == $user_id} {
    # User not autenticated
    switch $format {
	html {
	    ad_return_complaint 1 "Not authorized"
	    ad_script_abort
	}
	xml {
	    im_rest_error -http_status 401 -message "Not authenticated"
	    return
	}
    }
}

# Got a user already authenticated by Basic HTTP auth or auto-login

switch $format {
    xml {
	# ---------------------------------------------------------
	# Return the list of object types
	# ---------------------------------------------------------
	
	set xml_p 1
	set otype_sql "select object_type from acs_object_types"
	set otype_xml ""
	db_foreach otypes $otype_sql { 
	    append otype_xml "<object_type href=\"[export_vars -base $rest_url/$object_type]\">$object_type</object_type>\n"
	}

	set xml "<?xml version='1.0' encoding='UTF-8'?>\n<object_types>\n$otype_xml</object_types>\n"

    }
    default {

	# ---------------------------------------------------------
	# Continue as a normal HTML page
	# ---------------------------------------------------------
	
	set xml_p 0
	set current_user_id [ad_maybe_redirect_for_registration]
	set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
	set page_title [lang::message::lookup "" intranet-rest.REST_API_Overview "REST API Overview"]
	set context_bar [im_context_bar $page_title]
	
	set toggle_url "/intranet/admin/toggle"
	set return_url [im_url_with_query]
	
	# ---------------------------------------------------------
	# Make sure we've got a REST object_type object for every
	# acs_object_types.object_type
	# ---------------------------------------------------------
	
	set missing_object_types [db_list missing_object_types "
		select	object_type
		from	acs_object_types
		where	object_type not in (
			select	object_type
			from	im_rest_object_types
		)
	"]
	foreach object_type $missing_object_types {
	
	    db_string insert_rest_object_type "
		select	im_rest_object_type__new(
				null,
				'im_rest_object_type',
				now(),
				:current_user_id,
				'[ad_conn peeraddr]',
				null,
	
				:object_type,
				null,
				null
		)
	    "
	}
	
	
	# ---------------------------------------------------------
	# What operations are currently implemented on the REST API?
	# ---------------------------------------------------------
	
	array set xxx_crud_hash {
		group R
		im_biz_object_member CRUD
		im_company CRUD
		im_company_employee_rel CRUD
		im_cost_center R
		im_dynfield_attribute R
		im_dynfield_widget R
		im_invoice CRUD
		im_key_account_rel CRUD
		im_material R
		im_menu R
		im_note R
		im_office R
		im_profile R
		im_repeating_cost R
		im_report R
		im_ticket CRUD
		im_ticket_ticket_rel CRUD
		im_timesheet_task CRUD
		im_trans_invoice CRUD
		im_trans_task CRUD
		im_user_absence CRUD
		membership_rel CRUD
		user CRU
	}
	
	array set crud_hash {
		im_invoice "<b>CRUL</b>"
		im_invoice_item "<b>CRUL</b>"
		im_project "<b>CRUL</b>"
		im_trans_task "<b>CRUL</b>"
	}
	
	
	array set wiki_hash {
		object_typ_im_indicator 1
		object_type_acs_attribute 1
		object_type_acs_object 1
		object_type_acs_object_type 1
		object_type_acs_permission 1
		object_type_acs_privilege 1
		object_type_acs_rel 1
		object_type_apm_package 1
		object_type_cal_item 1
		object_type_calendar 1
		object_type_group 1
		object_type_im_biz_object 1
		object_type_im_category 1
		object_type_im_company 1
		object_type_im_component_plugin 1
		object_type_im_conf_item 1
		object_type_im_cost 1
		object_type_im_cost_center 1
		object_type_im_dynfield_attribute 1
		object_type_im_employee 1
		object_type_im_expense 1
		object_type_im_expense_bundle 1
		object_type_im_forum_topic 1
		object_type_im_forum_topic_name 1
		object_type_im_fs_file 1
		object_type_im_hour 1
		object_type_im_indicator 1
		object_type_im_invoice 1
		object_type_im_invoice_item 1
		object_type_im_material 1
		object_type_im_menu 1
		object_type_im_office 1
		object_type_im_payment 1
		object_type_im_profile 1
		object_type_im_project 1
		object_type_im_report 1
		object_type_im_ticket 1
		object_type_im_ticket_ticket_rel 1
		object_type_im_timesheet_invoice 1
		object_type_im_timesheet_price 1
		object_type_im_timesheet_task 1
		object_type_im_user_absence 1
		object_type_im_view 1
		object_type_object 1
		object_type_party 1
		object_type_person 1
		object_type_user 1
	}
	
	
	# ---------------------------------------------------------
	# Calculate the columns of the list
	# ---------------------------------------------------------
	
	set list_columns {
	        object_gif {
		    display_template {<a href="@object_types.object_type_url;noquote@">@object_types.object_type_gif_html;noquote@</a>}
	            label ""
	        }        
	        object_type {
	            display_col object_type
	            label "Object Type"
	            link_url_eval $object_type_url
	        }        
	        pretty_name {
	            display_col pretty_name
	            label "Pretty Name"
	        }
	    }
	
	
	set profile_sql {
		select DISTINCT
		        g.group_name,
		        g.group_id,
		        p.profile_gif
		from
		        acs_objects o,
		        groups g,
		        im_profiles p
		where
		        g.group_id = o.object_id
		        and g.group_id = p.profile_id
		        and o.object_type = 'im_profile'
	}
	
	set multirow_select ""
	set multirow_extend {object_type_url object_type_gif_html crud_status object_wiki_url wiki}
	set group_ids [list]
	
	if {$current_user_is_admin_p} {
	    db_foreach profiles $profile_sql {
		regsub -all {[^a-zA-Z0-9]} [string tolower $group_name] "_" group_name_key
		lappend list_columns p$group_id
		lappend list_columns [list \
					  label [im_gif $profile_gif $group_name $group_name] \
					  display_template "@object_types.p$group_id;noquote@" \
					 ]
		
		append multirow_select "\t\t, im_object_permission_p(rot.object_type_id, $group_id, 'read') as p${group_id}_read_p\n"
		append multirow_select "\t\t, im_object_permission_p(rot.object_type_id, $group_id, 'write') as p${group_id}_write_p\n"
		
		lappend multirow_extend "p$group_id"
		lappend group_ids $group_id
	    }
	}
	
	
	lappend list_columns crud_status
	lappend list_columns {
	            label "CRUL<br>Status"
		    display_template "@object_types.crud_status;noquote@"
		}
	lappend list_columns wiki
	lappend list_columns {
	            label "Wiki"
	            link_url_eval $object_wiki_url
		}
	
	
	# ---------------------------------------------------------
	# Create the list and fill it with data
	# ---------------------------------------------------------
	
	
	list::create \
	    -name object_types \
	    -multirow object_types \
	    -key object_type \
	    -row_pretty_plural "Object Types" \
	    -checkbox_name checkbox \
	    -selected_format "normal" \
	    -class "list" \
	    -main_class "list" \
	    -sub_class "narrow" \
	    -elements $list_columns
	
	
	set not_in_object_type "
				'acs_activity',
				'acs_event',
				'acs_mail_body',
				'acs_mail_gc_object',
				'acs_mail_link',
				'acs_mail_multipart',
				'acs_mail_queue_message',
				'acs_message',
				'acs_message_revision',
				'acs_named_object',
				'acs_object',
				'acs_reference_repository',
				'acs_sc_contract',
				'acs_sc_implementation',
				'acs_sc_msg_type',
				'acs_sc_operation',
				'admin_rel',
				'ams_object_revision',
				'apm_application',
				'apm_package',
				'apm_package_version',
				'apm_parameter',
				'apm_parameter_value',
				'apm_service',
				'application_group',
				'authority',
				'bt_bug',
				'bt_bug_revision',
				'bt_patch',
				'calendar',
				'cal_item',
				'composition_rel',
				'content_extlink',
				'content_folder',
				'content_item',
				'content_keyword',
				'content_module',
				'content_revision',
				'content_symlink',
				'content_template',
				'cr_item_child_rel',
				'cr_item_rel',
				'dynamic_group_type',
				'etp_page_revision',
				'image',
				'im_biz_object',
				'im_component_plugin',
				'im_cost',
				'im_gantt_person',
				'im_gantt_project',
				'im_indicator',
				'im_investment',
				'im_menu',
				'im_note',
				'im_repeating_cost',
				'im_report',
				'journal_article',
				'journal_entry',
				'journal_issue',
				'news_item',
				'notification',
				'notification_delivery_method',
				'notification_interval',
				'notification_reply',
				'notification_request',
				'notification_type',
				'person',
				'party',
				'postal_address',
				'rel_segment',
				'rel_constraint',
				'site_node',
				'user_blob_response_rel',
				'user_portrait_rel',
				'workflow',
				'workflow_lite',
				'workflow_case_log_entry'
	"
	
	db_multirow -extend $multirow_extend object_types select_object_types "
		select
			ot.object_type,
			ot.pretty_name,
			ot.object_type_gif,
			rot.object_type_id,
			im_object_permission_p(rot.object_type_id, :current_user_id, 'read') as current_user_read_p
			$multirow_select
		from
			acs_object_types ot,
			im_rest_object_types rot
		where
			ot.object_type = rot.object_type and
			-- skip a number of uninteresting user types
			ot.object_type not in ($not_in_object_type)
			-- exclude object types created for workflows
			and ot.object_type not like '%wf'
		order by
			ot.object_type
	" {
	    set object_type_url "/intranet-rest/$object_type?format=html"
	    set object_type_gif_html [im_gif $object_type_gif]
	    switch $object_type {
		im_company - im_project - bt_bug - im_company - im_cost - im_conf_item - im_project - im_user_absence - im_office - im_ticket - im_timesheet_task - im_translation_task - user {
		    # These object are handled via custom permissions:
		}
		default {
		    if {"t" != $current_user_read_p} { set object_type_url "" }
		}
	    }
	
	    set crud_status "RUL"
	    if {[info exists crud_hash($object_type)]} { set crud_status $crud_hash($object_type) }
	
	    set wiki_key "object_type_$object_type"
	    set wiki "Wiki"
	    set object_wiki_url "http://www.project-open.org/en/object_type_$object_type"
	    if {![info exists wiki_hash($wiki_key)]} {
		set wiki ""
		set object_wiki_url ""
	    }
	
	    # Calculate the read/write URLS
	    foreach gid $group_ids {
		set read_p [set "p${gid}_read_p"]
		set write_p [set "p${gid}_write_p"]
	        set object_id $object_type_id
		set horiz_group_id $gid
	
	        set action "add_readable"
	        set letter "r"
	        if {$read_p == "t"} {
	            set action "remove_readable"
	            set letter "<b>R</b>"
	        }
	        set read "<A href=\"[export_vars -base $toggle_url {horiz_group_id object_id action return_url}]\">$letter</A>"
	
	        set action "add_writable"
	        set letter "w"
	        if {$write_p == "t"} {
	            set action "remove_writable"
	            set letter "<b>W</b>"
	        }
	        set write "<A href=\"[export_vars -base $toggle_url {horiz_group_id object_id action return_url}]\">$letter</A>"
	
		ns_log Notice "intranet-rest/index: p$gid=gid=$gid, object_id=$object_type_id"
		set p$gid "$read$write"
	    }
	}
	

	# End of HTML stuff
    }
}
	