# /packages/intranet-security-update-client/www/user-agreement.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Saves verbosity preferences to package parameters
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/index"}
}

set current_user_id [ad_maybe_redirect_for_registration]

set po "&#93;project-open&#91"
set page_title "ASUS Terms &amp; Conditions"
