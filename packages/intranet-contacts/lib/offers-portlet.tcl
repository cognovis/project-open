# Portlet for displaying all projects which have the status offer along with the offer-list

foreach optional_param {status_id} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]