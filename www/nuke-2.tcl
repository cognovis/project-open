# /packages/intranet-confdb/www/nuke-2.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.

ad_page_contract {
    Remove a Conf Item from the system completely
    @author frank.bergmann@project-open.com
} {
    conf_item_id:integer,notnull
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [_ intranet-core.Done]
set context_bar [im_context_bar $page_title]

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You need to have administration rights for this operation."
    ad_script_abort
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

im_conf_item_nuke -conf_item_id $conf_item_id

set return_to_admin_link "<a href=\"/intranet-confdb/index\">[_ intranet-core.lt_return_to_user_admini]</a>" 

