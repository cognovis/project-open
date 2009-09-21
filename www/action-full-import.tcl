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


# ******************************************************
# Write HTTP headers and start the page
# ******************************************************

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format html

ns_write "
	[im_header]
	[im_navbar]
"

ns_write "<ul>\n"


foreach repo_id $repository_id {

    db_1row repo_info "
	select	*,
		conf_item_nr as repo_name
	from	im_conf_items
	where	conf_item_id = :repo_id
    "

    # Working:
    # ./cvs_read.pl -cvsdir :pserver:anonymous@cvs.project-open.net:/home/cvsroot -rlog intranet-hr

    set cvs_read [acs_root_dir]/packages/intranet-cvs-integration/perl/cvs_read.pl
    set command [list exec $cvs_read -cvsdir :pserver:${cvs_user}@${cvs_hostname}:${cvs_path} -rlog $repo_name]

    ns_write "<li>Command: $command\n"
    ns_write "<pre>\n"
    if {[catch {
	eval $command
    } err_msg]} {
	ns_write "<li><font><pre>$err_msg</pre></font>\n"
    }
    ns_write "</pre>\n"


}

ns_write "</ul>\n"

ns_write "
	[im_footer]
"
