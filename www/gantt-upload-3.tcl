# /packages/intranet-ganttproject/www/gantt-upload-3.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Save/Upload a GanttProject XML structure

    @author frank.bergmann@project-open.com
} {
    { expiry_date "" }
    { project_id:integer 0 }
    { security_token "" }
    upload_file
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]


ad_return_top_of_page "[im_header]\n[im_navbar]"


# -------------------------------------------------------------------
# Process Allocations
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

set allocations_node [$root_node selectNodes /project/allocations]

ns_write "<h2>Saving Allocations</h2><ul>\n"

foreach child [$allocations_node childNodes] {

    switch [$child nodeName] {

	"allocation" {

	    set task_id [$child getAttribute task-id ""]
	    set resource_id [$child getAttribute resource-id ""]
	    set function [$child getAttribute function ""]
	    set responsible [$child getAttribute responsible ""]
	    set percentage [$child getAttribute load "0"]

	    set allocation_exists_p [db_0or1row allocation_info "select * from im_timesheet_task_allocations where task_id = :task_id and user_id = :resource_id"]

	    set role_id [im_biz_object_role_full_member]
	    if {[string equal "Default:1" $function]} { 
		set role_id [im_biz_object_role_project_manager]
	    }

	    if {!$allocation_exists_p} { 
		db_dml insert_allocation "
		insert into im_timesheet_task_allocations (
			task_id, user_id
		) values (
			:task_id, :resource_id
		)"
	    }
	    db_dml update_allocation "
		update im_timesheet_task_allocations set
			role_id	= [im_biz_object_role_full_member],
			percentage = :percentage
		where	task_id = :task_id
			and user_id = :resource_id
	    "
	    ns_write "<li>[ns_quotehtml [$child asXML]]"
	}

	default { }
    }
}
ns_write "<ul>\n"



ns_log Notice "cvs-update: before writing footer"
ns_write [im_footer]

# ns_return 200 text/html $html
# ns_return 200 text/xml [$allocations_node asXML -indent 2 -escapeNonASCII]




    # Check whether the task exists with the same (existing task)
    set task_id [db_string task_exists "
	select task_id
	from im_timesheet_tasks
	where task_id = :gantt_project_id
    " -default 0]

    # Check whether the task exists (new task)
    if {!$task_id} {
	set task_id [db_string task_exists "
		select task_id
		from im_timesheet_tasks
		where gantt_project_id = :gantt_project_id
        " -default 0]
    }

