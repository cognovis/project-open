# Portlet for displaying all offer-item lists of projects that have the status Open

foreach optional_param {status_id actions} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]
set pm_base_url ""
if {[exists_and_not_null organization_id]} {
    set dotlrn_club_id [lindex [application_data_link::get_linked -from_object_id $organization_id -to_object_type "dotlrn_club"] 0]

    if {$dotlrn_club_id > 0} {
	set pm_base_url [apm_package_url_from_id [dotlrn_community::get_package_id_from_package_key -package_key "project-manager" -community_id $dotlrn_club_id]]
    } 
}

if {$actions eq ""} {
    if {[exists_and_not_null pm_base_url]} {
	set actions [list "[_ project-manager.Projects]" $pm_base_url "[_ project-manager.Projects]" "[_ project-manager.Add_project]" "[export_vars -base "${pm_base_url}/add-edit" -url {{customer_id $organization_id}}]" "[_ project-manager.Add_project]"]
    } else {
	set actions ""
    }
}
