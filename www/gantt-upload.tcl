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
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-ganttproject.GanttProject "GanttProject"]
set context_bar [im_context_bar $page_title]

# get the current users permissions for this project
set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}


ad_return_template