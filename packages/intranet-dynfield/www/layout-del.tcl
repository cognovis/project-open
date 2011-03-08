ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-08
    @cvs-id $Id: layout-del.tcl,v 1.3 2006/04/07 23:07:39 cvs Exp $

} {
    object_type:notnull
    page_url:notnull
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ******************************************************
# Delete page layout
# ******************************************************

db_transaction {
    db_dml delete_page_attributes {
	delete from im_dynfield_layout
        where page_url = :page_url
        and object_type = :object_type
    }
    db_dml delete_page_layout {
	delete from im_dynfield_layout_pages
	where page_url = :page_url
	and object_type = :object_type
    }
} on_error {
    ad_return_complaint 1 "This page could not be deleted"
    ns_log Warning "\[TCL\]dynfield/www/layout-del.tcl --------> $errmsg"
}

ad_returnredirect [export_vars -base layout-manager {object_type}]
