ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @cvs-id $Id: layout-position-del.tcl,v 1.4 2008/03/24 22:35:57 cvs Exp $

} {
    object_type:notnull
    page_url:notnull
    attribute_id:notnull
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
# Remove attribute from page
# ******************************************************

db_dml remove_attribute {
	delete from im_dynfield_layout 
	where 
		page_url = :page_url and 
		attribute_id = :attribute_id
}

ad_returnredirect "[export_vars -base "layout-position" {page_url object_type}]"
