# -------------------------------------------------------------
# /packages/intranet-notes/www/notes-list-component.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	project_id:integer
#	return_url

if {![info exists project_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	project_id
    }
}


if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [ad_maybe_redirect_for_registration]

# Check the permissions
im_project_permissions $user_id $project_id view read write admin
if {!$read} { return "" }


set new_note_url [export_vars -base "/intranet-notes/new" {project_id return_url}]

# ----------------------------------------------------
# Create a "multirow" to show the results

set notes_sql "
	select	*,
		im_category_from_id(note_type_id) as note_type
	from	im_notes
	where	project_id = :project_id
"

multirow create notes note_type note
db_multirow notes notes_query $notes_sql {

}

