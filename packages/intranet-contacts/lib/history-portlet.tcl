foreach optional_param {party_id query search_id tasks_interval page page_size page_flush_p tasks_orderby show_filters_p emp_f} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}
set package_url [ad_conn package_url]
set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]

set history_url "[contact::url -party_id ${party_id}]history"
