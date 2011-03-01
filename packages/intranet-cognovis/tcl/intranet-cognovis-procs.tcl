ad_library {
    Bring together all procedures and components (=HTML + SQL code)
    related to Projects.

    Sections of this library:
    <ul>
    <li>Project OO new, del and name methods
    <li>Project Business Logic
    <li>Project Components

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
    @author iuri.sampaio@gmail.com
}



ad_proc -public im_project_member_options {
    {-include_empty 1}
    project_id
    
} {
    Return members related to a group or task 
    @author iuri sampaio iuri.sampaio@gmail.com
    @date 2010-10-11
} {

#    ns_log Notice "Running API im_project_member_options $project_id"

    set options [db_list_of_lists select_members {
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

    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
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
    {-max_entries_per_page 20}
    {-view_name "im_timesheet_task_home_list"}
    {-restrict_to_status_id 9600}
    {-restrict_to_mine_p 1}
    {-order_by "priority"}
    {-page 1}
    {-return_url ""}
} {

    @author iuri sampaio (iuri.sampaio.gmail.com)
    @creation-date 2011-01-12
} {

    ns_log Notice "Running API im_timesheet_task_home_component"

    set params [list [list base_url "/intranet-cognovis/"] [list max_entries_per_page $max_entries_per_page] [list view_name $view_name] [list restrict_to_status_id $restrict_to_status_id] [list restrict_to_mine_p $restrict_to_mine_p] [list order_by $order_by] [list page $page] [list return_url $return_url]]

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
