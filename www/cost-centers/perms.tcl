ad_page_contract {
    Modify basic read/write/create/admin permissions for
    an arbitrary object.

    This is a modified copy of /packages/acs-subsite/www/admin/permissions.tcl
    with modification to adapt it to the needs of P/O.
    
    @author Lars Pind (lars@collaboraid.biz)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    object_id:integer,optional
}

if {![info exists object_id]} {
    set object_id [im_cost_center_company]
}

set object_name [db_string name "select acs_object__name(:object_id)" -default ""]

set page_title "Permissions for '$object_name'"
set context [list $page_title]

