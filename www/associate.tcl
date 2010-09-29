# /packages/intranet-confdb/www/associate.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Allow the user to associate the current ticket with a new object
    using an OpenACS relationship.
    @author frank.bergmann@project-open.com
} {
    { cid ""}
    { return_url "/intranet-confdb/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-confdb.Associate_Conf_Item_With_Other_Object "Associate Conf Item With Another Object"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-confdb.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to associated this conf item with other objects."]

# Check that the user has write permissions on all select tickets
foreach conf_item_id $cid {

    # Check that ticket_id is an integer
    im_security_alert_check_integer -location "Confdb: Associate" -value $conf_item_id

    im_conf_item_permissions $current_user_id $conf_item_id view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}

set first_conf_item_id [lindex $cid 0]
