ad_page_contract {
    Executes a CVS command on the server

    @param cvs_command
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2005
} {
    cvs_server
    cvs_root
    cvs_command
    { cvs_user "cvs"}
    { cvs_password ".cvsdev"}
}

# ------------------------------------------------------------
# Authentication & defaults
#

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Automatic Software Updates"
set context_bar [im_context_bar $page_title]
set acs_root_dir [acs_root_dir]

set cvs_command "update"
set package_dir "/web/projop/packages/"

# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar]"




# ------------------------------------------------------------
# Log the dude in
#

ns_write "<h2>CVS Login</h2>\n"
ns_write "CVS login using:\n<ul>\n"
ns_write "<li>Username = $cvs_user\n"
ns_write "<li>Password = $cvs_password\n"
ns_write "<li>Server = $cvs_server\n"
ns_write "<li>Protocol = pserver\n"
ns_write "<li>CvsRoot = $cvs_root\n"
ns_write "</ul>\n"
ns_write "<pre>\n"

if {[catch {

    set cmd "export HOME=$acs_root_dir; cvs -d :pserver:$cvs_user@$cvs_server:$cvs_root login 2>&1"
    ns_write "$cmd\n"

    set fp [open "|/bin/bash -c \"$cmd\"" "w"]
    puts $fp "$cvs_password\n"
    close $fp
    ns_write "Successfully executed:\n\n"

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


# ------------------------------------------------------------
# Execute a CVS command.
# Example:
#
# cvs -z3 -d :pserver:anonymous@openacs.org:/cvsroot checkout -r oacs-4-6

ns_write "</pre>\n"
ns_write "<h2>CVS Update</h2>\n"
ns_write "<pre>\n"

if { [catch {

    set cmd "export HOME=$acs_root_dir; cd $package_dir; cvs -z3 -d :pserver:$cvs_user@$cvs_server:$cvs_root $cvs_command 2>&1"
    ns_write "$cmd\n\n"
    ns_log Notice "cvs-update: cmd=$cmd"
    set fp [open "|/bin/bash -c \"$cmd\"" "r"]
    while { [gets $fp line] >= 0 } {
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

