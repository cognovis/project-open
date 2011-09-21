# -------------------------------------------------------------
# /packages/intranet-baseline/www/baseline-list-component.tcl
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
	project_id:integer
    }
}

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set current_user_id [ad_maybe_redirect_for_registration]
set new_baseline_url [export_vars -base "/intranet-baseline/new" {{baseline_project_id $project_id} return_url}]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :project_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$project_id object_view object_read object_write object_admin"
eval $perm_cmd


# ----------------------------------------------------
# Create a "multirow" to show the results

multirow create baselines baseline_type baseline baseline_formatted

if {$object_read} {

    set baselines_sql "
	select	b.*,
		im_category_from_id(b.baseline_type_id) as baseline_type,
		im_category_from_id(b.baseline_status_id) as baseline_status,
		to_char(o.creation_date, 'YYYY-MM-DD') as baseline_creation_date_pretty
	from	im_baselines b,
		acs_objects o
	where	b.baseline_project_id = :project_id and
		b.baseline_id = o.object_id
    "
    
    db_multirow -extend { baseline_formatted baselines_edit_url  baselines_view_url} baselines baselines_query $baselines_sql {

	set baselines_edit_url [export_vars -base "/intranet-baseline/new" {baseline_id return_url}]
	set baselines_view_url [export_vars -base "/intranet-baseline/new" {baseline_id return_url {form_mode display}}]

	regsub -all {[^0-9a-zA-Z]} $baseline_type "_" baseline_type_key
	set baseline_type [lang::message::lookup "" intranet-baseline.$baseline_type_key $baseline_type]

	regsub -all {[^0-9a-zA-Z]} $baseline_status "_" baseline_status_key
	set baseline_status [lang::message::lookup "" intranet-baseline.$baseline_status_key $baseline_status]
    }
}