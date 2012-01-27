ad_page_contract {
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-01-12

} {
    {-view_name "im_timesheet_task_home_list"}
    {-order_by "priority"}
    {-restrict_to_status_id 9600}
    {-restrict_to_mine_p 1}
    {-max_entries_per_page 50}
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
    lappend extend_list $name
    if {"" == $visible_for || [eval $visible_for]} {
	set admin_link [export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}]
	set image_admin_link [im_gif wrench]
	
	set hide_link [export_vars -base "/intranet/admin/views/hide-column" {return_url column_id}]
	set image_hide_link [im_gif delete]
	append elements " \
          $name { 
            label {$label<a href=$admin_link>$image_admin_link</a><a href=$hide_link>$image_hide_link</a>}
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

ns_log Notice "CLAUSE $restriction_clauses"
template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -elements $elements \
    -page_size 10 \
    -page_flush_p 0 \
    -page_query { 
	SELECT 
	p.project_id as task_id,
	t.priority as task_prio,
	p.project_name as task_name,
	t.planned_units as units,
	p.parent_id,
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

db_multirow -extend $extend_list tasks select_tasks {}

