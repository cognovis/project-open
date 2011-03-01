# /packages/intranet-security-update-client/www/update-preferences.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Saves verbosity preferences to package parameters
    @author frank.bergmann@project-open.com
} {
    verbosity:integer
    { return_url "/intranet/admin"}
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_admin_p} {
    ad_return_complaint 1 "You have no rights to change these preferences."
    return
}

if {0 != $verbosity && 1 != $verbosity} {
    ad_return_complaint 1 "Bad value for verbosity. Expected '1' or '0'."
    return
}

# --------------------------------------------------------
# Modify the preferences, directly in the package parameters
# --------------------------------------------------------

set package_key "intranet-security-update-client"
set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]

parameter::set_value \
	-package_id $package_id \
        -parameter "SecurityUpdateVerboseP" \
        -value $verbosity

ad_returnredirect $return_url
