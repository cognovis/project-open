# /packages/intranet-confdb/www/assoc-project-del.tcl
#
# Copyright (c) 2008 ]project-open[
#

ad_page_contract {
    Associate a configuration item with a project
    @author frank.bergmann@project-open.com
} {
    conf_item_id:integer
    { project_id:integer,multiple {}}
    return_url
}

# --------------------------------------------------------------
#
# --------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id "add_conf_items"]} {
    ad_return_complaint 1 "You don't have sufficient permissions to create or modify Conf Items"
    ad_script_abort
}

foreach pid $project_id {

    set rel_id [db_string rel_id "select rel_id from acs_rels where object_id_one = :pid and object_id_two = :conf_item_id" -default 0]
    if {0 != $rel_id} {
	db_string del_rel "select im_conf_item_project_rel__delete(:rel_id)"
    }

}


ad_returnredirect $return_url

