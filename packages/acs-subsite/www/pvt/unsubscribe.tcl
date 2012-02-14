ad_page_contract {

    @cvs-id $Id: unsubscribe.tcl,v 1.2 2010/10/19 20:12:42 po34demo Exp $
}

set user_id [auth::get_user_id -account_status closed]

set system_name [ad_system_name]

set page_title [_ acs-subsite.Close_your_account]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set pvt_home [ad_pvt_home]
set pvt_home_name [ad_pvt_home_name]
