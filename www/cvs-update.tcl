ad_page_contract {
    Executes a CVS command on the server

    @param cvs_command
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2005
} {
    cvs_server
    cvs_root
    cvs_command
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Automatic Software Updates"
set context_bar [im_context_bar $page_title]

set cvs_user anonymous
set cvs_command "update"
set package_dir "/web/projop/packages/"



ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_log Notice "cvs-update: after returning top_of_page"


# Execute a CVS command.
# Example:
#
# cvs -z3 -d :pserver:anonymous@openacs.org:/cvsroot checkout -r oacs-4-6

ns_write "<pre>\n"

if { [catch {

    set cmd "cd $package_dir; cvs -z3 -d :pserver:$cvs_user@$cvs_server:$cvs_root $cvs_command 2>&1"
    ns_log Notice "cvs-update: cmd=$cmd"
 
    set fp [open "|/bin/bash -c \"$cmd\"" "r"]

    ns_log Notice "cvs-update: fp=$fp"
    while { [gets $fp line] >= 0 } {
	ns_log Notice "cvs-update: line=$line"
	ns_write "$line\n"
    }
    close $fp


} errmsg] } {
    ns_write "</pre>
        <p>Unable to execute update command:<br><pre>$cmd\n</pre>
	The server returned the error:
	<pre>$errmsg\n</pre>
	<a href=\"http://www.project-open.com/contact/\">
        Please send us a note
        </a>:
        <pre>"
}

ns_write "</pre>\n"

ns_log Notice "cvs-update: before writing footer"
ns_write [im_footer]

