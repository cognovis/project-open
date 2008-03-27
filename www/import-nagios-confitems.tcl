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
set page_title [_ intranet-nagios.Import_Nagios_Configuration]
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

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<H1>$page_title</H1>\n"
ns_write "<h2>Configuration</h2>\n"
ns_write "<ul>\n"
ns_write "<li>Nagios Configuration File: $main_config_file\n"
ns_write "</ul>\n"

array set hosts_hash [im_nagios_read_config -main_config_file $main_config_file -debug 0]

foreach host_name [array names hosts_hash] {

    # Get the list of all services defined for host.
    # The special "host" service contains the host definition

    ad_return_complaint 1 $hosts_hash($host_name)

    array unset host_services
    array set host_services_hash $hosts_hash($host_name)

    set host_def $host_services_hash(host)

    ns_write "<ul>\n"
    ns_write "<li>Host: $host_name\n"
    ns_write "<li>$host_def\n"
    ns_write "</ul>\n"
        
}

ns_write [im_footer]


