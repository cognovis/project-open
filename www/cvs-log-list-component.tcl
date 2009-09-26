# -------------------------------------------------------------
# /packages/intranet-cvs-integration/www/cvs-log-list-component.tcl
#
# Copyright (c) 2009 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	object_id:integer
#	return_url

if {![info exists object_id]} {

    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	{object_id:integer 0}
	{conf_item_id:integer 0}
    }

}


if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [ad_maybe_redirect_for_registration]


# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd


# ----------------------------------------------------
# Create a "multirow" to show the results

multirow create cvs_logs note_type note note_formatted

if {$object_read} {

    set where_clause "1=0"
    if {0 != $object_id} { set where_clause "l.cvs_project_id = :object_id" }
    if {0 != $conf_item_id} { set where_clause "l.cvs_conf_item_id = :object_id" }

    set cvs_logs_sql "
	select	l.*,
		im_name_from_user_id(l.cvs_user_id) as cvs_user
	from	im_cvs_logs l
	where	$where_clause
    "
    
    db_multirow -extend { log_url } cvs_logs cvs_logs_query $cvs_logs_sql {
	set log_url [export_vars -base "/intranet-cvs-integration/new" {note_id return_url}]

	regsub -all {\\n} $cvs_note "" cvs_note
	regsub -all {\\r} $cvs_note "" cvs_note
	set cvs_note [string trim $cvs_note]

    }
}