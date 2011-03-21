# -------------------------------------------------------------
# intranet-release-mgmt/www/referencing-projects.tcl
#
# (c) 2003-2007 ]project-open[
# All rights reserved
# Author: frank.bergmann@project-open.com
#
# Display component
# Shows all projects with this release as release_project.

# -------------------------------------------------------------
# Variables:
# project_id:integer
# return_url

set page_title [lang::message::lookup "" intranet-release-mgmt.Referencing_Project "Referencing Projects"]
set package_url "/intranet-release-mgmt"
set release_project_id $project_id
set return_url [im_url_with_query]

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Release Manager) can do everything.
# The managers of the individual Release Items can change 
# _their_ release stati.

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
set edit_all_items_p $write

# -------------------------------------------------------------
# Create the list

set bulk_actions_list [list]

set elements {
	project_name {
	    display_col project_name
	    label "Name"
	    link_url_eval $project_url
	}
    }


set custom_cols [parameter::get_from_package_key -package_key "intranet-release-mgmt" -parameter "ReleaseMgmtReferencingProjectsCustomColumns" -default ""]

foreach col $custom_cols {
    set col_title [lang::message::lookup "" intranet-release-mgmt.[lang::util::suggest_key $col] $col]
    lappend elements $col
    lappend elements [list label $col_title ]
}

list::create \
    -name referencing_projects \
    -multirow referencing_projects \
    -key project_id \
    -row_pretty_plural $page_title \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions { } \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	release_project_id
	return_url
    } \
    -bulk_action_method GET \
    -elements $elements


db_multirow -extend { project_url } referencing_projects select_referencing_projects "
	select	p.*
 	from	im_projects p
	where	p.release_project_id = :project_id
	order by lower(p.project_name)
" {
    set project_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]
}
