ad_page_contract {
   intranet-cognovis/lib/home-tasks.tcl
    
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-01-12

} {
    {-view_name "im_timesheet_task_home_list"}
    {-order_by "priority"}
    {-restrict_to_status_id 76}
    {-restrict_to_mine_p 1}
    {-max_entries_per_page 20}
    {-page:optional}
    {-return_url ""}
}

# ---------------------- Where Restrictions -------------------------
set restriction_clauses [list]
set order_by_clause ""

if {[string is integer $restrict_to_status_id] && $restrict_to_status_id > 0} {
    lappend restriction_clauses " p.project_status_id in ([join [im_sub_categories $restrict_to_status_id] ","])"
}

if {$restrict_to_mine_p eq 1} {
    lappend restriction_clauses " p.project_id in (select object_id_one from acs_rels where object_id_two = [ad_conn user_id])"
}


set restriction_clauses [join $restriction_clauses "\n\tand "]
if {"" != $restriction_clauses} { set restriction_clauses "and $restriction_clauses"}


# ---------------------- Order By ------------------------------
if {[string equal $order_by "priority"]} {
    set order_by_clause "t.priority desc"
}


set elements ""
set extend_list [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]


db_foreach select_headers {} {
    ns_log Notice "HEADERS"
    ns_log Notice "$name | $label | $column_render_tcl"
    lappend extend_list $name
    if {"" == $visible_for || [eval $visible_for]} {
	set admin_link [export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}]
	set image_admin_link [im_gif wrench]
	
	set hide_link [export_vars -base "/intranet/admin/views/hide-column" {return_url column_id}]
	set image_hide_link [im_gif delete]
	if {[regexp {<} $name]} {
	    set name "checkbox"
	}
	append elements " \
          $name { 
            label {$label<a href=$admin_link>$image_admin_link</a>}
            display_template {$column_render_tcl}           
        } \ "
    }
    if {"" != $extra_select} { lappend extra_selects $extra_select }
    if {"" != $extra_from} { lappend extra_froms $extra_from }
    if {"" != $extra_where} { lappend extra_wheres $extra_where }
}



set extra_select [join $extra_selects ",\n\t"]
set extra_from [join $extra_froms ",\n\t"]
set extra_where [join $extra_wheres "and\n\t"]
if { ![empty_string_p $extra_select] } { set extra_select ",\n\t$extra_select" }
if { ![empty_string_p $extra_from] } { set extra_from ",\n\t$extra_from" }
if { ![empty_string_p $extra_where] } { set extra_where "and\n\t$extra_where" }

#ns_log Notice "FLAG"
#ns_log Notice "$elements"
template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -elements $elements \
    -page_size $max_entries_per_page \
    -page_flush_p 0 \
    -page_query { 
	SELECT 
	p.project_id as task_id,
	t.priority as task_prio,
	p.project_name as task_name,
	t.planned_units as units,
	p.parent_id as project_id,
	im_name_from_id(p.parent_id) as project_name,
        p.percent_completed
	$extra_select
        FROM 
	im_projects p, 
	im_timesheet_tasks t
	$extra_from
	WHERE t.task_id = p.project_id
	$restriction_clauses
	$extra_where
	ORDER BY $order_by_clause
    }

 
ns_log Notice "FLAG 1"
ns_log Notice "$extend_list"
ns_log Notice "$extra_select"
ns_log Notice "$extra_from"
ns_log Notice "$extra_where"
ns_log Notice "$restriction_clauses"


set  extend_list {gif_html object_url start_date end_date timesheet_report_url}
ns_log Notice "$extend_list"

db_multirow -extend $extend_list tasks select_task "
SELECT
        p.project_id as task_id,
        t.priority as task_prio,
        p.project_name as task_name,
        im_name_from_id(t.cost_center_id) as cost_center,
        p.start_date,
        p.end_date,
        (p.end_date < now() and coalesce(p.percent_completed,0) < 100) as red_p,
        p.project_type_id,
        t.planned_units,
        t.billable_units,
        p.parent_id project_id,
        im_name_from_id(p.parent_id) as project_name,
        p.percent_completed,
        p.reported_hours_cache as logged_hours
        FROM
        im_projects p,
        im_timesheet_tasks t
        WHERE t.task_id = p.project_id
        $restriction_clauses
        ORDER BY $order_by_clause
" {
   
    set timesheet_report_url [export_vars -base "/intranet-reporting/timesheet-customer-project" { end_date return_url {level_of_detail 99} task_id project_id start_date }]
    

    ns_log Notice "$task_prio - $task_name - $task_id - $project_type_id - $start_date - $end_date - "


    set start_date [string range $start_date 0 9]
    
    if {[string equal t $red_p]} { 
	set end_date "<nobr><font color=red>[string range $end_date 0 9]</font></nobr>" 
    } else { 
	set end_date "<nobr>[string range $end_date 0 9]</nobr>"
    }




    switch $project_type_id {
	100 {
	    # Timesheet Task
	    set object_url [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $task_id} return_url}]
	}
	101 {
	    # Ticket                                                                                                                                      
	    set object_url [export_vars -base "/intranet-helpdesk/new" {{ticket_id $task_id} return_url}]
	}
	default {
	    # Project                                                                                                                                     
	    set object_url [export_vars -base "/intranet/projects/view" {{project_id $task_id} return_url}]
	}
    }
}





