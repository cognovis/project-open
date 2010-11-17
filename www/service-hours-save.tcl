# /packages/intranet-sla-management/www/service-hours-save.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Associate the ticket_ids in "tid" with one of the specified objects.
    target_object_type specifies the type of object to associate with and
    determines which parameters are used.
    @author frank.bergmann@project-open.com
} {
    sla_id:integer
    hours:array,optional
    { return_url "/intranet-sla-management/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-sla-management.Save_Service_Hours "Save Service Hours"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

# Check that the user has write permissions on all select tickets
im_project_permissions $current_user_id $sla_id view read write admin
if {!$write} { ad_return_complaint 1 "You don't have permissions to perform this action" }

ad_return_complaint 1 [array get hours]


# ---------------------------------------------------------------
# Save the values
# ---------------------------------------------------------------

foreach h [array names hours] {

}

