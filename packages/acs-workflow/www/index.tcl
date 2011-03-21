ad_page_contract {
    Displays the user's task list.

    @author Lars Pind (lars@pinds.com)
    @creation-date 13 July 2000
    @cvs-id $Id: index.tcl,v 1.2 2006/04/07 22:47:07 cvs Exp $
} -properties {
    context
    admin_p
}

set user_id [ad_maybe_redirect_for_registration]
set admin_p [ad_permission_p [ad_conn package_id] "admin"] 

set context [list]

ad_return_template