# recipient        - to filter mails for a single receiver
# sender           - to filter mails for a single sender
# object_id        - to filter mails for a object_id
# page             - to filter the pagination
# page_size        - to know how many rows show (optional default to 10)
# show_filter_p    - to show or not the filters in the inlcude, default to "t"
# from_package_id  - to watch mails of this package instance  
# elements         - a list of elements to show in the list template. If not provided will show all elements.

foreach optional_param {page page_size show_filters_p elements} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]