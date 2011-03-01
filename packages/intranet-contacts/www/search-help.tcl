ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: search-help.tcl,v 1.1 2009/02/08 22:28:17 cvs Exp $
} {
} -validate {
}
set admin_p [ad_permission_p [ad_conn package_id] admin]
#set default_group_id [contacts::default_group_id]
set title "[_ intranet-contacts.Search_Help]"
set context [list $title]

