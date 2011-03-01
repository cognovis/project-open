# /packages/intranet-timesheet2-task-popup/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Displays form to let user enter hours

    @param project_id
    @param julian_date 
    @param return_url 

    @author frank.bergmann@project-open.com
    @creation-date Feb 2006

    @cvs-id new.tcl,v 3.9.2.8 2000/09/22 01:38:37 kevin Exp
} {
    { project_id:integer 0 }
    { julian_date "" }
    { return_url "" }
}

# ---------------------------------------------------------
# Default & Security
# ---------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {"" == $return_url} { set return_url [im_url_with_query] }
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
if { [empty_string_p $julian_date] } {
    set julian_date [db_string sysdate_as_julian "select to_char(sysdate,'J') from dual"]
}
set project_id_for_default $project_id
if {0 == $project_id} { set project_id_for_default ""}

db_1row user_name_and_date "
select 
	im_name_from_user_id(user_id) as user_name,
	to_char(to_date(:julian_date, 'J'), 'fmDay fmMonth fmDD, YYYY') as pretty_date
from	users
where	user_id = :user_id" 

set page_title "[lang::message::lookup "" intranet-timesheet2.Log_Hours "Log Hours"]"
set context_bar [im_context_bar [_ intranet-timesheet2.Add_hours]]


# ---------------------------------------------------------
# Build the SQL Subquery, determining the (parent)
# projects to be displayed 
# ---------------------------------------------------------

if {0 != $project_id} {

    # Project specified => only one project
    set one_project_only_p 1
    set statement_name "hours_for_one_group"

    set project_sql "
	select
		p.project_id
	from 
		im_projects p
	where 
		p.project_id = :project_id
	order by 
		upper(project_name)
    "

} else {

    # Project_id unknown => select all projects
    set one_project_only_p 0
    set statement_name "hours_for_groups"

    set project_sql "   
	select
		p.project_id
	from 
		im_projects p,
		(   select 
			r.object_id_one as project_id 
		    from 
			im_projects p,
			acs_rels r,
			im_categories psc
		    where
			r.object_id_one = p.project_id
			and object_id_two = :user_id
			and p.project_status_id = psc.category_id
			and upper(psc.category) not in (
			    'CLOSED','INVOICED','PARTIALLY PAID',
	                    'DECLINED','DELIVERED','PAID','DELETED','CANCELED'
	        )
		UNION
		    select
			project_id
		    from
			im_hours h
		    where
			h.user_id = :user_id
			and h.day = to_date(:julian_date, 'J')
		) r
	where 
		r.project_id =  p.project_id
		and p.parent_id is null
	order by 
		upper(p.project_name)
    "
}


# ---------------------------------------------------------
# Build the main hierarchical SQL
# ---------------------------------------------------------

set sql "
select
	h.hours, 
	h.note, 
	h.billing_rate,
	t.task_id,
	t.task_nr,
	t.task_name,
	t.material_id,
	t.uom_id,
	t.planned_units,
	t.reported_hours_cache,
	m.material_name,
        children.project_id as project_id,
        children.project_nr as project_nr,
        children.project_name as project_name,
        children.parent_id as parent_project_id,
	parent.project_nr as parent_project_nr,
	parent.project_name as parent_project_name,
        tree_level(children.tree_sortkey) -1 as subproject_level
from
        im_projects parent,
        im_projects children
	left outer join 
		im_timesheet_tasks_view t 
		on (children.project_id = t.project_id)
	left outer join (
			select	* 
			from	im_hours h
			where	h.day = to_date(:julian_date, 'J')
				and h.user_id = :user_id	
		) h 
		on (t.task_id = h.timesheet_task_id and h.project_id = children.project_id)
	left outer join 
		im_materials m 
		on (t.material_id = m.material_id)
where
	children.tree_sortkey between 
		parent.tree_sortkey and 
		tree_right(parent.tree_sortkey)
        and parent.project_id in (
	    $project_sql
	)
	and children.project_status_id not in (
		[im_project_status_deleted],
		[im_project_status_canceled],
		[im_project_status_closed]
	)
order by
	lower(parent.project_name),
        children.tree_sortkey
"

# ---------------------------------------------------------
# Execute query and format results
# ---------------------------------------------------------

set results ""
set ctr 0
set nbsps "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set old_project_id 0


db_foreach $statement_name $sql {

    set indent ""
    set level $subproject_level
    while {$level > 0} {
        set indent "$nbsps$indent"
	set level [expr $level-1]
    }

    # Insert intermediate header for every new project
    if {$old_project_id != $project_id} {

	# Add a line for a project. This is useful if there are
	# no timesheet_tasks yet for this project, because we
	# always want to allow employees to log their ours in
	# order not to give them excuses.
	#
	append results "<optgroup label=\"$project_name\">\n"

	if {"" == $task_name} {
	    append results "<option value=\"\">$indent (nothing defined yet)</option>\n"
	}
	set old_project_id $project_id
	incr ctr
    }
    

    # Don't show the empty tasks that are produced with each project
    # due to the "left outer join" SQL query
    if {"" != $task_name} {
	append results "<option value=\"$task_id\">$task_name</option>\n"
    }
}


if { [empty_string_p $results] } {
    append results "<option value=\"\">[_ intranet-timesheet2.lt_There_are_currently_n_1]</option>\n"
}

set export_form_vars [export_form_vars julian_date return_url]
