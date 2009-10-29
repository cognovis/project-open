# /packages/intranet-confdb/www/assoc-project.tcl
#
# Copyright (c) 2008 ]project-open[
#

ad_page_contract {
    Associate a configuration item with a project
    @author frank.bergmann@project-open.com
} {
    conf_item_id:integer
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

set page_title [lang::message::lookup "" intranet-confdb.Associate_Conf_Item_With_Project "Associated Conf Item With Project"]