# /tcl/intranet-security-update-client-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Checks for security update messages on a central security
    update server.

    @author frank.bergmann@project-open.com
    @creation-date  January 1st, 2006
}


ad_proc im_security_update_client_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set current_user_id [ad_maybe_redirect_for_registration]
    set action_url "/intranet-security-update-client/update-preferences"
    set return_url [ad_conn url]

    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_url_base [parameter::get -package_id $package_id -parameter "SecurityUpdateServerUrl" -default "http://projop.dnsalias.com/intranet-security-update-server/index"]
    set sec_verbosity [parameter::get -package_id $package_id -parameter "SecurityUpdateVerboseP" -default "0"]

    global tcl_platform
    set os_platform [lindex $tcl_platform(os) 0]
    set os_version [lindex $tcl_platform(osVersion) 0]
    set os_machine [lindex $tcl_platform(machine) 0]

    # Add the list of package versions to the URL in order to get 
    # the right messages

    set sec_url "$sec_url_base?"

    set package_sql "
	select	v.package_key,
	        v.version_name
	from	(	select	max(version_id) as version_id,
				package_key
			from	apm_package_versions
		        group by package_key
	        ) m,
	        apm_package_versions v
	where	m.version_id = v.version_id
    "

    db_foreach package_versions $package_sql {

	regsub -all {\.} $version_name "" version_name

	# shorten the "intranet-" and "acs-" prefix from packages to save space
	if {[regexp {^intranet\-(.*)} $package_key match key]} { set package_key "i-$key"}
	if {[regexp {^acs\-(.*)} $package_key match key]} { set package_key "a-$key"}

	append sec_url "p.[string trim $package_key]=[string trim $version_name]&"
    }

    if {0 != $sec_verbosity} {
	append sec_url "email=[string trim [db_string email "select im_email_from_user_id(:current_user_id)"]]&"
	append sec_url "os_platform=[string trim $os_platform]&"
	append sec_url "os_version=[string trim $os_version]&"
	append sec_url "os_machine=[string trim $os_machine]&"

	# extract the PostgreSQL version
	# psql (PostgreSQL) 8.0.8 \ncontains support for command-line editing
	set postgres_version "undefined"
	catch {set postgres_version [exec psql --version]} errmsg
	if {[regexp {([0-9]+\.[0-9]+\.[0-9])} $postgres_version match v]} { set postgres_version $v}
	append sec_url "pg_version=[string trim $postgres_version]"
    }


    set security_update_l10n [lang::message::lookup "" intranet-security-update-client.Security_Updates "Security Updates"]
    set no_iframes_l10n [lang::message::lookup "" intranet-security-update-client.Your_browser_cant_display_iframes "Your browser can't display IFrames. Please click for here for <a href=\"$sec_url_base\">security update messages</a>."]

    set anonymous_selected ""
    set verbose_selected ""
    if {0 == $sec_verbosity} {
	set anonymous_selected "checked"
    } else {
	set verbose_selected "checked"
    }

set ttt {
	<pre>$sec_url</pre>
	<pre>[string length $sec_url]</pre>
}

    set sec_html "
<iframe src=\"$sec_url\" width=\"90%\" height=\"100\" name=\"$security_update_l10n\">
  <p>$no_iframes_l10n</p>
</iframe>

<form action=\"$action_url\" method=POST>
    <input type=\"radio\" name=\"verbosity\" value=\"1\" $verbose_selected>Detailed
    [im_gif help "Choose this option for detailed security information. With this option the security update service transmits information about your configuration that might help us to assess your &#93project-open&#91; system configuration including package versions and operating system version information. It also includes your email address so that we can alert your in special situations."]
    <input type=\"radio\" name=\"verbosity\" value=\"0\" $anonymous_selected>Anonymous
    [im_gif help "Choose this option if you prefer not to reveal any information to &#93project-open&#91; that might identify you or your organization."]
    <input type=\"hidden\" name=\"return_url\" value=\"$return_url\">
    <input type=\"submit\" name=\"submit\" value=\"OK\">
</form>
"

    return $sec_html
}
