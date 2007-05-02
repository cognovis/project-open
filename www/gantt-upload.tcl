# /packages/intranet-forum/www/intranet/forum/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
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

ad_return_template