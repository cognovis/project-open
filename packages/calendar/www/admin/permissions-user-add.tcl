ad_page_contract {
    Redirect page for adding users to the permissions list.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id: permissions-user-add.tcl,v 1.3 2005/01/13 13:56:31 jeffd Exp $
} {
    object_id:integer
}

set page_title "Add User"

set context [list [list [export_vars -base permissions { object_id }] "Permissions"] $page_title]

