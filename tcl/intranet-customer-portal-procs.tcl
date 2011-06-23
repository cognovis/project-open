# /packages/intranet-core/tcl/intranet-profile-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# Profiles represent OpenACS groups used by ]project-open[
# However, for performance reasons we have introduced special
# caching and auxillary functions specific to ]po[.

# @author klaus.hofeditz@project-open.com



ad_proc -public im_list_rfqs_component {} {
    Returns a component that list all current RFQ together with their status
    and action options, such as "Accept/Deny Quote". 
    
} {

    set user_id [ad_get_user_id]

    # Include sencha libs 
    template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/intranet-sencha/js/ext-all-debug-w-comments.js" -order 1

    # CSS Adjustemnts to ExtJS
    template::head::add_css -href "/intranet-customer-portal/intranet-customer-portal.css" -media "screen" -order 10

    # Include Component JS
    template::head::add_javascript -src "/intranet-customer-portal/resources/js/rfq-list.js" -order 2

    return "<div id='gridRFQ'></div>"
}
