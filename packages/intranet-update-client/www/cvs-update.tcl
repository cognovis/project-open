ad_page_contract {
    Executes a CVS command on a remote CVS server.
    <ul>
    <li>First, we log the user in using a "cvs login" command.
    <li>Then we execute the actual cvs_command.
    </ul>

    Please note that we have to export the HOME directory
    because this environment variable is required by CVS
    and a "bash -c" shell doesn't set it up. Maybe somebody
    has a better idea?

    @param cvs_server The name of the CVS server (example: "cvs.openacs.org")
    @param cvs_root The standard CVS root (example: "/home/cvsroot")
    @param cvs_command The command to execute (example: "update -r v3-0-0")
    @param cvs_protocol The standard CVS protocol (example: "pserver")
    @param cvs_user The CVS user to log in (example: "anonymous")
    @param cvs_password The password for the CVS user (example: "")

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2005
} {
    cvs_server
    cvs_root
    cvs_command
    { cvs_protocol "pserver" }
    { cvs_user "" }
    { cvs_password "" }
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
set error 0

# Anonymous user has access without 
if {"" == $cvs_user} { 
    set cvs_user "anonymous" 
    set cvs_password ""
}

# Get the system platform (unix, windows or default)
# We need to know if we are on "windows" in order to
# set the permissions before and after the CVS update.
#
global tcl_platform
set platform [lindex $tcl_platform(platform) 0]

# Main directory of the OpenACS installation
# Example: /web/projop
set acs_root_dir [acs_root_dir]

# Directory where all active packages reside
# Example: /web/projop/packages/
set package_dir "$acs_root_dir/packages"


# ------------------------------------------------------------
# Return the page header.
# This technique allows us to write out HTML output while
# the processes are runnin. Otherwise, the user would
# not see any intermediate results, but only a screen 
# after possibly many minutes of waiting...
#

ad_return_top_of_page "[im_header]\n[im_navbar]"


# ------------------------------------------------------------
# Make sure everything is writable
#
if {[string equal $platform "windows"]} {

    ns_write "<h2>Setting Permissions</h2>\n"
    ns_write "<pre>\n"
    if { [catch {
	set cmd "cd $package_dir; chmod -R ugo+rwx * 2>&1"
	ns_write "$cmd\n\n"
	ns_log Notice "cvs-update: cmd=$cmd"
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	while { [gets $fp line] >= 0 } {
	    ns_write "$line\n"
	}
	close $fp
	ns_write "\nPermissions successfully set:\n\n"
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
}


# ------------------------------------------------------------
# Log the dude in
#

ns_write "<h2>CVS Login</h2>\n"
ns_write "<p>After this CVS update please visit the \n"
ns_write "<a href=/acs-admin/apm/packages-install>ACS Package Manager</a>\n"
ns_write "(APM) page and update the data model.\n</p>\n"
ns_write "CVS login using:\n<ul>\n"
ns_write "<li>Username = $cvs_user\n"
ns_write "<li>Password = $cvs_password\n"
ns_write "<li>Server = $cvs_server\n"
ns_write "<li>Protocol = $cvs_protocol\n"
ns_write "<li>Root = $cvs_root\n"
ns_write "</ul>\n"
ns_write "<pre>\n"


set cvs_password_phrase ""
if {"" != $cvs_password} {
    set cvs_password_phrase ":$cvs_password"
}


if {[catch {

    set cmd "export HOME=$acs_root_dir; cvs -d :$cvs_protocol:$cvs_user:$cvs_password\@$cvs_server:$cvs_root login 2>&1"
    ns_write "$cmd\n"

    set fp [open "|[im_bash_command] -c \"$cmd\"" "w"]
    puts $fp "$cvs_password\n"
    close $fp
    ns_write "CVS Login successfully completed:\n\n"

} errmsg] } {
    set error 1
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



# ------------------------------------------------------------
# Execute the CVS command.
# Example:
#
# cvs -z3 -d :pserver:anonymous\@openacs.org:/cvsroot checkout -r oacs-4-6

if {!$error} {
    ns_write "<h2>CVS Update</h2>\n"
    ns_write "<p>This command will take several minutes, depending on your 
          Internet connection. Please don't interrupt.</p>\n"
    ns_write "<pre>\n"

    if { [catch {

	set cmd "export HOME=$acs_root_dir; cd $package_dir; cvs -z3 -d :$cvs_protocol:$cvs_user\@$cvs_server:$cvs_root $cvs_command 2>&1"
	ns_write "$cmd\n\n"
	ns_log Notice "cvs-update: cmd=$cmd"

	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	while { [gets $fp line] >= 0 } {
	    ns_write "$line\n"
	}
	close $fp
	ns_write "\nSuccessfully executed:\n\n"

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
    ns_write "<p>After this CVS update please visit the \n"
    ns_write "<a href=/acs-admin/apm/packages-install>ACS Package Manager</a>\n"
    ns_write "(APM) page and update the data model.\n</p>\n"

}




# ------------------------------------------------------------
# Make sure everything is writable again
#

if {[string equal $platform "windows"]} {

    ns_write "<h2>Setting Permissions</h2>\n"
    ns_write "<pre>\n"
    if { [catch {
	set cmd "cd $package_dir; chmod -R ugo+rwx * 2>&1"
	ns_write "$cmd\n\n"
	ns_log Notice "cvs-update: cmd=$cmd"
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	while { [gets $fp line] >= 0 } {
	    ns_write "$line\n"
	}
	close $fp
	ns_write "\nPermissions successfully set:\n\n"
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

}

ns_log Notice "cvs-update: before writing footer"
ns_write [im_footer]

