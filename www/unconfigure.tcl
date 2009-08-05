# /packages/intranet-sysconfig/www/unconfigure.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Disables all components and menus and enables the SysConfig
    component on the "Home" page to prepare a users's configuration
    session
} {

}

# ---------------------------------------------------------------
# Output headers
# Allows us to write out progress info during the execution
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}


set content_type "text/html"
set http_encoding "iso8859-1"
append content_type "; charset=$http_encoding"
set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type
ns_write "[im_header] [im_navbar]"


# ---------------------------------------------------------------
# Disable everything
# ---------------------------------------------------------------

ns_write "<h2>Disabling Everything</h2>\n"

ns_write "<li>Disabling menus ... "
catch {db_dml disable_menus "update im_menus set enabled_p = 'f'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Disabling components ... "
catch {db_dml disable_components "update im_component_plugins set enabled_p = 'f'"}  err
ns_write "done<br><pre>$err</pre>\n"


# ---------------------------------------------------------------
# Enable the SysConfig components
# ---------------------------------------------------------------

ns_write "<h2>Enable Basic Stuff</h2>\n"

ns_write "<li>Enable 'Home' menu ... "
db_dml enable_home "update im_menus set enabled_p = 't' where label = 'home'"
ns_write "done<br><pre>$err</pre>\n"


ns_write "<li>Disabling 'SysConfig' component ... "
db_dml enable_sysconfig_component "update im_component_plugins set enabled_p = 't' where package_name = 'intranet-sysconfig'"
ns_write "done<br><pre>$err</pre>\n"


# ---------------------------------------------------------------
# Set the "verbosity" of the Update Component to "-1",
# indicating that the user needs to confirm sending server data.
# ---------------------------------------------------------------

set package_key "intranet-security-update-client"
set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
parameter::set_value \
        -package_id $package_id \
        -parameter "SecurityUpdateVerboseP" \
        -value -1


# ---------------------------------------------------------------
# Finish off page
# ---------------------------------------------------------------

# Remove all permission related entries in the system cache
util_memoize_flush_regexp ".*"
im_permission_flush


ns_write "[im_footer]\n"


