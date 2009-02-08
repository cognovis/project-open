set package_url [ad_conn package_url]
set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]

set relations_url "[contact::url -party_id $party_id]relationships"
if {![exists_and_not_null sort_by_date_p]} {
    set sort_by_date_p 0
}
