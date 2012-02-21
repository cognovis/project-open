ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2012-01-04
    @cvs-id $Id$

} {
    program_id:integer
    return_url
    project_id:integer,multiple
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_get_user_id]

# get the current users permissions for this project
im_project_permissions $current_user_id $program_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You don't have the necessary permissions to modify this program".
    ad_script_abort
}

foreach pid $project_id {
    im_project_permissions $current_user_id $pid view read write admin
    if {!$write} {
	ad_return_complaint 1 "You don't have the necessary permissions to modify project #$project_id".
	ad_script_abort
    }
}

# ------------------------------------------------------------------
# Update the projects
# ------------------------------------------------------------------

foreach pid $project_id {
    db_dml add_project_to_portfolio "update im_projects set program_id = :program_id where project_id = :project_id"
}


ad_returnredirect $return_url

