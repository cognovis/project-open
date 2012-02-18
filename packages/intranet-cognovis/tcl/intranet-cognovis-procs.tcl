ad_library {
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @author iuri.sampaio@gmail.com
}


namespace eval intranet_cognovis {}

ad_proc -public intranet_cognovis::get_all_open_project_members {
} {
    returns a [list] of all the users who are in projects with an OPEN status (or subcategories of open).
} {

    set project_list [im_project_options -include_empty 0 -project_status_id [im_project_status_open] -exclude_tasks_p 1 -no_conn_p 1]
    
    set user_ids [list]
    
    foreach element $project_list {
	set project_id [lindex $element 1]
	
	set members [db_list_of_lists select_members {
	    select
	    im_name_from_user_id(u.user_id) as name,
	    u.user_id
	    from
	    users u,
	    acs_rels rels
	    LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
	    LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id),
	    group_member_map m,
	    membership_rels mr
	    where
	    rels.object_id_one = :project_id
	    and rels.object_id_two = u.user_id
	    and mr.member_state = 'approved'
	    and u.user_id = m.member_id
	    and mr.member_state = 'approved'
	    and m.group_id = acs__magic_object_id('registered_users'::character varying)
	    and m.rel_id = mr.rel_id
	    and m.container_id = m.group_id
	    and m.rel_type = 'membership_rel'	
	    order by lower(im_name_from_user_id(u.user_id))
	}]
	
	foreach element $members {
	    set user_id_exists_p 0
	    foreach id $user_ids {
		if {$id eq [lindex $element 1]} {
		    set user_id_exists_p 1
		}
	    }
	    
	    if {$user_id_exists_p eq 0} {
		lappend user_ids [lindex $element 1]
	    }
	}
    }
    
    return $user_ids
}


ad_proc -public intranet_cognovis::remind_members {
} {
    Goes through the list of members in members_list and check if they have logged their hours within the last week.
} {

    set member_list [intranet_cognovis::get_all_open_project_members]
    
    set interval [db_string select_interval { select now() - interval '7 days' from dual; }]
    
    foreach member_id $member_list {
        set logged_hours_p [db_string select_hours {
	        select count(*) from im_hours where day > now() -interval '7 days' and user_id = :member_id
        }]
		
        if {$logged_hours_p eq 0} {
            
            set member_email [im_email_from_user_id $member_id]
            
            set from_addr [ad_admin_owner]
            
            db_1row select_system_url {
                select attr_value as system_url from apm_parameter_values where parameter_id = (
		           select parameter_id from apm_parameters where package_key = 'acs-kernel' and parameter_name = 'SystemURL' );
            }
	    
            set hour_logging_url "${system_url}/intranet-timesheet2/hours/index"
            db_1row select_package_id { 
               		select package_id from apm_packages where package_key = 'intranet-core'
            }

            acs_mail_lite::send -send_immediately \
                -to_addr $member_email \
                -from_addr $from_addr \
                -subject "[lang::util::localize "#intranet-cognovis.You_did_not_log_hours#" [lang::user::locale -user_id $member_id -package_id $package_id -site_wide]]" \
                -body "[lang::util::localize "#intranet-cognovis.Please_log_hours#" [lang::user::locale -user_id $member_id -package_id $package_id -site_wide]]" 
        }
    }
}


ad_proc -public im_project_base_data_cognovis_component {
    {-project_id}
    {-return_url}
} {
    returns basic project info with dynfields and hard coded
} { 

    set params [list  [list base_url "/intranet-cognovis/"]  [list project_id $project_id] [list return_url $return_url]]
    
    set result [ad_parse_template -params $params "/packages/intranet-cognovis/lib/project-base-data"]
    return [string trim $result]

}
    




# ----------------------------------------------------------------------
# Task Components
# ---------------------------------------------------------------------

# ----------------------------------------------------------------------
# Timesheet Task Info Component
# ---------------------------------------------------------------------


ad_proc -public im_timesheet_task_info_cognovis_component {
    task_id
    return_url
} {
    

    set params [list  [list base_url "/intranet-cognovis/"]  [list task_id $task_id] [list return_url $return_url]]
    
    set result [ad_parse_template -params $params "/packages/intranet-cognovis/lib/task-info"]

    return [string trim $result]


}



# ----------------------------------------------------------------------
# Home Tasks Component
# ---------------------------------------------------------------------
ad_proc -public im_timesheet_task_home_component {
    {-page_size 20}
    {-restrict_to_status_id 76}
    {-return_url ""}
} {

    @author iuri sampaio (iuri.sampaio.gmail.com)
    @creation-date 2011-01-12
} {

    # set the page variable (hopefully)
    set page [ns_queryget page 1]
    set orderby [ns_queryget orderby priority]
    set params [list [list base_url "/intranet-cognovis/"] [list page_size $page_size] [list restrict_to_status_id $restrict_to_status_id] [list orderby $orderby] [list page $page] [list return_url $return_url]]

    set result [ad_parse_template -params $params "/packages/intranet-cognovis/lib/home-tasks"]
    return [string trim $result]
}




#####
#Calendar Procs 
#####

ad_proc -public from_sql_datetime {
    {-sql_date:required}
    {-format:required}
} {
    
} {

    ns_log Notice "Running API from_sql_datetime"
    # for now, we recognize only "YYYY-MM-DD" "HH12:MIam" and "HH24:MI". 
    set sql_time $sql_date
    set date [template::util::date::create]
    set date_time [template::util::date::create]

    switch -exact -- $format {
        {YYYY-MM-DD-HH24:MI} {
            regexp {([0-9]*)-([0-9]*)-([0-9]*)} $sql_date all year month day hours minutes ampm
	    
            set date [template::util::date::set_property format $date {DD MONTH YYYY}]
            set date [template::util::date::set_property year $date $year]
            set date [template::util::date::set_property month $date $month]
            set date [template::util::date::set_property day $date $day]
            
	    regexp {([0-9]*):([0-9]*)} $sql_time all hours minutes

	    set date_time [template::util::date::set_property format $date_time {HH24:MI}]
            set date_time [template::util::date::set_property hours $date_time $hours]
            set date_time [template::util::date::set_property minutes $date_time $minutes]
	    
	    set new_format "[lindex $date 6] [lindex $date_time 6]"
	    set date [list [lindex $date 0] [lindex $date 1] [lindex $date 2] [lindex $date_time 3] [lindex $date_time 4] {} $new_format] 
        }

        {YYYY-MM-DD} {
            regexp {([0-9]*)-([0-9]*)-([0-9]*)} $sql_date all year month day

            set date [template::util::date::set_property format $date {DD MONTH YYYY}]
            set date [template::util::date::set_property year $date $year]
            set date [template::util::date::set_property month $date $month]
            set date [template::util::date::set_property day $date $day]
        }

        {HH12:MIam} {
            regexp {([0-9]*):([0-9]*) *([aApP][mM])} $sql_date all hours minutes ampm
            
            set date [template::util::date::set_property format $date {HH12:MI am}]
            set date [template::util::date::set_property hours $date $hours]
            set date [template::util::date::set_property minutes $date $minutes]                
            set date [template::util::date::set_property ampm $date [string tolower $ampm]]
        }

        {HH24:MI} {
            regexp {([0-9]*):([0-9]*)} $sql_date all hours minutes

            set date [template::util::date::set_property format $date {HH24:MI}]
            set date [template::util::date::set_property hours $date $hours]
            set date [template::util::date::set_property minutes $date $minutes]
        }

        {HH24} {
            set date [template::util::date::set_property format $date {HH24:MI}]
            set date [template::util::date::set_property hours $date $sql_date]
            set date [template::util::date::set_property minutes $date 0]
        }
        default {
            set date [template::util::date::set_property ansi $date $sql_date]
        }
    }
    return $date
}


ad_proc -public -callback im_project_new_redirect -impl intranet-cognovis {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
    {-project_id:required}
    {-parent_id:required}
    {-company_id:required}
    {-project_type_id:required}
    {-project_name:required}
    {-project_nr:required}
    {-workflow_key:required}
    {-return_url:required}
} {
    This is mainly a callback to redirect from the original new.tcl page to somewhere else
    
} {

    if {$parent_id ne ""} {
	# Fill in defaults if the paren_id is set
	db_1row projects_by_parent_id_query {
	    select 
	    p.company_id, 
	    p.project_type_id, 
	    p.project_status_id
	    from
	    im_projects p
	    where 
	    p.project_id=:parent_id 
	}
	
	set project_nr [im_next_project_nr -customer_id $company_id -parent_id $parent_id]
    }

    foreach unset_variable {project_id parent_id project_name project_nr} {
	if {[set $unset_variable] eq ""} {
	    unset $unset_variable
	}
    }
 
   ad_returnredirect [export_vars -base "/intranet-cognovis/projects/project-ae" {
	project_id parent_id company_id project_type_id project_name project_nr workflow_key return_url 
    }] 
} 




if {0} {
ad_proc -public -callback im_timesheet_task_new_redirect -impl intranet-cognovis {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
    {-task_id ""}
    {-project_id:required}
    {-edit_p ""}
    {-message ""}
    {-form_mode ""}
    {-task_status_id ""}
    {-return_url:required}
} {
    This is mainly a callback to redirect from the original new.tcl page to somewhere else
    
} {

    if {[exists_and_not_null task_id]} {
	ad_returnredirect [export_vars -base "/intranet-cognovis/tasks/view" {
	    task_id project_id edit_p message form_mode task_status_id return_url 
	}]
    } else {
	ad_returnredirect [export_vars -base "/intranet-cognovis/tasks/task-ae" {
	    project_id edit_p message form_mode task_status_id return_url 
	}]
    }
} 

}

ad_proc -public -callback im_company_new_redirect -impl intranet-cognovis {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
    {-company_id:required}
    {-company_status_id:required}
    {-company_type_id:required}
    {-company_name:required}
    {-company_path ""}
    {-return_url:required}
} {
    This is mainly a callback to redirect from the original new.tcl page to somewhere else
    
} {

 
   ad_returnredirect [export_vars -base "/intranet-cognovis/companies/company-ae" {
	company_id company_type_id company_status_id company_name return_url 
    }] 
} 

ad_proc -public intranet_cognovis::delete_project {
    {-project_id:required}
} {
    Delete project completely
} {
    # Delete the responses from simple survey
    db_dml delete "delete from survsimp_responses where related_object_id = :project_id"
    set item_id [db_string item "select item_id from cr_items where parent_id = $project_id" -default ""]
    if {$item_id ne ""} {
	db_string delete "select content_item__del($item_id) from dual" -default ""
    }

    # Delete the associated file storage folders
    # Get the folder_id
    set folder_id [intranet_fs::get_project_folder_id -project_id $project_id]

    # Now delete the relationship to it
    set relationship_id [db_string get_relationship_id "select rel_id from acs_rels where object_id_one = :project_id and object_id_two = :folder_id"]
    if {$relationship_id ne ""} {
	db_1row delete_relation "select acs_rel__delete($relationship_id) from dual"
    }
    # And delete the folder
    fs::delete_folder -folder_id $folder_id -no_notifications

    # Nuke the project
    ns_log Notice "<li>Nuking project \#$project_id ...<br>\n"
    set error [im_project_nuke $project_id]
    if {"" == $error} {
	ns_log Notice "... successful\n"
    } else {
	ns_log Notice "<font color=red>$error</font>\n"
    }
}

# ---------------------------------------------------------------
# intranet-helpdesk new ticket redirection
# ---------------------------------------------------------------

ad_proc -public -callback im_helpdesk_ticket_new_redirect -impl intranet-helpdesk {
    {-ticket_id ""}
    {-ticket_name "" }
    {-ticket_nr "" }
    {-ticket_sla_id "" }
    {-ticket_customer_contact_id "" }
    {-ticket_status_id ""}
    {-ticket_type_id "" }
    {-view_name ""}
    {-escalate_from_ticket_id ""}
    {-return_url:required}
} {
	This is mainly a callback to redirect from the original new.tcl page to somewhere else
	
        @param ticket_id ID of the task
	@param project_id ID of the project 
        @ticket_status_id This checks what is the current status of a ticket 
        @ticket_type_id This checks what is the current type of a ticket
} {
    if {[exists_and_not_null ticket_id]} {
	ad_returnredirect [export_vars -base "/intranet-cognovis/tickets/view" {
	    ticket_id return_url 
	}]
    } else {
	ad_returnredirect [export_vars -base "/intranet-cognovis/tickets/ticket-ae" {
	    {project_name $ticket_name} {project_nr $ticket_nr} {parent_id $ticket_sla_id} ticket_customer_contact_id ticket_status_id ticket_type_id view_name escalate_from_ticket_id return_url
	}]
    }
} 

# ----------------------------------------------------------------------
# Ticket Info Component
# ---------------------------------------------------------------------
ad_proc -public im_ticket_info_cognovis_component {
    ticket_id
    return_url
} {

    set params [list  [list base_url "/intranet-cognovis/"]  [list ticket_id  $ticket_id] [list return_url $return_url]]
    
    set result [ad_parse_template -params $params "/packages/intranet-cognovis/lib/ticket-info"]

    return [string trim $result]
}