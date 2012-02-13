ad_page_contract {
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id: permissions.tcl,v 1.2 2010/10/19 20:12:22 po34demo Exp $
} {
    package_id:integer
}

set page_title "[apm_instance_name_from_id $package_id] Permissions"

set context [list [list "." "Applications"] $page_title]

