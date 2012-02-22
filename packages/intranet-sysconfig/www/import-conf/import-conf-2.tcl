# /packages/intranet-sysconf/www/import-conf/import-conf-2.tcl
#
# Copyright (C) 2012 ]project-open[
#

ad_page_contract {
    Parse a CSV file and update the configuration.
    @author frank.bergmann@project-open.com
    @param upload_file Parameter used during manual file upload
    @param config_file Parameter used when a specific config is called
} {
    return_url
    upload_file:optional
    {config_file ""}
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title [lang::message::lookup "" intranet-sysconfig.Import_Conf "Import Configuration"]
set context_bar [im_context_bar {} $page_title]


if {"" == $config_file} {
    # Manual file upload:
    # Get the file from the user.
    # number_of_bytes is the upper-limit
    set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
    set config_file [ns_queryget upload_file.tmpfile]
    im_security_alert_check_tmpnam -location "import-conf-2.tcl" -value $config_file
    if { $max_n_bytes && ([file size $config_file] > $max_n_bytes) } {
	ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
	return
    }
}
    
if {![file readable $config_file]} {
    ad_return_complaint 1 "Unable to read the file '$config_file'. <br>
    Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}


# ------------------------------------------------------------
# Render Result Header

ad_return_top_of_page "
        [im_header]
        [im_navbar]
	<ul>
"

set html [im_sysconfig_load_configuration $config_file]
ns_write $html

# ------------------------------------------------------------
# Render Report Footer

ns_write "
	</ul>
	<p><A HREF=$return_url>Return to Project Page</A>
"
ns_write [im_footer]
