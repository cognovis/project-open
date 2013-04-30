ad_page_contract {
    Show all the links to Monitoring sub-modules
    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $
} {}

set package_id [ad_conn package_id]

set dev_support_link ""
set dev_support_id [apm_package_id_from_key "acs-developer-support"]
if { $dev_support_id != 0 } {
    set dev_support_url [db_string get_package_url { *SQL* } -default ""]
    if { ![empty_string_p $dev_support_url] } {
        set dev_support_link "<li><a href=\"$dev_support_url\">[_ monitoring.Developer_Support_Request_Information]</a>"
    }
}

set parameters_url [export_vars -base "/shared/parameters" {
    package_id { return_url [ad_return_url] }
}]

set context [list]
set title "[_ monitoring.Monitoring] [ad_system_name]"

ad_return_template


