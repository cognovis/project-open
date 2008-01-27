# /packages/intranet-workflow/www/projects/reset-case.tcl
#

ad_page_contract {
    View all the info about a specific project.

    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { task_id:integer 0}
    { project_id:integer 0}
    { place_key "tagged"}
    { action_pretty "l&ouml;schen" }
    { return_url ""}
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "RFC $action_pretty"
set date_format "YYYY-MM-DD"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"


