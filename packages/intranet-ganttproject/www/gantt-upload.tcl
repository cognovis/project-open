# /packages/intranet-forum/www/intranet/forum/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all projects with dimensional sliders.

    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    return_url:notnull
    {import_type ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

switch $import_type {
    microsoft_project { set program_name "Microsoft Project" }
    gantt_project { set program_name "GanttProject" }
    openproj { set program_name "OpenProj" }
    default { set program_name "unknown" }
}

set page_title [lang::message::lookup "" intranet-ganttproject.Import_from_program "Import Project From %program_name%"]
set context_bar [im_context_bar $page_title]

# get the current users permissions for this project
set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}


db_1row project_info "
	select	parent_id
	from	im_projects
	where	project_id = :project_id
"
if {"" != $parent_id} {
    ad_return_complaint 1 "
	<br>
	<b>[lang::message::lookup "" intranet-ganttproject.Unable_to_import_into_sub_project "Unable to import data into a sub-project"]</b>:<br>
	<p>[lang::message::lookup "" intranet-ganttproject.Unable_to_import_into_sub_project_blurb "
		We can't import into Gantt tasks into a sub-project.<br>
		Please select the main project and try again.
	"]</p><br>
    "
    ad_script_abort
}


# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]
# set menu_label "project_summary"
set menu_label ""

set sub_navbar [im_sub_navbar \
		    -components \
		    -base_url [export_vars -base "/intranet/projects/view" {project_id}] \
		    $parent_menu_id \
		    $bind_vars \
		    "" \
		    "pagedesriptionbar" \
		    $menu_label \
		   ]
