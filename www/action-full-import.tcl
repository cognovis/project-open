# packages/intranet-cvs-integration/www/action-full-import.tcl

ad_page_contract {
    Bulk action on CVS repositories to execute a full import.
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2005-01-25
    @cvs-id
} {
    repository_id:multiple,integer,notnull
    { return_url "/intranet-cvs-integration/www/index" }
} -properties {
} -validate {
} -errors {
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

set title [lang::message::lookup "" intranet-cvs-integration.Full_Import "Full Import"]
set context [list [list "$return_url" "CVS Repositories"] $title]

foreach repo_id $repository_id {

    db_1row repo_info "
	select	*
	from	im_conf_items
	where	conf_item_id = :repo_id
    "

    system [acs_root_dir]/packages/intranet-cvs-integration/perl/cvs_read.pl -cvsdir $cvs_root -rlog $line\n";


}



ad_returnredirect $return_url
