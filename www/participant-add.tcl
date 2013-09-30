# /packages/intranet-events/www/participant-add.tcl
#
# Copyright (c) 1998-2008 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@event-open.com
} {
    event_id:integer
    user_id:integer
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You don't have the right to modify this event"
    ad_script_abort
}

set role_id 1300
set rel_id [im_biz_object_add_role $user_id $event_id $role_id]
db_dml update_rel "update im_biz_object_members set member_status_id = [im_event_participant_status_reserved] where rel_id = :rel_id"

ad_returnredirect $return_url
