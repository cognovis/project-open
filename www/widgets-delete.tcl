ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id$

} {
    widget_id:array,optional
}

# ******************************************************
# Default & Security
# ******************************************************

set title "Delete Widgets"
set context [list $title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ******************************************************
# Create the list of Widgets
# ******************************************************

if {[info exists widget_id]} {

#    ad_return_complaint 1 "<pre>[array names widget_id]</pre>"

    foreach wid [array names widget_id] {
	db_dml delete_widget "delete from im_dynfield_widgets where widget_id = :wid"
    }

}

ad_returnredirect "widgets"
