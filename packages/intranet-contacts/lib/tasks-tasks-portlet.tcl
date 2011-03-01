foreach optional_param {object_id start_date end_date page_size hide_elements} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]
set package_id [ad_conn package_id]
if {![exists_and_not_null party_id]} {
    set party_id $object_id
}