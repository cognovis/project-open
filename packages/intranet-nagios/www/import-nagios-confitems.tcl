# /packages/intranet-nagios/www/import-nagios-confitems.tcl

ad_page_contract {
    Parses the Nagios configuration file and creates ConfItems in the
   ]po[ ConfDB
} {
    { return_url "index" }
}

# ------------------------------------------------------------
# Default & Security
#

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-nagios.Import_Nagios_Configuration "Import Nagios Configuration"]
set context_bar [im_context_bar $page_title]
set context ""

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set main_config_file [parameter::get_from_package_key -package_key "intranet-nagios" -parameter "NagiosConfigurationUnixPath" -default "/usr/local/nagios/etc/nagios.cfg"]

# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar "conf_items"]"
ns_write "<H1>$page_title</H1>\n"
ns_write "<h2>Configuration</h2>\n"
ns_write "<ul>\n"
ns_write "<li>Nagios Configuration File: $main_config_file\n"
ns_write "</ul>\n"
ns_write "<p>\n"

set hosts_hash [im_nagios_read_config -main_config_file $main_config_file -debug 0]

im_nagios_create_confdb -hosts_hash $hosts_hash -debug 1

ns_write [im_nagios_display_config -hosts_hash $hosts_hash]


ns_write [im_footer]


