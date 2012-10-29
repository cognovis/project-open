#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    
} {

}

# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"




array set profiles_array {}           
set myset [ad_conn form]
set profile_array_size 0

for {set i 0} {$i < [ns_set size $myset]} {incr i} {
    set key [ns_set key $myset $i]
    set value [ns_set value $myset $i]

    set var_key [lindex [split $key "."] 0]
    if {$var_key != "profiles_array"} { continue }

    set var_value [lindex [split $key "."] 1]
    set profiles_array($var_value) $value
    incr profile_array_size
}

# Defaults if there is nothing specified
if {0 == $profile_array_size} {
    set key "employees,all_projects"
    set profiles_array($key) "on"

    set key "project_managers,all_projects"
    set profiles_array($key) "on"

    set key "project_managers,all_companies"
    set profiles_array($key) "on"

    set key "senior_managers,all_projects"
    set profiles_array($key) "on"

    set key "senior_managers,all_companies"
    set profiles_array($key) "on"

    set key "senior_managers,finance"
    set profiles_array($key) "on"
}
