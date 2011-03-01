ad_page_contract {
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id: permissions.tcl,v 1.1 2009/02/08 22:28:17 cvs Exp $
} {
    {group_id:integer ""}
}

if { [exists_and_not_null group_id] } {
    set object_id $group_id
} else {
    set object_id [ad_conn package_id]
}
set page_title "[_ intranet-contacts.Permissions]"

set context [list $page_title]

