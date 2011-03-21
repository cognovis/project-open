ad_page_contract {
    Redirect page for adding users to the permissions list.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id: permissions-user-add.tcl,v 1.1 2006/10/25 17:55:10 cvs Exp $
}

set object_id [ad_conn package_id]

set page_title "Add User"

set context [list [list "permissions" "Permissions"] $page_title]

