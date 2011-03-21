ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-08
    @cvs-id $Id: layout-default.tcl,v 1.3 2006/04/07 23:07:39 cvs Exp $

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
# Set default page
# ******************************************************

db_transaction {
    db_dml remove_old_default_page {
	update im_dynfield_layout_pages
	set default_p = 'f'
	where default_p = 't'
    }
    
    db_dml set_default_page {
        update im_dynfield_layout_pages
        set default_p = 't'
	where page_url = :page_url
        and object_type = :object_type
    }
}

ad_returnredirect [export_vars -base layout-manager {object_type}]
