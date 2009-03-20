# /packages/intranet-release-mgmt/www/add-items.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new release item to a project

    @author frank.bergmann@project-open.com
} {
    release_project_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Release Manager) can do everything.
# The managers of the individual Release Items can change 
# _their_ release stati.

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# -------------------------------------------------------------
# Create the list of potential release items to add

set bulk_actions_list [list]
lappend bulk_actions_list "Add Release Items" "add-items-2" "Add new release items"

set elements {
	project_name {
	    display_col project_name
	    label "Release Item"
	    link_url_eval $release_project_url
	}
        project_chk {
	    label "<input type=\"checkbox\"
			  name=\"_dummy\"
			  onclick=\"acs_ListCheckAll('project_list', this.checked)\"
			  title=\"Check/uncheck all rows\">"
	    display_template {
		@release_items.project_chk;noquote@
	    }
	}
    }

list::create \
    -name release_items \
    -multirow release_items \
    -key release_item \
    -row_pretty_plural $page_title \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions { } \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  { release_project_id return_url } \
    -bulk_action_method GET \
    -elements $elements


set project_release_item_p_sql ""
if {[im_column_exists im_projects release_item_p]} {
    set project_release_item_p_sql "OR p.release_item_p = 't'"
}


db_multirow -extend { release_project_url release_status_template project_chk } release_items select_release_items "
	select	p.*
 	from	im_projects p
	where	project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
		and (
			project_type_id in ([join [im_sub_categories [im_project_type_software_release_item]] ","])
			$project_release_item_p_sql
		)
	order by project_name
" {
    set release_project_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]

    set project_chk "<input type=\"checkbox\"
	name=\"project_id\"
	value=\"$project_id\"
	id=\"project_list,$project_id\">
    "
}
