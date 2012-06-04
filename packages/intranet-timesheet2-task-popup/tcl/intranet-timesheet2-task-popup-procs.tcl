# /packages/intranet-timesheet2-task-popup/www/intranet-timesheet2-task-popup-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Procedures for Timsheet Popup Window

    @author frank.bergmann@project-open.com
    @creation-date 2006-02-20
    @cvs-id $Id$
}


ad_proc -public im_timesheet_task_popup_id { } {
    Returns the ID of the current package. Please
    not that there is no "_pg" in the procedure name.
    This is in order to keep the rest of the system
    identical, no matter whether it's a PostgreSQL
    TSearch2 implementation of search or an Oracle
    Intermedia implementation.
} {
    return [db_string im_package_search_id {
        select package_id from apm_packages
        where package_key = 'intranet-timesheet2-task-popup'
    } -default 0]
}


ad_proc -public im_timesheet_task_popup_component { } {
    This is a piece of HTML that is being included in all
    pages of the system in the header.
} {

    set link "<a href=\"javascript:mywin=window.open('/intranet-timesheet2-task-popup/index', 'Zweitfenster', 'width=300,height=200,scrollbars=yes');mywin.focus();\"> <font=red> Log your Hours</font> </a>"

    set return_url [im_url_with_query]

    return "
<form method=POST action=/intranet-timesheet2-task-popup/new-2>
<input type=text name=note size=12 value=\"Timesheet\" onClick=\"javascript:this.value = ''\">
[export_form_vars return_url]
<select name=project_task_id>
[im_timesheet_task_popup_task_select]
</select>
<input type=submit value=Go>
</form>

"

}


ad_proc -public im_timesheet_task_popup_task_select { {default_task_id ""} } {
    Returns a select box with all tasks for the current
    user.
} {
    set user_id [ad_get_user_id]
    if {0 == $user_id} { return "" }

    set julian_date [db_string sysdate_as_julian "select to_char(sysdate,'J') from dual"]


    # ---------------------------------------------------------
    # Calculate the last task that the user has entered
    # from the last entry of the user today.
    #
    if {"" == $default_task_id} {
    	set default_task_id [db_string default_task "
		select	task_id
		from	im_timesheet_popups
		where	user_id = :user_id
			and log_time = (
				select	max(log_time)
				from	im_timesheet_popups
				where	user_id = :user_id
					and log_time >= now()::date -- included for fast select
					and log_time::date = now()::date
			)
	" -default ""]
    }

    # ---------------------------------------------------------
    # Select the tasks of all active projects where the user
    # participates
    set one_project_only_p 0
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

    # ---------------------------------------------------------
    # Build the main hierarchical SQL
    #    
    set sql "
	select
		t.task_id,
		t.task_name,
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
    set results ""
    set nbsps "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    set old_project_id 0
    set selected_p 0
    db_foreach timesheet_tasks $sql {

	set indent ""
	set level $subproject_level
	while {$level > 0} {
	    set indent "$nbsps$indent"
	    set level [expr $level-1]
	}

	# Insert intermediate header for every new project
	if {$old_project_id != $project_id} {
	    
	    # Add a header line for a project.
	    append results "<optgroup label=\"$project_name\">\n"
	    if {"" == $task_name} {
		append results "<option value=\"$project_id-0\">$indent (nothing defined yet)</option>\n"
	    }
	    set old_project_id $project_id
	}
    
	# Don't show the empty tasks that are produced with each project
	# due to the "left outer join" SQL query
	if {"" != $task_name} {

	    set selected ""
	    if {$task_id == $default_task_id} {
		set selected " selected"
		set selected_p 1
	    }
	    append results "<option value=\"$project_id-$task_id\" $selected>$task_name</option>\n"
	}
    }

    if {!$selected_p} {
	set results "<option value=\"\">
        [lang::message::lookup "" intranet-core.Please_Select "--- Please Select ---"]</option>
        $results\n"
    }

    return $results
}







