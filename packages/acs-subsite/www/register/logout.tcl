# /www/register/logout.tcl

ad_page_contract {
    Logs a user out

    @cvs-id $Id: logout.tcl,v 1.2 2010/10/19 20:12:43 po34demo Exp $

} {
    {return_url ""}
}

if { $return_url eq "" } {
    if { [permission::permission_p -object_id [subsite::get_element -element package_id] -party_id 0 -privilege read] } {
        set return_url [subsite::get_element -element url]
    } else {
        set return_url /
    }
}

ad_user_logout 
db_release_unused_handles

ad_returnredirect $return_url

