# /tcl/intranet-security-update-client-procs.tcl
#
# Copyright (C) 2003-2006 Project/Open
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
    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_url_base [parameter::get -package_id $package_id -parameter "SecurityUpdateServerUrl" -default "http://projop.dnsalias.com/intranet-security-update-server/index"]

    # Add the list of package versions to the URL in order to get 
    # the right messages

    set sec_url "$sec_url_base?"

    set package_sql "
	select
	        v.package_key,
	        v.version_name
	from (
	        select
	                max(version_id) as version_id,
	                package_key
	        from
	                apm_package_versions
	        group by
	                package_key
	        ) m,
	        apm_package_versions v
	where
	        m.version_id = v.version_id
    "

    db_foreach package_versions $package_sql {
	append sec_url "p.[ns_urlencode $package_key]=[ns_urlencode $version_name]&"
    }


    set security_update_l10n [lang::message::lookup "" intranet-security-update-client.Security_Updates "Security Updates"]
    set no_iframes_l10n [lang::message::lookup "" intranet-security-update-client.Your_browser_cant_display_iframes "Your browser can't display IFrames. Please click for here for <a href=\"$sec_url_base\">security update messages</a>."]

    set sec_html "
<iframe src=\"$sec_url\" width=\"90%\" height=\"100\" name=\"$security_update_l10n\">
  <p>$no_iframes_l10n</p>
</iframe>
"
    
    return [im_table_with_title $security_update_l10n $sec_html]
}
