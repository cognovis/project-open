# /packages/intranet-trans-quality/www/project-task_select.tcl

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @cvs-id 
} {
    project_id:integer
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set page_title "Select Translation Task"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

if {![im_permission $user_id add_trans_quality]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# ---------------------------------------------------------------
# Show the list of tasks for this project
# ---------------------------------------------------------------

set view_name "transq_task_select"
set task_component [im_task_component $user_id $project_id $return_url $view_name]
